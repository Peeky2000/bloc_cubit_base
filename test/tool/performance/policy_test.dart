import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/policy.dart';

Map<String, dynamic> _config() =>
    jsonDecode('''
{
  "startup": {
    "enabled": true,
    "target": "lib/main_dev.dart",
    "runs": 3,
    "max_first_frame_ms": 2000.0,
    "bands": {"startup_first_frame_ms": [1500.0, 5000.0]}
  },
  "retry": {"max_extra_runs": 2, "delay_seconds": 30},
  "bands": {"frame_p95_ms": [16.67, 33.0]},
  "data_budgets": {
    "orders": {
      "scenario_ms": {"items_metric": "data_items", "base_ms": 1000}
    }
  },
  "thresholds": {
    "max_jank_percent": 3.0,
    "max_frame_p95_ms": 20.0,
    "max_frame_p99_ms": 32.0,
    "max_scenario_ms": 15000.0,
    "max_regression_percent": 5.0,
    "min_frame_count": 20,
    "zero_baseline_regression_delta": {
      "jank_percent": 0.5,
      "frame_p95_ms": 1.0,
      "frame_p99_ms": 2.0,
      "scenario_ms": 50.0
    },
    "max_network_failures": 0
  }
}
''')
        as Map<String, dynamic>;

Matcher _formatError(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', message),
);

bool _exists(String _) => true;

Map<String, dynamic> _failure(String owner, {String retry = 'auto'}) => {
  'owner': owner,
  'retry': retry,
  'endpoint': '/orders',
  'status': 503,
  'reason': 'unavailable',
};

Map<String, dynamic> _sample(List<Map<String, dynamic>> failures) => {
  'network': {'failures': failures},
};

