import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late RecordingPerformanceTracer adapter;
  late PerformanceTracer tracer;

  setUp(() {
    adapter = RecordingPerformanceTracer();
    tracer = Observability(
      crash: RecordingCrashReporter(),
      analytics: RecordingAnalyticsTracker(),
      performance: adapter,
      flags: LocalFeatureFlags(debugLogging: false),
      debugLogging: false,
    ).performance;
  });

  test('forwards safe attributes and stops once', () async {
    final trace = tracer.start('load_orders')
      ..setAttribute('source', 'network')
      ..setAttribute('email', 'ada@example.com')
      ..setAttribute('page', '0901234567');
    await trace.stop();
    await trace.stop();
    trace.setAttribute('late', 'ignored');

    final recorded = adapter.traces.single;
    expect(recorded.name, 'load_orders');
    expect(recorded.attributes, {'source': 'network'});
    expect(recorded.stopCount, 1);
  });

  test('keeps at most five attributes', () {
    final trace = tracer.start('list_render');
    for (var i = 0; i < 7; i++) {
      trace.setAttribute('a$i', 'v');
    }

    expect(adapter.traces.single.attributes.keys, [
      'a0',
      'a1',
      'a2',
      'a3',
      'a4',
    ]);
  });

  test('ignores traces with invalid names', () async {
    final trace = tracer.start('/orders?id=1')..setAttribute('a', 'b');
    await trace.stop();

    expect(adapter.traces, isEmpty);
  });
}
