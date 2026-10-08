/// Summarizes HTTP requests captured by the VM service HTTP profiler.
///
/// Pure Dart so it can be unit tested on the host. Query strings are dropped
/// so tokens or personal data in URLs never reach a report.
library;

import 'network_errors.dart';

class HttpSample {
  const HttpSample({
    required this.method,
    required this.uri,
    required this.start,
    this.end,
    this.statusCode,
    this.responseBytes,
    this.error,
  });

  final String method;
  final Uri uri;
  final DateTime start;
  final DateTime? end;
  final int? statusCode;
  final int? responseBytes;
  final String? error;
}

/// Endpoints slower than this are listed as slow.
const int _slowRequestMs = 1000;

Map<String, Object> summarizeNetwork(
  List<HttpSample> samples, {
  bool authenticated = true,
}) {
  final durations = <double>[];
  final endpoints = <String, _Endpoint>{};
  final failures = <Map<String, Object>>[];
  var failed = 0;
  var bytes = 0;
  for (final sample in samples) {
    final key = '${sample.method} ${_redact(sample.uri)}';
    final endpoint = endpoints[key] ??= _Endpoint(key);
    endpoint.count++;
    final status = sample.statusCode;
    final isFailure = sample.error != null || status == null || status >= 400;
    if (isFailure) {
      failed++;
      endpoint.failures++;
      endpoint.lastFailure = sample.error ?? 'HTTP ${status ?? 'no response'}';
      final verdict = classifyFailure(
        statusCode: status,
        error: sample.error,
        authenticated: authenticated,
      );
      failures.add({
        'endpoint': key,
        'status': ?status,
        'error': ?sample.error,
        'at': sample.start.toUtc().toIso8601String(),
        ...verdict.toJson(),
      });
    }
    final size = sample.responseBytes;
    if (size != null && size > 0) {
      bytes += size;
      endpoint.bytes += size;
    }
    final end = sample.end;
    if (end != null) {
      final ms = end.difference(sample.start).inMicroseconds / 1000;
      durations.add(ms);
      endpoint.durations.add(ms);
    }
  }
  durations.sort();
  final ranked = endpoints.values.toList()
    ..sort((a, b) => b.worstMs.compareTo(a.worstMs));
  return {
    'request_count': samples.length,
    'failed_count': failed,
    'failures': failures,
    'response_kb': _round(bytes / 1024),
    'request_p50_ms': _round(_percentile(durations, 0.50)),
    'request_p95_ms': _round(_percentile(durations, 0.95)),
    'request_max_ms': _round(durations.isEmpty ? 0 : durations.last),
    'endpoints': [
      for (final e in ranked.take(15))
        {
          'endpoint': e.key,
          'count': e.count,
          'worst_ms': _round(e.worstMs),
          'response_kb': _round(e.bytes / 1024),
          'failures': e.failures,
          if (e.lastFailure != null) 'last_failure': e.lastFailure!,
          'slow': e.worstMs > _slowRequestMs,
        },
    ],
  };
}

class _Endpoint {
  _Endpoint(this.key);
  final String key;
  final durations = <double>[];
  int count = 0;
  int failures = 0;
  int bytes = 0;
  String? lastFailure;
  double get worstMs => durations.isEmpty ? 0 : durations.reduce(_max);
  static double _max(double a, double b) => a > b ? a : b;
}

/// Keeps scheme, host and path, collapsing numeric or long id segments so
/// `/orders/123` and `/orders/456` count as one endpoint.
String _redact(Uri uri) {
  final segments = [
    for (final s in uri.pathSegments)
      RegExp(r'^\d+$').hasMatch(s) || RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(s)
          ? ':id'
          : s,
  ];
  return '${uri.scheme}://${uri.host}/${segments.join('/')}';
}

double _percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

double _round(num value) => (value * 100).roundToDouble() / 100;