void main() {
  group('TargetStatus', () {
    test('labels and exit codes', () {
      expect(TargetStatus.values.map((s) => s.label), [
        'PASS',
        'FAIL',
        'ERROR',
      ]);
      expect(TargetStatus.values.map((s) => s.exitCode), [0, 1, 3]);
      expect(TargetStatus.fromGate(true), TargetStatus.pass);
      expect(TargetStatus.fromGate(false), TargetStatus.fail);
    });

    test('error beats fail beats pass', () {
      const s = TargetStatus.values;
      expect(TargetStatus.overall(const []), TargetStatus.pass);
      expect(TargetStatus.overall([s[0], s[0]]), TargetStatus.pass);
      expect(TargetStatus.overall([s[0], s[1], s[0]]), TargetStatus.fail);
      expect(TargetStatus.overall([s[2], s[1], s[0]]), TargetStatus.error);
    });
  });

  group('config validation', () {
    test('parses the scenario gate', () {
      final gate = parseScenarioGate(_config());
      expect(gate.limits['frame_p95_ms'], 20.0);
      expect(gate.maxRegressionPercent, 5.0);
      expect(gate.zeroBaselineDelta['scenario_ms'], 50.0);
      expect(gate.optionalLimits, {'network_failed_count': 0});
    });

    test('missing thresholds or one of its keys', () {
      expect(
        () => parseScenarioGate(_config()..remove('thresholds')),
        _formatError('thresholds is required'),
      );
      final config = _config();
      (config['thresholds'] as Map).remove('max_frame_p99_ms');
      expect(
        () => parseScenarioGate(config),
        _formatError('Invalid thresholds.max_frame_p99_ms'),
      );
      final zero = _config();
      (zero['thresholds'] as Map).remove('zero_baseline_regression_delta');
      expect(
        () => parseScenarioGate(zero),
        _formatError('thresholds.zero_baseline_regression_delta is required'),
      );
    });

    test('bad band', () {
      final config = _config()
        ..['bands'] = {
          'frame_p95_ms': [40, 20],
        };
      expect(() => parseBands(config), throwsFormatException);
      expect(
        () => parseBands(_config()..remove('bands')),
        _formatError('bands is required'),
      );
    });

    test('bad budget', () {
      expect(parseBudgets(_config())['orders']!['scenario_ms']!.baseMs, 1000);
      final missingBase = _config()
        ..['data_budgets'] = {
          'orders': {
            'scenario_ms': {'items_metric': 'data_items'},
          },
        };
      expect(
        () => parseBudgets(missingBase),
        _formatError('budget.scenario_ms.base_ms must be a number >= 0'),
      );
      final notObject = _config()..['data_budgets'] = {'orders': 'fast'};
      expect(
        () => parseBudgets(notObject),
        _formatError('data_budgets.orders must be an object'),
      );
    });

    test('retry policy', () {
      final retry = parseRetryPolicy(_config());
      expect(retry.maxExtraRuns, 2);
      expect(retry.delay, const Duration(seconds: 30));
      expect(
        () => parseRetryPolicy(_config()..remove('retry')),
        _formatError('retry is required'),
      );
      final negative = _config()..['retry'] = {'max_extra_runs': -1};
      expect(
        () => parseRetryPolicy(negative),
        _formatError('Invalid max_extra_runs'),
      );
    });

    test('startup validates thresholds itself', () {
      final startup = parseStartup(_config(), exists: _exists)!;
      expect(startup.runs, 3);
      expect(startup.gate.limits, {'startup_first_frame_ms': 2000.0});
      expect(startup.gate.maxRegressionPercent, 5.0);
      expect(startup.bands.keys, ['startup_first_frame_ms']);

      // No gate parsed first: still a clear FormatException, not a cast error.
      expect(
        () => parseStartup(_config()..remove('thresholds'), exists: _exists),
        _formatError('thresholds is required'),
      );
      final noRegression = _config();
      (noRegression['thresholds'] as Map).remove('max_regression_percent');
      expect(
        () => parseStartup(noRegression, exists: _exists),
        _formatError('Invalid thresholds.max_regression_percent'),
      );
    });

    test('startup disabled, missing target, bad enabled', () {
      final disabled = _config();
      (disabled['startup'] as Map)['enabled'] = false;
      expect(parseStartup(disabled, exists: _exists), isNull);
      expect(parseStartup(_config()..remove('startup'), exists: _exists), null);
      expect(
        () => parseStartup(_config(), exists: (_) => false),
        _formatError('startup.target does not exist: lib/main_dev.dart'),
      );
      final bad = _config();
      (bad['startup'] as Map)['enabled'] = 'yes';
      expect(
        () => parseStartup(bad, exists: _exists),
        _formatError('startup.enabled must be a bool'),
      );
    });

    test('primitives', () {
      expect(requireString({'a': 'x'}, 'a'), 'x');
      expect(
        () => requireString({'a': ''}, 'a'),
        _formatError('a is required'),
      );
      expect(requireCount({'n': 0}, 'n', zero: true), 0);
      expect(() => requireCount({'n': 0}, 'n'), _formatError('Invalid n'));
      expect(
        () => requireNumber({'n': -1}, 'n', 'x.n'),
        _formatError('Invalid x.n'),
      );
    });
  });

  group('scenario descriptors', () {
    Map<String, dynamic> descriptor({Object? targets}) => {
      'id': 'orders',
      'description': 'Orders list',
      'routes': ['/orders'],
      'test': 'integration_test/performance/scenarios/orders_test.dart',
      'enabled': true,
      'targets': ?targets,
    };

    test('parses targets', () {
      final scenarios = parseScenarios([
        (
          path: 'orders.json',
          json: descriptor(
            targets: {
              'status': 'proposed',
              'rationale': 'AC-3: list opens in 1 s',
              'bands': {
                'scenario_ms': [1000, 2000],
              },
            },
          ),
        ),
      ], exists: _exists);
      final targets = scenarios.single.targets!;
      expect(targets.status, 'proposed');
      expect(targets.bands['scenario_ms']!.poor, 2000);
      expect(targets.toJson(), {
        'status': 'proposed',
        'rationale': 'AC-3: list opens in 1 s',
      });
    });

    test('bad targets status', () {
      expect(
        () => parseTargets({'status': 'draft', 'rationale': 'x'}, 'a.json'),
        _formatError('a.json: targets.status must be proposed or approved'),
      );
      expect(
        () => parseTargets({'status': 'approved'}, 'a.json'),
        _formatError('a.json: targets.rationale is required'),
      );
    });

    test('rejects duplicate ids, startup id and missing test files', () {
      final file = (path: 'a.json', json: descriptor());
      expect(
        () => parseScenarios([file, file], exists: _exists),
        _formatError('Invalid scenario descriptor: a.json'),
      );
      expect(
        () => parseScenarios([
          (path: 's.json', json: descriptor()..['id'] = 'startup'),
        ], exists: _exists),
        throwsFormatException,
      );
      expect(
        () => parseScenarios([file], exists: (_) => false),
        throwsFormatException,
      );
    });
  });

  group('samples', () {
    Map<String, dynamic> valid() => {
      for (final key in scenarioMetrics) key: 10,
      'raw_frames': [1],
    };

    test('validateSample', () {
      expect(() => validateSample(valid()), returnsNormally);
      expect(
        () => validateSample(valid()..remove('jank_percent')),
        throwsA(
          isA<InvalidSampleException>().having(
            (e) => e.message,
            'message',
            'missing/invalid jank_percent',
          ),
        ),
      );
      expect(
        () => validateSample(valid()..['raw_frames'] = []),
        throwsA(isA<InvalidSampleException>()),
      );
    });

    test('networkFailures is the single accessor', () {
      expect(networkFailures(null), isEmpty);
      expect(networkFailures({'network': 'x'}), isEmpty);
      expect(networkFailures(_sample([_failure('backend')])), hasLength(1));
      expect(
        failureOwners(_sample([_failure('backend'), _failure('network')])),
        {'backend', 'network'},
      );
    });
  });

  group('retry decision', () {
    const policy = RetryPolicy(2, Duration.zero);

    test('all retryable owners are discarded', () {
      final decision = decideRetry(
        _sample([_failure('network'), _failure('backend')]),
        discardedCount: 0,
        policy: policy,
      );
      expect(decision.discard, isTrue);
      expect(decision.discardedRun(4), {
        'attempt': 4,
        'owners': ['network', 'backend'],
        'failures': [_failure('network'), _failure('backend')],
      });
    });

    test('any mobile or environment failure is kept', () {
      for (final owner in ['mobile', 'environment']) {
        final decision = decideRetry(
          _sample([_failure('network'), _failure(owner)]),
          discardedCount: 0,
          policy: policy,
        );
        expect(decision.discard, isFalse, reason: owner);
      }
    });

    test('no failures or exhausted budget is kept', () {
      expect(
        decideRetry(_sample([]), discardedCount: 0, policy: policy).discard,
        isFalse,
      );
      expect(
        decideRetry(
          _sample([_failure('backend')]),
          discardedCount: 2,
          policy: policy,
        ).discard,
        isFalse,
      );
    });
  });

  group('triage and pending', () {
    test('groups discarded and last-run failures by owner', () {
      final result = triage(_sample([_failure('mobile', retry: 'never')]), [
        {
          'failures': [_failure('backend'), _failure('backend')],
        },
      ]);
      expect(result['total'], 3);
      expect((result['backend'] as Map)['count'], 2);
      expect((result['mobile'] as Map)['retry'], 'never');
      expect(((result['backend'] as Map)['examples'] as List).first, {
        'endpoint': '/orders',
        'status': 503,
        'error': null,
        'reason': 'unavailable',
        'at': null,
      });
      expect(triage(null, const []), {'total': 0});
    });

    test('pending entry action depends on the owners', () {
      final queuedAt = DateTime.utc(2026, 1, 2);
      final later = pendingEntry(
        id: 'orders',
        reason: 'only 2/5 valid runs',
        triage: triage(null, [
          {
            'failures': [_failure('backend')],
          },
        ]),
        deviceId: 'R5',
        queuedAt: queuedAt,
      );
      expect(later, {
        'id': 'orders',
        'queued_at': '2026-01-02T00:00:00.000Z',
        'reason': 'only 2/5 valid runs',
        'owners': ['backend'],
        'action': 'Re-run later: dart run tool/perf.dart --scenario=orders',
        'device_id': 'R5',
      });
      final fix = pendingEntry(
        id: 'orders',
        reason: 'x',
        triage: triage(_sample([_failure('mobile', retry: 'never')]), []),
        deviceId: 'R5',
        queuedAt: queuedAt,
      );
      expect(
        fix['action'],
        'Fix the cause first; a re-run will fail the same way.',
      );
      expect(
        withoutPending([
          {'id': 'orders'},
          {'id': 'home'},
        ], 'orders'),
        [
          {'id': 'home'},
        ],
      );
    });
  });

  group('baselines and summaries', () {
    const env = {'device_id': 'R5', 'flavor': 'dev', 'flutter_version': '3.1'};

    test('sameEnvironment', () {
      final baseline = {'scenario': 'orders', 'environment': env};
      expect(sameEnvironment(baseline, 'orders', env), isTrue);
      expect(sameEnvironment(baseline, 'home', env), isFalse);
      expect(
        sameEnvironment(baseline, 'orders', {...env, 'flutter_version': '3.2'}),
        isFalse,
      );
      expect(sameEnvironment({'scenario': 'orders'}, 'orders', env), isFalse);
    });

    test('median', () {
      expect(median([3, 1, 2]), 2);
      expect(median([4, 1, 3, 2]), 2.5);
    });

    test('summarizeScenario includes optional and data_* medians', () {
      Map<String, dynamic> run(num v, {bool heap = true}) => {
        for (final key in scenarioMetrics) key: v,
        if (heap) 'heap_growth_mb': v,
        'network_p95_ms': v,
        'data_items': v * 10,
        'data_label': 'x',
      };
      final summary = summarizeScenario([run(1), run(3, heap: false), run(2)]);
      expect(summary.keys, [
        ...scenarioMetrics,
        'network_p95_ms',
        'data_items',
      ]);
      expect(summary['frame_p95_ms'], 2);
      expect(summary['data_items'], 20);
      expect(summarize([run(1), run(5)], const ['scenario_ms']), {
        'scenario_ms': 3.0,
      });
    });
  });

  test('resultEntry keeps the summary.json keys', () {
    final entry = resultEntry(
      id: 'orders',
      kind: 'scenario',
      body: {'status': 'PASS', 'raw_results': [], 'log': 'a.log'},
      reportPath: 'r.json',
    );
    expect(entry.keys, [
      'id',
      'kind',
      'description',
      'routes',
      'status',
      'rating',
      'ratings',
      'targets',
      'source',
      'failures',
      'request_failures',
      'summary',
      'comparison',
      'diagnosis',
      'network',
      'report',
      'log',
    ]);
    expect(entry['status'], 'PASS');
    expect(entry['report'], 'r.json');
    expect(entry['log'], 'a.log');
  });

  group('mask', () {
    test('replaces secrets and ignores values shorter than 3', () {
      expect(
        mask('user alice pw s3cret', ['alice', 's3cret']),
        'user *** pw ***',
      );
      expect(mask('a 12 b', ['12', '']), 'a 12 b');
    });

    test('masks nested JSON, including escaped secrets', () {
      const secret = 'p"w\\d';
      final text = encodeMasked(
        {
          'log': {
            'lines': ['login $secret ok'],
            secret: 1,
          },
        },
        [secret],
      );
      expect(text, isNot(contains('p\\"w')));
      expect(jsonDecode(text), {
        'log': {
          'lines': ['login *** ok'],
          '***': 1,
        },
      });
      expect(
        mask(jsonEncode({'cmd': 'run $secret'}), [secret]),
        '{"cmd":"run ***"}',
      );
    });
  });
}
