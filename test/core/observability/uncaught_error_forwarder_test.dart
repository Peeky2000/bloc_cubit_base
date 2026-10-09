import 'dart:async';

import 'package:bloc_cubit_base/bootstrap.dart';
import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late LogSink sink;
  late RecordingCrashReporter adapter;
  late UncaughtErrorForwarder forwarder;
  late Observability observability;

  setUp(() {
    sink = LogSink();
    adapter = RecordingCrashReporter();
    forwarder = UncaughtErrorForwarder(log: sink.call);
    observability = Observability(
      crash: adapter,
      analytics: RecordingAnalyticsTracker(),
      performance: RecordingPerformanceTracer(),
      flags: LocalFeatureFlags(debugLogging: false),
      debugLogging: false,
    );
  });

  test('forwards Flutter errors with redaction and keeps the log', () async {
    attachObservability(forwarder, observability);
    final stack = StackTrace.current;

    forwarder.onFlutterError(
      FlutterErrorDetails(
        exception: Exception('layout failed for ada@example.com'),
        stack: stack,
        context: ErrorDescription('during layout'),
      ),
    );
    await pumpEventQueue();

    expect(sink.lines.single, contains('ada@example.com'));
    final recorded = adapter.errors.single;
    expect(
      recorded.error.toString(),
      'Exception: layout failed for <redacted>',
    );
    expect(recorded.stack, same(stack));
    expect(recorded.fatal, isTrue);
    expect(recorded.reason, 'during layout');
  });

  test('reports silent Flutter errors as non-fatal', () async {
    forwarder.attach(observability.crash);

    forwarder.onFlutterError(
      FlutterErrorDetails(exception: Exception('image 404'), silent: true),
    );
    await pumpEventQueue();

    expect(adapter.errors.single.fatal, isFalse);
  });

  test('forwards platform dispatcher and zone errors as fatal', () async {
    forwarder.attach(observability.crash);

    final handled = forwarder.onPlatformError(
      StateError('token Bearer secret'),
      StackTrace.empty,
    );
    runZonedGuarded(() => throw ArgumentError('zone'), forwarder.onZoneError);
    await pumpEventQueue();

    expect(handled, isTrue);
    expect(sink.lines, hasLength(2));
    expect(adapter.errors.map((e) => e.fatal), [true, true]);
    expect(
      adapter.errors.first.error.toString(),
      'Bad state: token Bearer <redacted>',
    );
    expect(adapter.errors.last.error.toString(), contains('zone'));
  });

  test('keeps early errors and sends them once attached', () async {
    for (var i = 0; i < UncaughtErrorForwarder.maxPending + 5; i++) {
      forwarder.onZoneError(StateError('early $i'), StackTrace.empty);
    }
    await pumpEventQueue();
    expect(adapter.errors, isEmpty);
    expect(sink.lines, hasLength(UncaughtErrorForwarder.maxPending + 5));

    forwarder.attach(observability.crash);
    await pumpEventQueue();

    expect(adapter.errors, hasLength(UncaughtErrorForwarder.maxPending));
    expect(adapter.errors.first.error.toString(), 'Bad state: early 5');
  });

  test('a failing reporter or log never throws from a handler', () async {
    void broken(String message, {Object? error, StackTrace? stackTrace}) =>
        throw StateError('console gone');
    final fragile = UncaughtErrorForwarder(log: broken)
      ..attach(ThrowingAdapters());

    fragile
      ..onFlutterError(FlutterErrorDetails(exception: Exception('x')))
      ..onZoneError(Exception('y'), StackTrace.empty);
    expect(fragile.onPlatformError(Exception('z'), StackTrace.empty), isTrue);
    await pumpEventQueue();
  });

  test('install routes Flutter and platform dispatcher errors', () async {
    final previousFlutter = FlutterError.onError;
    final dispatcher = PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      dispatcher.onError = previousPlatform;
    });

    forwarder
      ..install(dispatcher: dispatcher)
      ..attach(observability.crash);
    FlutterError.onError!(FlutterErrorDetails(exception: Exception('a')));
    final handled = dispatcher.onError!(Exception('b'), StackTrace.empty);
    await pumpEventQueue();

    expect(handled, isTrue);
    expect(adapter.errors, hasLength(2));
  });

  test('attachObservability refreshes flags', () async {
    var refreshes = 0;
    final bundle = Observability(
      crash: adapter,
      analytics: RecordingAnalyticsTracker(),
      performance: RecordingPerformanceTracer(),
      flags: _CountingFlags(() => refreshes++),
      debugLogging: false,
    );

    attachObservability(forwarder, bundle);
    await pumpEventQueue();

    expect(refreshes, 1);
  });

  test('attachObservability survives an offline flag refresh', () async {
    attachObservability(
      forwarder,
      Observability(
        crash: adapter,
        analytics: RecordingAnalyticsTracker(),
        performance: RecordingPerformanceTracer(),
        flags: ThrowingAdapters(),
        debugLogging: false,
      ),
    );
    await pumpEventQueue();

    forwarder.onZoneError(StateError('after'), StackTrace.empty);
    await pumpEventQueue();
    expect(adapter.errors.single.error.toString(), 'Bad state: after');
  });
}

final class _CountingFlags implements FeatureFlags {
  _CountingFlags(this._onRefresh);

  final void Function() _onRefresh;

  @override
  T value<T extends Object>(FeatureFlag<T> flag) => flag.defaultValue;

  @override
  Future<bool> refresh() async {
    _onRefresh();
    return false;
  }
}
