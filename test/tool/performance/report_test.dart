import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/report.dart';

void main() {
  final report = <String, dynamic>{
    'target': 'orders',
    'status': 'FAIL',
    'summary': {'frame_p95_ms': 21.5},
    'comparison': {
      'frame_p95_ms': {'baseline': 20, 'change_percent': 7.5},
    },
    'failures': ['frame_p95_ms 21.50 > 20.00'],
    'rating': 'NEEDS_IMPROVEMENT',
    'ratings': {
      'frame_p95_ms': {
        'value': 21.5,
        'good': 16.67,
        'poor': 33,
        'rating': 'NEEDS_IMPROVEMENT',
      },
    },
    'targets': {'status': 'proposed', 'rationale': 'AC-3'},
    'request_failures': {
      'total': 1,
      'backend': {
        'count': 1,
        'retry': 'auto',
        'examples': [
          {'endpoint': '/orders', 'status': 503, 'reason': 'unavailable'},
        ],
      },
    },
    'network': {
      'request_count': 4,
      'failed_count': 1,
      'request_p95_ms': 800,
      'response_kb': 12,
      'endpoints': [
        {
          'endpoint': '/orders',
          'slow': true,
          'count': 2,
          'worst_ms': 900,
          'response_kb': 10,
          'failures': 1,
        },
      ],
    },
  };

  test('target markdown has metrics, rating, targets, triage and network', () {
    final md = targetMarkdown(report);
    expect(md, startsWith('# orders: FAIL\n'));
    expect(md, contains('| frame_p95_ms | 21.50 | 20.00 | 7.50% |'));
    expect(md, contains('Failures: frame_p95_ms 21.50 > 20.00'));
    expect(md, contains('## Rating: NEEDS_IMPROVEMENT'));
    expect(
      md,
      contains(
        '| frame_p95_ms | 21.50 | 16.67 | 33.00 |  | NEEDS_IMPROVEMENT |',
      ),
    );
    expect(md, contains('Targets: PROPOSED, not yet approved by the PM. AC-3'));
    expect(md, contains('## Failed requests by owner'));
    expect(md, contains('| backend | 1 | auto | /orders 503: unavailable |'));
    expect(md, contains('## Network (last measured run'));
    expect(md, contains('| /orders (slow) | 2 | 900.00 | 10.00 | 1 |'));
  });

  test('approved targets, no triage table without failures, log tail', () {
    final md = targetMarkdown({
      ...report,
      'targets': {'status': 'approved', 'rationale': 'PM'},
      'request_failures': {'total': 0},
      'log_tail': 'exit 1',
    });
    expect(md, contains('Targets: approved. PM'));
    expect(md, isNot(contains('Failed requests by owner')));
    expect(md, contains('```text\nexit 1\n```'));
  });

  test('summary markdown labels proposed targets and pending re-runs', () {
    final md = summaryMarkdown({
      'status': 'ERROR',
      'timestamp': 't',
      'environment': {
        'device_name': 'Pixel',
        'platform': 'android',
        'flavor': 'dev',
        'flutter_version': '3.1',
      },
      'targets': [
        {
          'id': 'orders',
          'status': 'FAIL',
          'rating': 'POOR',
          'targets': {'status': 'proposed'},
          'failures': ['a', 'b'],
          'report': 'r.json',
          'network': report['network'],
        },
      ],
      'pending_reruns': [
        {
          'id': 'home',
          'reason': 'backend down',
          'owners': ['backend'],
          'action': 'Re-run later',
        },
      ],
      'uncovered_routes': <String>[],
    });
    expect(md, startsWith('# Performance run: ERROR\n'));
    expect(md, contains('| orders | FAIL | POOR (proposed targets) | a; b |'));
    expect(md, contains('### orders'));
    expect(md, contains('## Waiting for a re-run'));
    expect(
      md,
      contains('- home: backend down (owners: backend). Re-run later'),
    );
    expect(md, contains('Routes without scenarios: none'));
  });

  test('formatValue', () {
    expect(formatValue(1), '1.00');
    expect(formatValue(null), 'n/a');
  });
}
