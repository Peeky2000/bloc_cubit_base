import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:flutter/foundation.dart';

/// Records screen views and product events.
///
/// Parameter values must be non-personal `String`, `int`, `double` or `bool`.
/// `Observability` drops anything else, and any key or value that looks
/// personal, before an adapter such as Firebase Analytics sees it.
abstract interface class AnalyticsTracker {
  Future<void> screenView(String name);

  /// [name] and parameter keys use letters, digits and `_`, start with a
  /// letter and are at most 40 characters.
  Future<void> event(String name, {Map<String, Object> params = const {}});
}

/// Keeps analytics on the device: redacted lines in the debug console during
/// debug builds, nothing at all otherwise.
final class LocalAnalyticsTracker implements AnalyticsTracker {
  LocalAnalyticsTracker({
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
  }) : _redactor = redactor,
       _debug = DebugDiagnostics(log: log, enabled: debugLogging);

  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  Future<void> screenView(String name) async =>
      _debug('analytics: screen_view ${_redactor.text(name)}');

  @override
  Future<void> event(
    String name, {
    Map<String, Object> params = const {},
  }) async => _debug(
    'analytics: ${_redactor.text(name)} '
    '${_redactor.text(describeSafely(params))}',
  );
}

/// Applies the privacy and naming rules in front of any [AnalyticsTracker]
/// adapter. Invalid events are dropped, never sent half-cleaned.
///
/// - Event names and parameter keys match `[A-Za-z][A-Za-z0-9_]{0,39}` and do
///   not use the reserved `firebase_`, `google_` or `ga_` prefixes.
/// - Parameter keys that name personal data (`email`, `phone`, `user_id`,
///   `token`, ...) are dropped.
/// - Values must be `bool`, `int`, finite `double` or `String`. Strings that
///   look personal (e-mail, phone, token, URL with query) are dropped; others
///   are cut to 100 characters. At most 25 parameters are kept.
/// - Screen names lose any query or fragment and are redacted.
/// - Adapter failures are swallowed.
final class SanitizingAnalyticsTracker implements AnalyticsTracker {
  SanitizingAnalyticsTracker(
    this._inner, {
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DebugDiagnostics debug = const DebugDiagnostics(),
  }) : _redactor = redactor,
       _debug = debug;

  static const maxParams = 25;
  static const maxValueLength = 100;
  static const maxScreenNameLength = 100;
  static final _name = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$');
  static const _reservedPrefixes = ['firebase_', 'google_', 'ga_'];

  final AnalyticsTracker _inner;
  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  Future<void> screenView(String name) {
    final screen = _screenName(name);
    if (screen == null) {
      _debug('analytics: dropped a screen view without a usable name');
      return Future.value();
    }
    return _guard(() => _inner.screenView(screen));
  }

  @override
  Future<void> event(String name, {Map<String, Object> params = const {}}) {
    if (!_isValidName(name)) {
      _debug('analytics: dropped event with invalid name');
      return Future.value();
    }
    return _guard(() => _inner.event(name, params: _params(params)));
  }

  String? _screenName(String name) {
    final path = name.split(RegExp('[?#]')).first.trim();
    if (path.isEmpty) {
      return null;
    }
    final redacted = _redactor.text(path);
    return redacted.length > maxScreenNameLength
        ? redacted.substring(0, maxScreenNameLength)
        : redacted;
  }

  Map<String, Object> _params(Map<String, Object> params) {
    final result = <String, Object>{};
    for (final MapEntry(:key, :value) in params.entries) {
      if (result.length == maxParams) {
        _debug('analytics: kept the first $maxParams parameters');
        break;
      }
      final clean = _value(value);
      if (clean == null ||
          !_isValidName(key) ||
          _redactor.isSensitiveKey(key)) {
        _debug('analytics: dropped parameter "${_redactor.text(key)}"');
        continue;
      }
      result[key] = clean;
    }
    return Map.unmodifiable(result);
  }

  Object? _value(Object value) => switch (value) {
    bool() || int() || double(isFinite: true) => value,
    final String text when !_redactor.containsPersonalData(text) =>
      text.length > maxValueLength ? text.substring(0, maxValueLength) : text,
    _ => null,
  };

  bool _isValidName(String name) =>
      _name.hasMatch(name) &&
      !_reservedPrefixes.any((prefix) => name.startsWith(prefix));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _debug('analytics: adapter failed with ${error.runtimeType}');
    }
  }
}
