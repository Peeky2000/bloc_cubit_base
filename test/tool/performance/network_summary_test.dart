import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/performance/network_summary.dart';

HttpSample _sample(
  String path, {
  int ms = 100,
  int? status = 200,
  int bytes = 1024,
  String? error,
}) {
  final start = DateTime(2026);
  return HttpSample(
    method: 'GET',
    uri: Uri.parse('https://api.example.com$path?token=secret&phone=0901'),
    start: start,
    end: start.add(Duration(milliseconds: ms)),
    statusCode: status,
    responseBytes: bytes,
    error: error,
  );
}

void main() {
  test('groups ids, drops query strings and ranks by worst time', () {
    final summary = summarizeNetwork([
      _sample('/orders/123', ms: 300),
      _sample('/orders/456', ms: 1500, bytes: 4096),
      _sample('/profile', ms: 80),
    ]);

    final endpoints = (summary['endpoints']! as List).cast<Map>();
    expect(
      endpoints.first['endpoint'],
      'GET https://api.example.com/orders/:id',
    );
    expect(endpoints.first['count'], 2);
    expect(endpoints.first['slow'], isTrue);
    expect(endpoints.first['response_kb'], 5.0);
    expect(summary.toString(), isNot(contains('secret')));
    expect(summary.toString(), isNot(contains('0901')));
    expect(summary['request_count'], 3);
    expect(summary['request_max_ms'], 1500.0);
  });

  test('counts HTTP errors and transport failures', () {
    final summary = summarizeNetwork([
      _sample('/orders', status: 500),
      _sample('/orders', status: null, error: 'SocketException'),
      _sample('/orders'),
    ]);

    expect(summary['failed_count'], 2);
    final endpoint = (summary['endpoints']! as List).single as Map;
    expect(endpoint['failures'], 2);
    expect(endpoint['last_failure'], 'SocketException');
  });

  test('returns zeros when there was no traffic', () {
    final summary = summarizeNetwork(const []);
    expect(summary['request_count'], 0);
    expect(summary['request_p95_ms'], 0);
    expect(summary['endpoints'], isEmpty);
  });

  test('classifies each failed request by owner', () {
    final summary = summarizeNetwork([
      _sample('/orders', status: 503),
      _sample('/orders/9', status: 404),
    ]);
    final failures = (summary['failures']! as List).cast<Map>();
    expect(failures.map((f) => f['owner']), ['backend', 'mobile']);
    expect(failures.first['retry'], 'later');
    expect(failures.last['endpoint'], 'GET https://api.example.com/orders/:id');
  });
}
