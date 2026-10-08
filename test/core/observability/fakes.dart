import 'package:bloc_cubit_base/core/observability/observability.dart';

final class RecordedError {
  RecordedError(this.error, this.stack, {required this.fatal, this.reason});

  final Object error;
  final StackTrace? stack;
  final bool fatal;
  final String? reason;
}

final class RecordingCrashReporter implements CrashReporter {
  final errors = <RecordedError>[];
  final breadcrumbs = <String>[];
  final userIds = <String>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async =>
      errors.add(RecordedError(error, stack, fatal: fatal, reason: reason));

  @override
  Future<void> log(String message) async => breadcrumbs.add(message);

  @override
  Future<void> setUserIdentifier(String hashedId) async =>
      userIds.add(hashedId);
}

final class RecordingAnalyticsTracker implements AnalyticsTracker {
  final screens = <String>[];
  final events = <(String, Map<String, Object>)>[];

  @override
  Future<void> screenView(String name) async => screens.add(name);

  @override
  Future<void> event(
    String name, {
    Map<String, Object> params = const {},
  }) async => events.add((name, params));
}

final class RecordingPerformanceTracer implements PerformanceTracer {
  final traces = <RecordingTrace>[];

  @override
  TraceHandle start(String name) {
    final trace = RecordingTrace(name);
    traces.add(trace);
    return trace;
  }
}

final class RecordingTrace implements TraceHandle {
  RecordingTrace(this.name);

  final String name;
  final attributes = <String, String>{};
  var stopCount = 0;

  @override
  void setAttribute(String name, String value) => attributes[name] = value;

  @override
  Future<void> stop() async => stopCount++;
}

/// Every member throws, to prove the wrappers contain adapter failures.
final class ThrowingAdapters
    implements
        CrashReporter,
        AnalyticsTracker,
        PerformanceTracer,
        TraceHandle,
        FeatureFlags {
  ThrowingAdapters({this.throwOnStart = true});

  final bool throwOnStart;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => Future.error(StateError('adapter down'));

  @override
  Future<void> log(String message) => throw StateError('adapter down');

  @override
  Future<void> setUserIdentifier(String hashedId) =>
      throw StateError('adapter down');

  @override
  Future<void> screenView(String name) => Future.error(StateError('down'));

  @override
  Future<void> event(String name, {Map<String, Object> params = const {}}) =>
      throw StateError('adapter down');

  @override
  TraceHandle start(String name) =>
      throwOnStart ? throw StateError('adapter down') : this;

  @override
  void setAttribute(String name, String value) =>
      throw StateError('adapter down');

  @override
  Future<void> stop() => throw StateError('adapter down');

  @override
  T value<T extends Object>(FeatureFlag<T> flag) =>
      throw StateError('adapter down');

  @override
  Future<bool> refresh() => Future.error(StateError('offline'));
}

/// Collects debug diagnostics instead of printing them.
final class LogSink {
  final lines = <String>[];

  void call(String message, {Object? error, StackTrace? stackTrace}) =>
      lines.add(message);
}
