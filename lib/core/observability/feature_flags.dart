import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:flutter/foundation.dart';

/// A remotely tunable value with a safe in-code default.
///
/// Users get [defaultValue] offline, before the first successful refresh,
/// when the key is not published and when the remote value has the wrong
/// type. Declare flags in one catalog so the defaults are reviewed together:
///
/// ```dart
/// abstract final class AppFlags {
///   static const newCheckout = FeatureFlag('new_checkout_enabled', false);
///   static const ordersPageSize = FeatureFlag('orders_page_size', 20);
/// }
///
/// final enabled = flags.value(AppFlags.newCheckout); // bool
/// ```
@immutable
final class FeatureFlag<T extends Object> {
  const FeatureFlag(this.key, this.defaultValue)
    : assert(
        defaultValue is bool ||
            defaultValue is int ||
            defaultValue is double ||
            defaultValue is String,
        'Feature flags support bool, int, double and String only.',
      );

  final String key;
  final T defaultValue;

  @override
  String toString() => 'FeatureFlag($key)';
}

/// Reads typed flags. Never a place for secrets: anyone can read them.
abstract interface class FeatureFlags {
  /// The active value of [flag], or its default when there is no valid one.
  T value<T extends Object>(FeatureFlag<T> flag);

  /// Fetches and activates remote values. Returns `true` when new values
  /// became active. The app must work without ever calling it.
  Future<bool> refresh();
}

/// In-code defaults, optionally overridden for tests or local builds.
/// Overrides with the wrong type are ignored.
final class LocalFeatureFlags implements FeatureFlags {
  LocalFeatureFlags({
    Map<String, Object> overrides = const {},
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
  }) : _overrides = Map.unmodifiable(overrides),
       _debug = DebugDiagnostics(log: log, enabled: debugLogging);

  final Map<String, Object> _overrides;
  final DebugDiagnostics _debug;

  @override
  T value<T extends Object>(FeatureFlag<T> flag) {
    final override = _overrides[flag.key];
    return override is T ? override : flag.defaultValue;
  }

  @override
  Future<bool> refresh() async {
    _debug('flags: no remote source, using in-code defaults');
    return false;
  }
}

/// Makes any [FeatureFlags] adapter safe offline: a failing or slow refresh
/// returns `false`, and a failing or mistyped read returns the default.
final class FallbackFeatureFlags implements FeatureFlags {
  FallbackFeatureFlags(
    this._inner, {
    Duration refreshTimeout = const Duration(seconds: 10),
    DebugDiagnostics debug = const DebugDiagnostics(),
  }) : _refreshTimeout = refreshTimeout,
       _debug = debug;

  final FeatureFlags _inner;
  final Duration _refreshTimeout;
  final DebugDiagnostics _debug;

  @override
  T value<T extends Object>(FeatureFlag<T> flag) {
    try {
      return _inner.value(flag);
    } catch (error) {
      _debug('flags: ${flag.key} uses its default after ${error.runtimeType}');
      return flag.defaultValue;
    }
  }

  @override
  Future<bool> refresh() async {
    try {
      return await _inner.refresh().timeout(_refreshTimeout);
    } catch (error) {
      _debug('flags: refresh failed with ${error.runtimeType}; keeping values');
      return false;
    }
  }
}
