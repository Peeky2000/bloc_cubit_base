import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:flutter/foundation.dart';

/// Measures a named piece of work, such as loading a list.
///
/// ```dart
/// final trace = tracer.start('load_orders');
/// try {
///   await loadOrders();
///   trace.setAttribute('source', 'network');
/// } finally {
///   await trace.stop();
/// }
/// ```
abstract interface class PerformanceTracer {
  TraceHandle start(String name);
}

/// A running trace returned by [PerformanceTracer.start].
abstract interface class TraceHandle {
  /// Adds a non-personal dimension, at most 5 per trace.
  void setAttribute(String name, String value);

  /// Ends the trace. Calling it again does nothing.
  Future<void> stop();
}

/// Times traces on the device and prints them to the debug console during
/// debug builds. Nothing is sent anywhere.
final class LocalPerformanceTracer implements PerformanceTracer {
  LocalPerformanceTracer({
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
  }) : _redactor = redactor,
       _debug = DebugDiagnostics(log: log, enabled: debugLogging);

  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  TraceHandle start(String name) =>
      _LocalTrace(_redactor.text(name), _redactor, _debug);
}

final class _LocalTrace implements TraceHandle {
  _LocalTrace(this._name, this._redactor, this._debug)
    : _stopwatch = Stopwatch()..start();

  final String _name;
  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;
  final Stopwatch _stopwatch;
  final _attributes = <String, String>{};

  @override
  void setAttribute(String name, String value) {
    if (_stopwatch.isRunning) {
      _attributes[_redactor.text(name)] = _redactor.text(value);
    }
  }

  @override
  Future<void> stop() async {
    if (!_stopwatch.isRunning) {
      return;
    }
    _stopwatch.stop();
    _debug(
      'performance: $_name took ${_stopwatch.elapsedMilliseconds} ms '
      '$_attributes',
    );
  }
}

/// Applies the naming and privacy rules in front of any [PerformanceTracer]
/// adapter.
///
/// - Trace names match `[A-Za-z][A-Za-z0-9_]{0,99}`; others get a no-op trace.
/// - At most 5 attributes per trace. Names match `[A-Za-z][A-Za-z0-9_]{0,39}`
///   and must not name personal data. Values that look personal are dropped;
///   others are cut to 100 characters.
/// - `stop()` runs once. Adapter failures are swallowed.
final class SafePerformanceTracer implements PerformanceTracer {
  SafePerformanceTracer(
    this._inner, {
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DebugDiagnostics debug = const DebugDiagnostics(),
  }) : _redactor = redactor,
       _debug = debug;

  static const maxAttributes = 5;
  static const maxAttributeValueLength = 100;
  static final _traceName = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,99}$');

  final PerformanceTracer _inner;
  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;

  @override
  TraceHandle start(String name) {
    if (!_traceName.hasMatch(name)) {
      _debug('performance: dropped trace with invalid name');
      return const _NoopTrace();
    }
    try {
      return _SafeTrace(_inner.start(name), _redactor, _debug);
    } catch (error) {
      _debug('performance: adapter failed with ${error.runtimeType}');
      return const _NoopTrace();
    }
  }
}

final class _SafeTrace implements TraceHandle {
  _SafeTrace(this._inner, this._redactor, this._debug);

  static final _attributeName = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$');

  final TraceHandle _inner;
  final DiagnosticRedactor _redactor;
  final DebugDiagnostics _debug;
  final _names = <String>{};
  var _stopped = false;

  @override
  void setAttribute(String name, String value) {
    final isNew = !_names.contains(name);
    if (_stopped ||
        (isNew && _names.length >= SafePerformanceTracer.maxAttributes) ||
        !_attributeName.hasMatch(name) ||
        _redactor.isSensitiveKey(name) ||
        _redactor.containsPersonalData(value)) {
      _debug('performance: dropped attribute "${_redactor.text(name)}"');
      return;
    }
    try {
      _inner.setAttribute(
        name,
        value.length > SafePerformanceTracer.maxAttributeValueLength
            ? value.substring(0, SafePerformanceTracer.maxAttributeValueLength)
            : value,
      );
      _names.add(name);
    } catch (error) {
      _debug('performance: adapter failed with ${error.runtimeType}');
    }
  }

  @override
  Future<void> stop() async {
    if (_stopped) {
      return;
    }
    _stopped = true;
    try {
      await _inner.stop();
    } catch (error) {
      _debug('performance: adapter failed with ${error.runtimeType}');
    }
  }
}

final class _NoopTrace implements TraceHandle {
  const _NoopTrace();

  @override
  void setAttribute(String name, String value) {}

  @override
  Future<void> stop() async {}
}
