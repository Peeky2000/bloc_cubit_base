import 'dart:collection';
import 'dart:developer' as developer;

import 'package:bloc_cubit_base/core/observability/crash_reporter.dart';
import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:flutter/foundation.dart';

void _logUncaught(String message, {Object? error, StackTrace? stackTrace}) =>
    developer.log(message, error: error, stackTrace: stackTrace);

/// Sends uncaught errors to the local log and, once [attach]ed, to a
/// [CrashReporter].
///
/// `bootstrap` installs the handlers before anything else runs and attaches
/// the reporter after dependency injection is ready. Up to [maxPending]
/// errors raised before that, for example during plugin start-up, are kept
/// and sent on [attach].
///
/// Uncaught errors are reported as fatal so they count against crash-free
/// users. Flutter errors marked `silent` (such as image loading failures) are
/// non-fatal.
final class UncaughtErrorForwarder {
  UncaughtErrorForwarder({DiagnosticLog log = _logUncaught}) : _log = log;

  static const maxPending = 20;

  final DiagnosticLog _log;
  final _pending = Queue<_PendingError>();
  CrashReporter? _reporter;

  /// Routes Flutter framework errors and errors that reach the platform
  /// dispatcher (outside any guarded zone) to this forwarder.
  void install({PlatformDispatcher? dispatcher}) {
    FlutterError.onError = onFlutterError;
    (dispatcher ?? PlatformDispatcher.instance).onError = onPlatformError;
  }

  /// Starts sending errors to [reporter], beginning with any kept earlier.
  void attach(CrashReporter reporter) {
    _reporter = reporter;
    while (_pending.isNotEmpty) {
      _pending.removeFirst().sendTo(reporter);
    }
  }

  /// For `FlutterError.onError`.
  void onFlutterError(FlutterErrorDetails details) {
    _safeLog(details.exceptionAsString, details.stack);
    _report(
      _PendingError(
        details.exception,
        details.stack,
        fatal: !details.silent,
        reason: _context(details),
      ),
    );
  }

  /// For `PlatformDispatcher.onError`. Returns `true`: the error is handled.
  bool onPlatformError(Object error, StackTrace stack) {
    onZoneError(error, stack);
    return true;
  }

  /// For the `runZonedGuarded` error callback.
  void onZoneError(Object error, StackTrace stack) {
    _safeLog(() => describeSafely(error), stack);
    _report(_PendingError(error, stack, fatal: true));
  }

  void _report(_PendingError error) {
    final reporter = _reporter;
    if (reporter != null) {
      error.sendTo(reporter);
      return;
    }
    if (_pending.length == maxPending) {
      _pending.removeFirst();
    }
    _pending.add(error);
  }

  void _safeLog(String Function() message, StackTrace? stack) {
    try {
      _log(message(), stackTrace: stack);
    } catch (_) {
      // Logging must never turn one error into two.
    }
  }

  static String? _context(FlutterErrorDetails details) {
    try {
      return details.context?.toDescription();
    } catch (_) {
      return null;
    }
  }
}

final class _PendingError {
  _PendingError(this.error, this.stack, {required this.fatal, this.reason});

  final Object error;
  final StackTrace? stack;
  final bool fatal;
  final String? reason;

  void sendTo(CrashReporter reporter) => fireAndForget(
    () => reporter.recordError(error, stack, fatal: fatal, reason: reason),
  );
}
