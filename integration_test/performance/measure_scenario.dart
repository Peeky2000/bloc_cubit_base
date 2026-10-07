import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> measureScenario(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Future<void> Function() scenario,
) async {
  if (!kProfileMode) {
    fail('Performance scenarios require Flutter profile mode.');
  }
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> frames) => timings.addAll(frames);
  binding.addTimingsCallback(collect);
  final watch = Stopwatch()..start();
  try {
    await scenario();
    watch.stop();
    // Engine timing callbacks can arrive after the last widget pump.
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 20 && timings.isEmpty; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    if (timings.isEmpty) {
      fail('No Flutter engine FrameTiming samples were captured.');
    }
    final frame = timings.map((t) => t.totalSpan.inMicroseconds / 1000).toList()
      ..sort();
    final build =
        timings.map((t) => t.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final raster =
        timings.map((t) => t.rasterDuration.inMicroseconds / 1000).toList()
          ..sort();
    binding.reportData = {
      'performance': {
        'frame_p50_ms': _percentile(frame, 0.50),
        'frame_p95_ms': _percentile(frame, 0.95),
        'frame_p99_ms': _percentile(frame, 0.99),
        'jank_percent':
            frame.where((ms) => ms > 16.67).length * 100 / frame.length,
        'frame_count': frame.length,
        'build_p95_ms': _percentile(build, 0.95),
        'raster_p95_ms': _percentile(raster, 0.95),
        'scenario_ms': watch.elapsedMilliseconds,
        'startup_ms': 'unsupported',
        'cpu': 'unsupported',
        'memory': 'unsupported',
        'raw_frames': [
          for (final timing in timings)
            {
              'frame_ms': timing.totalSpan.inMicroseconds / 1000,
              'build_ms': timing.buildDuration.inMicroseconds / 1000,
              'raster_ms': timing.rasterDuration.inMicroseconds / 1000,
            },
        ],
      },
    };
  } finally {
    binding.removeTimingsCallback(collect);
  }
}

double _percentile(List<double> sorted, double p) =>
    sorted[((sorted.length - 1) * p).ceil()];
