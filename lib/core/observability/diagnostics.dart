import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc_cubit_base/core/network/network_redactor.dart';
import 'package:flutter/foundation.dart';

/// Writes one diagnostic line. Injected so tests can capture output.
typedef DiagnosticLog =
    void Function(String message, {Object? error, StackTrace? stackTrace});

/// Default [DiagnosticLog]: the developer console, tagged `observability`.
void logDiagnostic(String message, {Object? error, StackTrace? stackTrace}) =>
    developer.log(
      message,
      name: 'observability',
      error: error,
      stackTrace: stackTrace,
    );

/// `toString()` that never throws, for objects we do not control.
String describeSafely(Object? value) {
  try {
    return value.toString();
  } catch (_) {
    return '<${value.runtimeType}>';
  }
}

/// Runs [action] without awaiting it and drops any error it throws, so
/// telemetry can never break navigation or error handling.
void fireAndForget(FutureOr<void> Function() action) {
  unawaited(Future<void>.sync(action).catchError((Object _) {}));
}

/// Logs only in debug builds and never lets a logging failure escape.
final class DebugDiagnostics {
  const DebugDiagnostics({
    DiagnosticLog log = logDiagnostic,
    bool enabled = kDebugMode,
  }) : _log = log,
       _enabled = enabled;

  final DiagnosticLog _log;
  final bool _enabled;

  void call(String message, {StackTrace? stackTrace}) {
    if (!_enabled) {
      return;
    }
    try {
      _log(message, stackTrace: stackTrace);
    } catch (_) {
      // Diagnostics must never break the app.
    }
  }
}

/// Removes personal data from diagnostics before they leave the device.
///
/// Builds on [NetworkRedactor] so network logs and telemetry share one set of
/// sensitive keys and bearer-token rules, then masks values that often appear
/// in exception messages: JWTs, URL query strings, e-mail addresses and long
/// digit runs such as phone numbers.
final class DiagnosticRedactor {
  const DiagnosticRedactor({NetworkRedactor network = const NetworkRedactor()})
    : _network = network;

  final NetworkRedactor _network;

  static final _jwt = RegExp(r'\beyJ[\w-]*\.[\w-]+\.[\w-]*');
  static final _urlQuery = RegExp(
    r'(\b[a-z][a-z0-9+.-]*://[^\s?#]+)[?#]\S*',
    caseSensitive: false,
  );
  static final _email = RegExp(r'[\w.%+-]+@[\w-]+(?:\.[\w-]+)+');
  static final _longDigits = RegExp(r'\+?\d(?:[\s.-]?\d){8,}');

  /// Keys that identify a person even though they are not credentials.
  static const _personalKeys = {
    'fullname',
    'displayname',
    'firstname',
    'lastname',
    'username',
    'userid',
    'uid',
    'deviceid',
    'address',
    'birthday',
    'dob',
    'location',
    'latitude',
    'longitude',
    'lat',
    'lng',
    'ip',
    'ipaddress',
  };

  String get replacement => _network.replacement;

  String text(String value) => _network
      .text(value)
      .replaceAll(_jwt, replacement)
      .replaceAllMapped(_urlQuery, (match) => '${match[1]}?$replacement')
      .replaceAll(_email, replacement)
      .replaceAll(_longDigits, replacement);

  bool containsPersonalData(String value) => text(value) != value;

  bool isSensitiveKey(String key) {
    // NetworkRedactor keeps its key list private. Probing headers() reuses the
    // exact same rule instead of keeping a second copy that can drift.
    if (_network.headers({key: ''})[key] == replacement) {
      return true;
    }
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _personalKeys.contains(normalized);
  }
}
