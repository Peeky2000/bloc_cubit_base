import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:flutter/foundation.dart';

/// Records crashes and non-fatal errors.
///
/// Use the instance from `Observability`: it redacts every message before an
/// adapter such as Crashlytics sees it and swallows adapter failures.
abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// Adds a breadcrumb shown with the next report.
  Future<void> log(String message);

  /// Links later reports to a pseudonymous user. Pass a hex hash, never an
  /// e-mail, phone number or raw account ID. An empty string clears it.
  Future<void> setUserIdentifier(String hashedId);
}

/// An error whose text has been scrubbed of personal data.
///
/// Only the redacted text and the original type name survive. The stack trace
/// travels next to it unchanged.
final class RedactedError implements Exception {
  const RedactedError(this.message, {required this.originalType});

  factory RedactedError.of(Object error, DiagnosticRedactor redactor) =>
      error is RedactedError
      ? error
      : RedactedError(
          redactor.text(describeSafely(error)),
          originalType: error.runtimeType.toString(),
        );

  final String message;
  final String originalType;

  @override
  String toString() => message;
}

/// Keeps reports on the device: redacted lines in the debug console during
/// debug builds, nothing at all otherwise.
final class LocalCrashReporter implements CrashReporter {
  LocalCrashReporter({
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
  }) : _redactor = redactor,
       _debug = DebugDiagnostics(log: log, enabled: debugLogging);

  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    final kind = fatal ? 'fatal' : 'non-fatal';
    final context = reason == null ? '' : ' (${_redactor.text(reason)})';
    _debug(
      'crash: $kind error$context: ${_redactor.text(describeSafely(error))}',
      stackTrace: stack,
    );
  }

  @override
  Future<void> log(String message) async =>
      _debug('crash: breadcrumb: ${_redactor.text(message)}');

  @override
  Future<void> setUserIdentifier(String hashedId) async => _debug(
    hashedId.isEmpty
        ? 'crash: user identifier cleared'
        : 'crash: user identifier set',
  );
}

/// Applies the privacy rules in front of any [CrashReporter] adapter.
///
/// - Error text and reasons pass through [DiagnosticRedactor]; the adapter
///   receives a [RedactedError] plus the original stack trace.
/// - Breadcrumbs are redacted.
/// - User identifiers must be a hex hash (16-128 characters) or empty.
/// - Adapter failures are swallowed.
final class RedactingCrashReporter implements CrashReporter {
  RedactingCrashReporter(
    this._inner, {
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DebugDiagnostics debug = const DebugDiagnostics(),
  }) : _redactor = redactor,
       _debug = debug;

  static final _hashedId = RegExp(r'^[A-Fa-f0-9]{16,128}$');

  final CrashReporter _inner;
  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => _guard(
    () => _inner.recordError(
      RedactedError.of(error, _redactor),
      stack,
      fatal: fatal,
      reason: reason == null ? null : _redactor.text(reason),
    ),
  );

  @override
  Future<void> log(String message) =>
      _guard(() => _inner.log(_redactor.text(message)));

  @override
  Future<void> setUserIdentifier(String hashedId) {
    if (hashedId.isNotEmpty && !_hashedId.hasMatch(hashedId)) {
      _debug('crash: ignored a user identifier that is not a hex hash');
      return Future.value();
    }
    return _guard(() => _inner.setUserIdentifier(hashedId));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _debug('crash: adapter failed with ${error.runtimeType}');
    }
  }
}
