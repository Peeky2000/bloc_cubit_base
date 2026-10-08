import 'dart:developer' as developer;
import 'dart:isolate' show Isolate;
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show debugProfileBuildsEnabled;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart' as vm_io;

import 'network_summary.dart';
import 'timeline_hotspots.dart';

/// Frames slower than one 60 Hz vsync count as jank.
const double _jankBudgetMs = 1000 / 60;

/// Set by the runner for the separate, non-gated diagnosis run.
const bool _diagnose = bool.fromEnvironment('PERF_DIAGNOSE');

/// Measures [scenario] in profile mode and reports the result to the driver.
///
/// A normal run records engine `FrameTiming` and Dart heap usage only, so the
/// numbers are representative. A diagnosis run (`PERF_DIAGNOSE=true`) instead
/// enables per-widget build/layout/paint timeline events and reports the
/// slowest widgets. Its timings are inflated and are never gated.
/// How much real data a scenario loaded, such as `{'items': 2000}` for an
/// orders list. The runner scales data budgets with these counts so a screen
/// with more data gets a proportionally larger time budget.
typedef DataSize = Map<String, num> Function();

Future<void> measureScenario(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Future<void> Function() scenario, {
  DataSize? dataSize,
  bool authenticated = true,
}) async {
  if (!kProfileMode) {
    fail('Performance scenarios require Flutter profile mode.');
  }
  if (_diagnose) {
    await _diagnoseScenario(binding, scenario);
    return;
  }
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> frames) => timings.addAll(frames);
  final probe = await _VmProbe.connect();
  await probe?.startHttp();
  binding.addTimingsCallback(collect);
  final heapBefore = await probe?.heapBytes();
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
    final heapAfter = await probe?.heapBytes();
    final network = await probe?.httpSamples();
    double ms(Duration d) => d.inMicroseconds / 1000;
    final frame = [for (final t in timings) ms(t.totalSpan)]..sort();
    final build = [for (final t in timings) ms(t.buildDuration)]..sort();
    final raster = [for (final t in timings) ms(t.rasterDuration)]..sort();
    final memory = heapBefore == null || heapAfter == null
        ? const <String, Object>{'memory': 'unsupported'}
        : {
            'heap_start_mb': heapBefore / _mb,
            'heap_end_mb': heapAfter / _mb,
            'heap_growth_mb': (heapAfter - heapBefore) / _mb,
          };
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
        ...memory,
        if (network != null)
          'network': summarizeNetwork(network, authenticated: authenticated),
        if (dataSize != null)
          for (final e in dataSize().entries) 'data_${e.key}': e.value,
        if (network != null) ..._networkMetrics(network),
        'cpu': 'unsupported',
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
    await probe?.dispose();
  }
}

/// Flat numeric network metrics that the runner can median and compare.
Map<String, num> _networkMetrics(List<HttpSample> samples) {
  final summary = summarizeNetwork(samples);
  final failures = (summary['failures']! as List).cast<Map>();
  int owned(String owner) => failures.where((f) => f['owner'] == owner).length;
  return {
    'network_request_count': summary['request_count']! as num,
    'network_failed_count': summary['failed_count']! as num,
    'network_p95_ms': summary['request_p95_ms']! as num,
    'network_response_kb': summary['response_kb']! as num,
    'network_failed_mobile': owned('mobile'),
    'network_failed_backend': owned('backend'),
    'network_failed_network': owned('network'),
    'network_failed_environment': owned('environment'),
  };
}

const double _mb = 1024 * 1024;

/// VM service client for heap and HTTP profiling of the app isolate.
///
/// Needs `flutter drive --no-dds`. Returns null fields when the service or an
/// extension is unavailable so the frame benchmark still runs.
class _VmProbe {
  _VmProbe(this._service, this._isolateId);

  final vm.VmService _service;
  final String _isolateId;
  bool _httpEnabled = false;

  static Future<_VmProbe?> connect() async {
    try {
      final info = await developer.Service.getInfo();
      final uri = info.serverUri;
      final isolateId = developer.Service.getIsolateId(Isolate.current);
      if (uri == null || isolateId == null) return null;
      final service = await vm_io.vmServiceConnectUri(
        'ws://localhost:${uri.port}${uri.path}ws',
      );
      return _VmProbe(service, isolateId);
    } catch (_) {
      return null;
    }
  }

  /// Dart heap plus external usage after a forced GC.
  Future<int?> heapBytes() async {
    try {
      final profile = await _service.getAllocationProfile(_isolateId, gc: true);
      final memory = profile.memoryUsage;
      if (memory == null) return null;
      return (memory.heapUsage ?? 0) + (memory.externalUsage ?? 0);
    } catch (_) {
      return null;
    }
  }

  Future<void> startHttp() async {
    try {
      if (!await _service.isHttpProfilingAvailable(_isolateId)) return;
      await _service.httpEnableTimelineLogging(_isolateId, true);
      await _service.clearHttpProfile(_isolateId);
      _httpEnabled = true;
    } catch (_) {
      _httpEnabled = false;
    }
  }

  /// Requests made through dart:io during the scenario, without bodies.
  Future<List<HttpSample>?> httpSamples() async {
    if (!_httpEnabled) return null;
    try {
      final profile = await _service.getHttpProfile(_isolateId);
      return [
        for (final r in profile.requests)
          HttpSample(
            method: r.method,
            uri: r.uri,
            start: r.startTime,
            end: r.response?.endTime ?? r.endTime,
            statusCode: r.response?.statusCode,
            responseBytes: r.response?.contentLength,
            error: r.response?.error ?? r.request?.error,
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      if (_httpEnabled) {
        await _service.httpEnableTimelineLogging(_isolateId, false);
      }
    } catch (_) {}
    await _service.dispose();
  }
}

Future<void> _diagnoseScenario(
  IntegrationTestWidgetsFlutterBinding binding,
  Future<void> Function() scenario,
) async {
  // The user-widget-only flag needs widget creation tracking, which exists
  // only in debug (JIT) builds, so profile mode traces every widget.
  debugProfileBuildsEnabled = true;
  debugProfileLayoutsEnabled = true;
  debugProfilePaintsEnabled = true;
  try {
    final timeline = await binding.traceTimeline(
      scenario,
      streams: const ['Dart', 'Embedder', 'GC'],
    );
    binding.reportData = {'diagnosis': summarizeTimeline(timeline.toJson())};
  } finally {
    debugProfileBuildsEnabled = false;
    debugProfileLayoutsEnabled = false;
    debugProfilePaintsEnabled = false;
  }
}

/// Nearest-rank percentile: the smallest sample with at least `p` of the
/// samples at or below it. With fewer than 1 / (1 - p) samples, p95/p99 equal
/// the maximum, which is why the runner enforces `min_frame_count`.
double _percentile(List<double> sorted, double p) {
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}
