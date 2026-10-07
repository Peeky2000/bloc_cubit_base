import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Frames slower than one 60 Hz vsync count as jank.
const double _jankBudgetMs = 1000 / 60;

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
    double ms(Duration d) => d.inMicroseconds / 1000;
    final frame = [for (final t in timings) ms(t.totalSpan)]..sort();
    final build = [for (final t in timings) ms(t.buildDuration)]..sort();
    final raster = [for (final t in timings) ms(t.rasterDuration)]..sort();
    binding.reportData = {
      'performance': {
        'frame_p50_ms': _percentile(frame, 0.50),
        'frame_p95_ms': _percentile(frame, 0.95),
        'frame_p99_ms': _percentile(frame, 0.99),
        'jank_percent':
            frame.where((v) => v > _jankBudgetMs).length * 100 / frame.length,
        'frame_count': frame.length,
        'build_p95_ms': _percentile(build, 0.95),
        'raster_p95_ms': _percentile(raster, 0.95),
        'scenario_ms': watch.elapsedMilliseconds,
        'startup_ms': 'unsupported',
        'cpu': 'unsupported',
        'memory': 'unsupported',
        'raw_frames': [
          for (final t in timings)
            {
              'frame_ms': ms(t.totalSpan),
              'build_ms': ms(t.buildDuration),
              'raster_ms': ms(t.rasterDuration),
            },
        ],
      },
    };
  } finally {
    binding.removeTimingsCallback(collect);
  }
}

/// Nearest-rank percentile: the smallest sample with at least `p` of the
/// samples at or below it. With fewer than 1 / (1 - p) samples, p95/p99 equal
/// the maximum, which is why the runner enforces `min_frame_count`.
double _percentile(List<double> sorted, double p) {
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}
