import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/gate.dart';

void main() {
  const config = GateConfig(
    limits: {'frame_p95_ms': 20, 'jank_percent': 3},
    maxRegressionPercent: 5,
    zeroBaselineDelta: {'frame_p95_ms': 1, 'jank_percent': 0.5},
    minFrameCount: 20,
  );

  test('passes within limits and without a baseline', () {
    final result = evaluate(
      {'frame_p95_ms': 12, 'jank_percent': 1, 'frame_count': 40},
      null,
      config,
    );
    expect(result.passed, isTrue);
    expect(result.comparison, isEmpty);
  });

  test('fails a hard limit', () {
    final result = evaluate(
      {'frame_p95_ms': 25, 'jank_percent': 1, 'frame_count': 40},
      null,
      config,
    );
    expect(result.failures, ['frame_p95_ms 25.00 > 20.00']);
  });

  test('fails a relative regression even below the hard limit', () {
    final result = evaluate(
      {'frame_p95_ms': 14, 'jank_percent': 1, 'frame_count': 40},
      {'frame_p95_ms': 10, 'jank_percent': 1},
      config,
    );
    expect(result.failures.single, startsWith('frame_p95_ms regression +40'));
    expect(
      result.comparison['frame_p95_ms']!['change_percent'],
      closeTo(40, 1e-9),
    );
  });

  test('gates a zero baseline with the absolute delta', () {
    final regressed = evaluate(
      {'frame_p95_ms': 10, 'jank_percent': 2.9, 'frame_count': 40},
      {'frame_p95_ms': 10, 'jank_percent': 0},
      config,
    );
    expect(regressed.failures.single, contains('from zero baseline'));

    final noisy = evaluate(
      {'frame_p95_ms': 10, 'jank_percent': 0.4, 'frame_count': 40},
      {'frame_p95_ms': 10, 'jank_percent': 0},
      config,
    );
    expect(noisy.passed, isTrue);
    expect(noisy.comparison['jank_percent']!['change_percent'], isNull);
  });

  test('requires enough frames for meaningful percentiles', () {
    final result = evaluate(
      {'frame_p95_ms': 10, 'jank_percent': 0, 'frame_count': 3},
      null,
      config,
    );
    expect(result.failures.single, startsWith('frame_count 3.00 < 20.00'));
  });

  test('reports a gated metric that was not measured', () {
    final result = evaluate({'frame_count': 40}, null, config);
    expect(result.failures, hasLength(2));
    expect(result.failures.first, contains('missing'));
  });

  test('applies optional limits only when the metric was measured', () {
    const withNetwork = GateConfig(
      limits: {},
      maxRegressionPercent: 5,
      optionalLimits: {'network_failed_count': 0},
    );
    expect(evaluate({}, null, withNetwork).passed, isTrue);
    expect(evaluate({'network_failed_count': 2}, null, withNetwork).failures, [
      'network_failed_count 2.00 > 0.00',
    ]);
  });
}
