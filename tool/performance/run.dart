import 'dart:convert';
import 'dart:io';

import 'gate.dart';
import 'rating.dart';

const _usage = '''
Usage: dart run tool/perf.dart [options]

  --scenario=<id>[,<id>]  Run only these scenario ids (and skip startup
                          unless "startup" is listed).
  --diagnose              Also run one instrumented pass per scenario and
                          report the slowest widgets, even when it passes.
  --approve-baseline      Measure again and store baselines when every
                          target passes. Never run this automatically.
  --help                  Show this message.
''';

const _scenarioMetrics = <String>[
  'frame_p50_ms',
  'frame_p95_ms',
  'frame_p99_ms',
  'jank_percent',
  'frame_count',
  'build_p95_ms',
  'raster_p95_ms',
  'scenario_ms',
];

/// Reported when every measured run returns them; never gated by default.
const _optionalMetrics = <String>[
  'heap_growth_mb',
  'heap_end_mb',
  'network_request_count',
  'network_failed_count',
  'network_p95_ms',
  'network_response_kb',
  'network_failed_mobile',
  'network_failed_backend',
  'network_failed_network',
  'network_failed_environment',
];

/// Owners whose failures are temporary and worth an automatic re-run.
const _retryableOwners = <String>{'network', 'backend'};

/// Environment variables forwarded to scenarios as `--dart-define`. Values
/// are secrets and are masked in every log and report.
const _secretDefines = <String>['PERF_USERNAME', 'PERF_PASSWORD'];

/// Gated scenario metric -> hard-limit key in `thresholds`.
const _scenarioLimits = <String, String>{
  'jank_percent': 'max_jank_percent',
  'frame_p95_ms': 'max_frame_p95_ms',
  'frame_p99_ms': 'max_frame_p99_ms',
  'scenario_ms': 'max_scenario_ms',
};

const _startupMetrics = <String>[
  'startup_first_frame_ms',
  'startup_framework_init_ms',
];

class _Options {
  _Options(this.approve, this.diagnose, this.only);
  final bool approve;
  final bool diagnose;
  final Set<String>? only;
}

_Options? _parse(List<String> args) {
  var approve = false;
  var diagnose = false;
  Set<String>? only;
  for (final arg in args) {
    if (arg == '--approve-baseline') {
      approve = true;
    } else if (arg == '--diagnose') {
      diagnose = true;
    } else if (arg.startsWith('--scenario=')) {
      only = arg
          .substring('--scenario='.length)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (only.isEmpty) return null;
    } else {
      return null;
    }
  }
  return _Options(approve, diagnose, only);
}

Future<void> run(List<String> args) async {
  final options = _parse(args);
  if (options == null || args.contains('--help')) {
    (options == null ? stderr : stdout).write(_usage);
    exitCode = options == null ? 2 : 0;
    return;
  }
  try {
    if (!File('pubspec.yaml').existsSync()) {
      throw StateError('Run the benchmark from the project root.');
    }
    final config = _json(File('tool/performance/config.json'));
    // Validate the whole config before any slow device work starts.
    final runs = _count(config, 'runs');
    final warmups = _count(config, 'warmup_runs', zero: true);
    final flavor = _required(config, 'flavor');
    final diagnoseOnFailure = config['diagnose_on_failure'] == true;
    final gate = _scenarioGate(config);
    final bands = _bands(config);
    final budgets = _budgets(config);
    final retry = _retryPolicy(config);
    final pendingPath = _required(config, 'pending_file');
    final startup = _startup(config);
    final reportRoot = _required(config, 'report_directory');
    final latestRoot = _required(config, 'latest_directory');
    final historyPath = _required(config, 'history_file');
    final baselineRoot = _required(config, 'baseline_directory');
    final all = _scenarios(_required(config, 'scenario_directory'));
    final uncovered = _uncoveredRoutes(_required(config, 'routes_file'), all);
    final only = options.only;
    final known = {...all.map((s) => s.id), 'startup'};
    final unknown = only?.difference(known) ?? const <String>{};
    if (unknown.isNotEmpty) {
      throw FormatException('Unknown scenario: ${unknown.join(', ')}');
    }
    final scenarios = all
        .where((s) => only == null ? s.enabled : only.contains(s.id))
        .toList();
    final runStartup =
        startup != null && (only == null || only.contains('startup'));
    stdout.writeln(
      'Routes without enabled scenarios: '
      '${uncovered.isEmpty ? 'none' : uncovered.join(', ')}',
    );
    if (scenarios.isEmpty && !runStartup) {
      throw const FormatException(
        'Nothing to measure. Enable startup in tool/performance/config.json '
        'or add a scenario under integration_test/performance/scenarios.',
      );
    }

    final flutter = await _flutter();
    final environment = await _environment(flutter, flavor);
    final device = environment['device_id'] as String;
    final platform = environment['platform'] as String;
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final results = <Map<String, dynamic>>[];
    final pendingBaselines = <File, Map<String, dynamic>>{};

    Future<void> record(
      String id,
      String kind,
      Map<String, dynamic> body,
    ) async {
      final reportDir = Directory('$reportRoot/$id')
        ..createSync(recursive: true);
      final report = <String, dynamic>{
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'target': id,
        'kind': kind,
        'environment': environment,
        ...body,
      };
      final reportFile = File('${reportDir.path}/$stamp.json')
        ..writeAsStringSync(_pretty(report));
      File('${reportDir.path}/$stamp.md').writeAsStringSync(_markdown(report));
      final summary = body['summary'];
      File(historyPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '${jsonEncode({'timestamp': report['timestamp'], 'target': id, 'device_id': device, 'flavor': flavor, if (summary is Map) ...summary, 'status': body['status']})}\n',
          mode: FileMode.append,
        );
      results.add({
        'id': id,
        'kind': kind,
        'description': body['description'],
        'routes': body['routes'],
        'status': body['status'],
        'rating': body['rating'],
        'ratings': body['ratings'],
        'targets': body['targets'],
        'source': body['source'],
        'failures': body['failures'],
        'request_failures': body['request_failures'],
        'summary': body['summary'],
        'comparison': body['comparison'],
        'diagnosis': body['diagnosis'],
        'network': body['network'],
        'report': reportFile.path,
        'log': body['log'],
      });
      _printTarget(id, body);
    }

    Map<String, dynamic>? baselineFor(String id) {
      final file = File('$baselineRoot/$id/${_safe(device)}.json');
      if (!file.existsSync()) return null;
      final baseline = _json(file);
      if (_sameEnvironment(baseline, id, environment)) {
        return baseline['summary'] as Map<String, dynamic>?;
      }
      if (!options.approve) {
        throw FormatException(
          '$id: baseline scenario/device/flavor/Flutter differs; use the same '
          'environment or approve a new baseline.',
        );
      }
      stdout.writeln(
        '$id: existing baseline is from another environment; not compared.',
      );
      return null;
    }

    void stage(String id, Map<String, double> summary) {
      if (!options.approve) return;
      pendingBaselines[File('$baselineRoot/$id/${_safe(device)}.json')] = {
        'approved_at_utc': DateTime.now().toUtc().toIso8601String(),
        'scenario': id,
        'environment': environment,
        'summary': summary,
      };
    }

    if (runStartup) {
      final log = _Log('$reportRoot/startup/$stamp.log');
      try {
        final samples = await _measureStartup(
          flutter,
          platform,
          flavor,
          device,
          startup,
          log,
        );
        final summary = _summarize(samples, _startupMetrics);
        final result = evaluate(summary, baselineFor('startup'), startup.gate);
        final ratings = rateMetrics(summary, bands: startup.bands);
        if (result.passed) stage('startup', summary);
        await record('startup', 'startup', {
          'description':
              'Cold start of ${startup.target} until the first frame is '
              'rasterized (flutter run --trace-startup)',
          'routes': const ['/'],
          'runs': samples.length,
          'raw_results': samples,
          'summary': summary,
          'comparison': result.comparison,
          'status': result.passed ? 'PASS' : 'FAIL',
          'rating': overallRating(ratings.values).label,
          'ratings': {for (final r in ratings.entries) r.key: r.value.toJson()},
          'failures': result.failures,
          'log': log.path,
        });
      } on _TargetError catch (error) {
        await record('startup', 'startup', _errorBody(error, log));
      }
    }

    for (final scenario in scenarios) {
      final log = _Log('$reportRoot/${scenario.id}/$stamp.log');
      try {
        final binary = await _prebuild(
          flutter,
          platform,
          flavor,
          scenario.test,
          log,
        );
        final measured = <Map<String, dynamic>>[];
        final discarded = <Map<String, dynamic>>[];
        var attempts = 0;
        var warmupsDone = 0;
        final maxAttempts = runs + warmups + retry.maxExtraRuns;
        while (measured.length < runs && attempts < maxAttempts) {
          final warmup = warmupsDone < warmups;
          attempts++;
          if (warmup) warmupsDone++;
          stdout.writeln(
            '${scenario.id}: ${warmup ? 'warmup' : 'run'} attempt $attempts',
          );
          final output = await _drive(
            flutter,
            flavor,
            device,
            scenario.test,
            log,
            binary: binary,
          );
          final sample = _marker('PERF_RESULT', output);
          if (sample == null) {
            throw _TargetError('no metrics returned');
          }
          _validate(sample);
          if (warmup) continue;
          final owners = _failureOwners(sample);
          if (owners.isNotEmpty &&
              owners.every(_retryableOwners.contains) &&
              discarded.length < retry.maxExtraRuns) {
            // A temporary network/backend failure means the app showed an
            // error state, not the real screen. Discard and measure again.
            discarded.add({
              'attempt': attempts,
              'owners': owners.toList(),
              'failures': (sample['network'] as Map?)?['failures'],
            });
            stdout.writeln(
              '${scenario.id}: discarded run, ${owners.join('/')} failure',
            );
            await Future<void>.delayed(retry.delay);
            continue;
          }
          measured.add(sample);
        }
        if (measured.length < runs) {
          throw _TargetError(
            'only ${measured.length}/$runs valid runs after '
            '${discarded.length} network/backend failures',
            failures: discarded,
          );
        }
        final metrics = [
          ..._scenarioMetrics,
          for (final key in _optionalMetrics)
            if (measured.every((r) => r[key] is num)) key,
        ];
        final summary = _summarize(measured, metrics);
        for (final key in measured.first.keys) {
          if (key.startsWith('data_') && measured.every((r) => r[key] is num)) {
            summary[key] = _median(
              measured.map((r) => (r[key] as num).toDouble()).toList(),
            );
          }
        }
        final result = evaluate(summary, baselineFor(scenario.id), gate);
        // Scenario targets override global bands; global data budgets
        // remain a fallback for scenarios without their own.
        final targets = scenario.targets;
        final ratings = rateMetrics(
          summary,
          bands: {...bands, ...?targets?.bands},
          budgets: {...?budgets[scenario.id], ...?targets?.budgets},
        );
        final triage = _triage(measured.last, discarded);
        Map<String, dynamic>? diagnosis;
        if (options.diagnose || (!result.passed && diagnoseOnFailure)) {
          stdout.writeln('${scenario.id}: instrumented diagnosis run');
          final output = await _drive(
            flutter,
            flavor,
            device,
            scenario.test,
            log,
            defines: const ['PERF_DIAGNOSE=true'],
          );
          diagnosis = _marker('PERF_DIAGNOSIS', output);
        }
        if (result.passed) stage(scenario.id, summary);
        final network = measured.last['network'];
        await record(scenario.id, 'scenario', {
          'description': scenario.description,
          'routes': scenario.routes,
          'uncovered_routes': uncovered,
          'config': config,
          'runs': measured.length,
          'raw_results': measured,
          'summary': summary,
          'comparison': result.comparison,
          'status': result.passed ? 'PASS' : 'FAIL',
          'rating': overallRating(ratings.values).label,
          'ratings': {for (final r in ratings.entries) r.key: r.value.toJson()},
          if (targets != null) 'targets': targets.toJson(),
          'source': ?scenario.source,
          'failures': result.failures,
          'request_failures': triage,
          'discarded_runs': discarded,
          'diagnosis': diagnosis,
          if (network is Map) 'network': network,
          'log': log.path,
        });
      } on _TargetError catch (error) {
        final triage = _triage(null, error.failures);
        await record(scenario.id, 'scenario', {
          ..._errorBody(error, log),
          'description': scenario.description,
          'routes': scenario.routes,
          'request_failures': triage,
          'discarded_runs': error.failures,
        });
        _queue(pendingPath, scenario.id, error.message, triage, environment);
      }
    }

    for (final r in results) {
      if (r['status'] != 'ERROR') _unqueue(pendingPath, r['id'] as String);
    }
    final statuses = results.map((r) => r['status']).toSet();
    final overall = statuses.contains('ERROR')
        ? 'ERROR'
        : statuses.contains('FAIL')
        ? 'FAIL'
        : 'PASS';
    final approved = <String>[];
    if (options.approve && overall == 'PASS') {
      for (final entry in pendingBaselines.entries) {
        entry.key.parent.createSync(recursive: true);
        entry.key.writeAsStringSync(_pretty(entry.value));
        approved.add(entry.key.path);
        stdout.writeln('Baseline approved: ${entry.key.path}');
      }
    } else if (options.approve) {
      stdout.writeln('Baselines unchanged because a target did not pass.');
    }
    final latest = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'status': overall,
      'command': _mask(['dart', 'run', 'tool/perf.dart', ...args].join(' ')),
      'environment': environment,
      'targets': results,
      'uncovered_routes': uncovered,
      'pending_reruns': _readPending(pendingPath),
      'baselines_approved': approved,
    };
    final latestDir = Directory(latestRoot)..createSync(recursive: true);
    File('${latestDir.path}/summary.json').writeAsStringSync(_pretty(latest));
    File(
      '${latestDir.path}/summary.md',
    ).writeAsStringSync(_latestMarkdown(latest));
    stdout.writeln('PERFORMANCE: $overall');
    stdout.writeln('Summary: ${latestDir.path}/summary.json');
    exitCode = switch (overall) {
      'PASS' => 0,
      'FAIL' => 1,
      _ => 3,
    };
  } catch (error) {
    stderr.writeln('Performance tooling error: $error');
    exitCode = 2;
  }
}

// ---------------------------------------------------------------------------
// Device work

class _TargetError implements Exception {
  _TargetError(this.message, {this.failures = const []});
  final String message;
  final List<Map<String, dynamic>> failures;
  @override
  String toString() => message;
}

class _Log {
  _Log(this.path) {
    File(path).parent.createSync(recursive: true);
    File(path).writeAsStringSync('');
  }
  final String path;
  void add(List<String> command, ProcessResult result) {
    File(path).writeAsStringSync(
      _mask(
        '\$ ${command.join(' ')}\n${result.stdout}\n${result.stderr}\n'
        'exit ${result.exitCode}\n\n',
      ),
      mode: FileMode.append,
    );
  }

  /// Last lines, so an agent sees the actual failure without the full log.
  String tail([int lines = 40]) {
    final all = File(path).readAsLinesSync();
    return all.skip(all.length > lines ? all.length - lines : 0).join('\n');
  }
}

Map<String, dynamic> _errorBody(_TargetError error, _Log log) => {
  'status': 'ERROR',
  'failures': ['$error'],
  'log': log.path,
  'log_tail': log.tail(),
};

Future<Map<String, dynamic>> _environment(
  List<String> flutter,
  String flavor,
) async {
  final version = await _process(flutter, ['--version', '--machine']);
  final devices = await _process(flutter, ['devices', '--machine']);
  if (version.exitCode != 0 || devices.exitCode != 0) {
    throw StateError('Unable to read Flutter version/devices.');
  }
  final available = (jsonDecode(devices.stdout as String) as List)
      .whereType<Map<String, dynamic>>()
      .where((d) => d['isSupported'] != false && _platformOf(d) != null)
      .toList();
  final requested = Platform.environment['FLUTTER_PERF_DEVICE'];
  if (requested == null && available.length != 1) {
    throw StateError(
      available.isEmpty
          ? 'No Android/iOS device connected. Plug in a real device.'
          : 'Select a device with FLUTTER_PERF_DEVICE '
                '(${available.map((d) => d['id']).join(', ')}).',
    );
  }
  final device = requested ?? available.single['id'] as String;
  final match = available.where((d) => d['id'] == device).toList();
  if (match.length != 1) throw StateError('Unsupported device: $device');
  final info = jsonDecode(version.stdout as String) as Map;
  return {
    'device_id': device,
    'device_name': match.single['name'],
    'platform': _platformOf(match.single),
    'emulator': match.single['emulator'],
    'flavor': flavor,
    'flutter_version': info['frameworkVersion'],
    'dart_version': Platform.version,
    'build_mode': 'profile',
    'cpu': 'unsupported',
  };
}

/// Builds the profile APK once so every run reuses the same binary. iOS needs
/// a signed IPA for reuse, so iOS keeps building inside each command.
Future<String?> _prebuild(
  List<String> flutter,
  String platform,
  String flavor,
  String target,
  _Log log,
) async {
  if (platform != 'android') return null;
  stdout.writeln('building profile APK for $target');
  final args = [
    'build',
    'apk',
    '--profile',
    '--flavor',
    flavor,
    '--target=$target',
  ];
  final result = await _process(flutter, args);
  log.add([...flutter, ...args], result);
  if (result.exitCode != 0) throw _TargetError('profile build failed');
  final apk = File('build/app/outputs/flutter-apk/app-$flavor-profile.apk');
  if (!apk.existsSync()) throw _TargetError('missing ${apk.path}');
  return apk.path;
}

Future<String> _drive(
  List<String> flutter,
  String flavor,
  String device,
  String target,
  _Log log, {
  String? binary,
  List<String> defines = const [],
}) async {
  final args = [
    'drive',
    '--profile',
    '--flavor',
    flavor,
    '-d',
    device,
    // The scenario opens its own VM service client for heap usage.
    '--no-dds',
    '--driver=test_driver/perf_driver.dart',
    '--target=$target',
    for (final define in defines) '--dart-define=$define',
    for (final name in _secretDefines)
      if (Platform.environment[name]?.isNotEmpty ?? false)
        '--dart-define=$name=${Platform.environment[name]}',
    if (binary != null) '--use-application-binary=$binary',
  ];
  final result = await _process(flutter, args);
  log.add([...flutter, ...args], result);
  if (result.exitCode != 0) {
    throw _TargetError('flutter drive failed (${result.exitCode})');
  }
  return '${result.stdout}\n${result.stderr}';
}

class _Startup {
  _Startup(this.target, this.runs, this.gate, this.bands);
  final String target;
  final int runs;
  final GateConfig gate;
  final Map<String, Band> bands;
}

Future<List<Map<String, dynamic>>> _measureStartup(
  List<String> flutter,
  String platform,
  String flavor,
  String device,
  _Startup startup,
  _Log log,
) async {
  final binary = await _prebuild(
    flutter,
    platform,
    flavor,
    startup.target,
    log,
  );
  final samples = <Map<String, dynamic>>[];
  for (var i = 0; i < startup.runs; i++) {
    stdout.writeln('startup: run ${i + 1}');
    final out = Directory.systemTemp.createTempSync('perf_startup_');
    try {
      final args = [
        'run',
        '--profile',
        '--flavor',
        flavor,
        '-d',
        device,
        '--target=${startup.target}',
        '--trace-startup',
        if (binary != null) '--use-application-binary=$binary',
      ];
      final result = await _process(
        flutter,
        args,
        environment: {'FLUTTER_TEST_OUTPUTS_DIR': out.path},
      );
      log.add([...flutter, ...args], result);
      final info = File('${out.path}/start_up_info.json');
      if (result.exitCode != 0 || !info.existsSync()) {
        throw _TargetError('startup trace failed (${result.exitCode})');
      }
      final data = _json(info);
      final firstFrame =
          data['timeToFirstFrameRasterizedMicros'] ??
          data['timeToFirstFrameMicros'];
      final frameworkInit = data['timeToFrameworkInitMicros'];
      if (firstFrame is! num || frameworkInit is! num) {
        throw _TargetError('start_up_info.json has no first-frame timing');
      }
      samples.add({
        'startup_first_frame_ms': firstFrame / 1000,
        'startup_framework_init_ms': frameworkInit / 1000,
        'raw': data,
      });
    } finally {
      out.deleteSync(recursive: true);
    }
  }
  return samples;
}

// ---------------------------------------------------------------------------
// Config

class _Scenario {
  const _Scenario(
    this.id,
    this.description,
    this.routes,
    this.test,
    this.enabled, {
    this.source,
    this.targets,
  });
  final String id;
  final String description;
  final List<String> routes;
  final String test;
  final bool enabled;

  /// Where the flow came from, such as an acceptance criterion.
  final Map<String, dynamic>? source;

  /// Scenario-specific rating targets derived from the requirement.
  final _Targets? targets;
}

/// Per-scenario bands and data budgets. `proposed` targets were inferred by
/// an agent and still need PM approval; they rate runs but are labelled.
class _Targets {
  const _Targets(this.status, this.rationale, this.bands, this.budgets);
  final String status;
  final String rationale;
  final Map<String, Band> bands;
  final Map<String, DataBudget> budgets;

  Map<String, Object> toJson() => {'status': status, 'rationale': rationale};
}

_Targets? _targetsFrom(Object? raw, String file) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    throw FormatException('$file: targets must be an object');
  }
  final status = raw['status'];
  if (status != 'proposed' && status != 'approved') {
    throw FormatException('$file: targets.status must be proposed or approved');
  }
  final rationale = raw['rationale'];
  if (rationale is! String || rationale.isEmpty) {
    throw FormatException('$file: targets.rationale is required');
  }
  final bands = raw['bands'] ?? const <String, dynamic>{};
  final budgets = raw['data_budgets'] ?? const <String, dynamic>{};
  if (bands is! Map<String, dynamic> || budgets is! Map<String, dynamic>) {
    throw FormatException('$file: targets.bands and data_budgets are objects');
  }
  return _Targets(
    status as String,
    rationale,
    {for (final e in bands.entries) e.key: Band.fromJson(e.key, e.value)},
    {
      for (final e in budgets.entries)
        e.key: DataBudget.fromJson(e.key, e.value as Map<String, dynamic>),
    },
  );
}

List<_Scenario> _scenarios(String path) {
  final folder = Directory(path);
  if (!folder.existsSync()) {
    throw FormatException('Missing scenario directory: $path');
  }
  final files =
      folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final ids = <String>{'startup'};
  final result = <_Scenario>[];
  for (final file in files) {
    final value = _json(file);
    final id = _required(value, 'id');
    final test = _required(value, 'test');
    final routes = value['routes'];
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id) ||
        !ids.add(id) ||
        routes is! List ||
        routes.any((r) => r is! String) ||
        value['enabled'] is! bool ||
        !File(test).existsSync()) {
      throw FormatException('Invalid scenario descriptor: ${file.path}');
    }
    final source = value['source'];
    if (source != null && source is! Map<String, dynamic>) {
      throw FormatException('${file.path}: source must be an object');
    }
    result.add(
      _Scenario(
        id,
        _required(value, 'description'),
        routes.cast<String>(),
        test,
        value['enabled'] as bool,
        source: source as Map<String, dynamic>?,
        targets: _targetsFrom(value['targets'], file.path),
      ),
    );
  }
  return result;
}

List<String> _uncoveredRoutes(String path, List<_Scenario> scenarios) {
  final source = File(path).readAsStringSync();
  final constants = <String, String>{};
  for (final m in RegExp(
    r"static const String\s+(\w+)\s*=\s*'([^']+)'\s*;",
  ).allMatches(source)) {
    constants[m.group(1)!] = m.group(2)!;
  }
  final routes = <String>{};
  for (final m in RegExp(r'SLIPage\(name:\s*(\w+)').allMatches(source)) {
    final route = constants[m.group(1)];
    if (route != null) routes.add(route);
  }
  final covered = scenarios
      .where((s) => s.enabled)
      .expand((s) => s.routes)
      .toSet();
  return routes.difference(covered).toList()..sort();
}

GateConfig _scenarioGate(Map<String, dynamic> config) {
  final raw = config['thresholds'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('thresholds is required');
  }
  final zero = raw['zero_baseline_regression_delta'];
  if (zero is! Map<String, dynamic>) {
    throw const FormatException(
      'thresholds.zero_baseline_regression_delta is required',
    );
  }
  return GateConfig(
    limits: {
      for (final entry in _scenarioLimits.entries)
        entry.key: _number(raw, entry.value, 'thresholds.${entry.value}'),
    },
    maxRegressionPercent: _number(
      raw,
      'max_regression_percent',
      'thresholds.max_regression_percent',
    ),
    zeroBaselineDelta: {
      for (final key in _scenarioLimits.keys)
        key: _number(
          zero,
          key,
          'thresholds.zero_baseline_regression_delta.$key',
        ),
    },
    minFrameCount: _number(
      raw,
      'min_frame_count',
      'thresholds.min_frame_count',
    ),
    optionalLimits: {
      'network_failed_count': _number(
        raw,
        'max_network_failures',
        'thresholds.max_network_failures',
      ),
    },
  );
}

_Startup? _startup(Map<String, dynamic> config) {
  final raw = config['startup'];
  if (raw == null) return null;
  if (raw is! Map<String, dynamic> || raw['enabled'] is! bool) {
    throw const FormatException('startup.enabled must be a bool');
  }
  if (raw['enabled'] != true) return null;
  final target = _required(raw, 'target');
  if (!File(target).existsSync()) {
    throw FormatException('startup.target does not exist: $target');
  }
  final thresholds = config['thresholds'] as Map<String, dynamic>;
  return _Startup(
    target,
    _count(raw, 'runs'),
    GateConfig(
      limits: {
        'startup_first_frame_ms': _number(
          raw,
          'max_first_frame_ms',
          'startup.max_first_frame_ms',
        ),
      },
      maxRegressionPercent: _number(
        thresholds,
        'max_regression_percent',
        'thresholds.max_regression_percent',
      ),
    ),
    {
      for (final e
          in ((raw['bands'] as Map<String, dynamic>?) ?? const {}).entries)
        e.key: Band.fromJson(e.key, e.value),
    },
  );
}

class _RetryPolicy {
  const _RetryPolicy(this.maxExtraRuns, this.delay);
  final int maxExtraRuns;
  final Duration delay;
}

_RetryPolicy _retryPolicy(Map<String, dynamic> config) {
  final raw = config['retry'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('retry is required');
  }
  return _RetryPolicy(
    _count(raw, 'max_extra_runs', zero: true),
    Duration(seconds: _count(raw, 'delay_seconds', zero: true)),
  );
}

Map<String, Band> _bands(Map<String, dynamic> config) {
  final raw = config['bands'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('bands is required');
  }
  return {for (final e in raw.entries) e.key: Band.fromJson(e.key, e.value)};
}

/// Scenario id -> metric -> budget.
Map<String, Map<String, DataBudget>> _budgets(Map<String, dynamic> config) {
  final raw = config['data_budgets'] ?? const <String, dynamic>{};
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('data_budgets must be an object');
  }
  return {
    for (final scenario in raw.entries)
      scenario.key: {
        for (final metric in (scenario.value as Map<String, dynamic>).entries)
          metric.key: DataBudget.fromJson(
            metric.key,
            metric.value as Map<String, dynamic>,
          ),
      },
  };
}

Set<String> _failureOwners(Map<String, dynamic> sample) {
  final failures = (sample['network'] as Map?)?['failures'];
  if (failures is! List) return const {};
  return {for (final f in failures) '${(f as Map)['owner']}'};
}

/// Groups failed requests by owner so the report says who has to act.
Map<String, dynamic> _triage(
  Map<String, dynamic>? lastSample,
  List<Map<String, dynamic>> discarded,
) {
  final all = <Map>[
    for (final d in discarded)
      for (final f in (d['failures'] as List? ?? const [])) f as Map,
    if (lastSample != null)
      for (final f
          in ((lastSample['network'] as Map?)?['failures'] as List? ??
              const []))
        f as Map,
  ];
  final byOwner = <String, List<Map>>{};
  for (final f in all) {
    (byOwner['${f['owner']}'] ??= []).add(f);
  }
  return {
    'total': all.length,
    for (final e in byOwner.entries)
      e.key: {
        'count': e.value.length,
        'retry': e.value.first['retry'],
        'examples': [
          for (final f in e.value.take(5))
            {
              'endpoint': f['endpoint'],
              'status': f['status'],
              'error': f['error'],
              'reason': f['reason'],
              'at': f['at'],
            },
        ],
      },
  };
}

List<dynamic> _readPending(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];
  final value = jsonDecode(file.readAsStringSync());
  return value is List ? value : const [];
}

/// Records a target that could not be measured so it is re-run later.
void _queue(
  String path,
  String id,
  String reason,
  Map<String, dynamic> triage,
  Map<String, dynamic> environment,
) {
  final pending = _readPending(path).where((p) => (p as Map)['id'] != id);
  final retryLater = triage.entries
      .where((e) => e.value is Map)
      .every((e) => (e.value as Map)['retry'] != 'never');
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      _pretty([
        ...pending,
        {
          'id': id,
          'queued_at': DateTime.now().toUtc().toIso8601String(),
          'reason': reason,
          'owners': [
            for (final e in triage.entries)
              if (e.value is Map) e.key,
          ],
          'action': retryLater
              ? 'Re-run later: dart run tool/perf.dart --scenario=$id'
              : 'Fix the cause first; a re-run will fail the same way.',
          'device_id': environment['device_id'],
        },
      ]),
    );
}

void _unqueue(String path, String id) {
  final file = File(path);
  if (!file.existsSync()) return;
  final rest = _readPending(path).where((p) => (p as Map)['id'] != id).toList();
  file.writeAsStringSync(_pretty(rest));
}

Map<String, dynamic> _json(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

String _required(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key is required');
  }
  return value;
}

int _count(Map<String, dynamic> map, String key, {bool zero = false}) {
  final value = map[key];
  if (value is! int || value < (zero ? 0 : 1)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

num _number(Map<String, dynamic> map, String key, String label) {
  final value = map[key];
  if (value is! num || !value.isFinite || value < 0) {
    throw FormatException('Invalid $label');
  }
  return value;
}

// ---------------------------------------------------------------------------
// Helpers

/// Maps a `flutter devices --machine` entry to `android`/`ios`, or null.
String? _platformOf(Map<String, dynamic> device) {
  final target = '${device['targetPlatform'] ?? device['platformType'] ?? ''}';
  if (target.startsWith('android')) return 'android';
  if (target == 'ios') return 'ios';
  return null;
}

bool _sameEnvironment(
  Map<String, dynamic> baseline,
  String id,
  Map<String, dynamic> environment,
) {
  final previous = baseline['environment'];
  return baseline['scenario'] == id &&
      previous is Map &&
      previous['device_id'] == environment['device_id'] &&
      previous['flavor'] == environment['flavor'] &&
      previous['flutter_version'] == environment['flutter_version'];
}

Map<String, double> _summarize(
  List<Map<String, dynamic>> samples,
  List<String> metrics,
) => {
  for (final key in metrics)
    key: _median(samples.map((r) => (r[key] as num).toDouble()).toList()),
};

String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

String _pretty(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);

String _fmt(Object? value) => value is num ? value.toStringAsFixed(2) : 'n/a';

/// Replaces secret values with `***` so they never reach logs or reports.
String _mask(String text) {
  var masked = text;
  for (final name in _secretDefines) {
    final value = Platform.environment[name];
    if (value != null && value.length >= 3) {
      masked = masked.replaceAll(value, '***');
    }
  }
  return masked;
}

/// Uses the same Flutter resolution as every derry task.
Future<List<String>> _flutter() async {
  if (!Platform.isWindows) return ['./scripts/flutterw.sh'];
  final fvm = await Process.run('where.exe', ['fvm']);
  return fvm.exitCode == 0 ? ['fvm', 'flutter'] : ['flutter.bat'];
}

Future<ProcessResult> _process(
  List<String> command,
  List<String> args, {
  Map<String, String>? environment,
}) => Process.run(
  command.first,
  [...command.skip(1), ...args],
  runInShell: Platform.isWindows,
  environment: environment,
);

Map<String, dynamic>? _marker(String name, String text) {
  final matches = RegExp('$name:(\\{[^\\r\\n]+\\})').allMatches(text);
  return matches.isEmpty
      ? null
      : jsonDecode(matches.last.group(1)!) as Map<String, dynamic>;
}

void _validate(Map<String, dynamic> sample) {
  for (final key in _scenarioMetrics) {
    final value = sample[key];
    if (value is! num || !value.isFinite || value < 0) {
      throw _TargetError('missing/invalid $key');
    }
  }
  if (sample['frame_count'] == 0 ||
      sample['raw_frames'] is! List ||
      (sample['raw_frames'] as List).isEmpty) {
    throw _TargetError('no frame samples');
  }
}

double _median(List<double> values) {
  values.sort();
  final m = values.length ~/ 2;
  return values.length.isOdd ? values[m] : (values[m - 1] + values[m]) / 2;
}

void _printTarget(String id, Map<String, dynamic> body) {
  stdout.writeln('PERFORMANCE $id: ${body['status']}');
  final summary = body['summary'];
  final comparison = body['comparison'];
  if (summary is Map) {
    for (final entry in summary.entries) {
      if (entry.key == 'frame_count') continue;
      final metric = comparison is Map ? comparison[entry.key] : null;
      final change = metric is Map ? metric['change_percent'] : null;
      stdout.writeln(
        '${entry.key}: ${_fmt(entry.value)}'
        '${change is num ? ' (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)' : ''}',
      );
    }
  }
  for (final failure in body['failures'] as List) {
    stdout.writeln('- $failure');
  }
}

String _markdown(Map<String, dynamic> report) {
  final summary = report['summary'];
  final comparison = report['comparison'];
  final rows = <String>[
    '| Metric | Current | Baseline | Change |',
    '|---|---:|---:|---:|',
  ];
  if (summary is Map) {
    for (final entry in summary.entries) {
      final c = comparison is Map ? comparison[entry.key] as Map? : null;
      final change = c?['change_percent'];
      rows.add(
        '| ${entry.key} | ${_fmt(entry.value)} | ${_fmt(c?['baseline'])} | '
        '${change is num ? '${change.toStringAsFixed(2)}%' : 'n/a'} |',
      );
    }
  }
  final buffer = StringBuffer()
    ..writeln('# ${report['target']}: ${report['status']}')
    ..writeln()
    ..writeln(rows.join('\n'))
    ..writeln()
    ..writeln('Failures: ${(report['failures'] as List).join('; ')}');
  final diagnosis = report['diagnosis'];
  if (diagnosis is Map) {
    buffer
      ..writeln()
      ..writeln(_hotspotTable(diagnosis));
  }
  final ratings = report['ratings'];
  if (ratings is Map && ratings.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(_ratingTable(report['rating'], ratings));
  }
  final targets = report['targets'];
  if (targets is Map) {
    buffer
      ..writeln()
      ..writeln(
        targets['status'] == 'proposed'
            ? 'Targets: PROPOSED, not yet approved by the PM. '
                  '${targets['rationale']}'
            : 'Targets: approved. ${targets['rationale']}',
      );
  }
  final triage = report['request_failures'];
  if (triage is Map && (triage['total'] ?? 0) > 0) {
    buffer
      ..writeln()
      ..writeln(_triageTable(triage));
  }
  final network = report['network'];
  if (network is Map) {
    buffer
      ..writeln()
      ..writeln(_networkTable(network));
  }
  final tail = report['log_tail'];
  if (tail is String) {
    buffer
      ..writeln()
      ..writeln('```text')
      ..writeln(tail)
      ..writeln('```');
  }
  return buffer.toString();
}

String _hotspotTable(Map<dynamic, dynamic> diagnosis) {
  final rows = <String>[
    '## Slowest widgets (instrumented run, compare relatively)',
    '',
    '| Widget / render object | Self ms | Total ms | Count |',
    '|---|---:|---:|---:|',
  ];
  for (final h in (diagnosis['hotspots'] as List? ?? const [])) {
    final m = h as Map;
    rows.add(
      '| ${m['name']} | ${_fmt(m['self_ms'])} | ${_fmt(m['total_ms'])} | '
      '${m['count']} |',
    );
  }
  return rows.join('\n');
}

String _ratingTable(Object? overall, Map<dynamic, dynamic> ratings) {
  final rows = <String>[
    '## Rating: $overall',
    '',
    '| Metric | Value | Good up to | Poor above | Data size | Rating |',
    '|---|---:|---:|---:|---:|---|',
  ];
  for (final e in ratings.entries) {
    final m = e.value as Map;
    rows.add(
      '| ${e.key} | ${_fmt(m['value'])} | ${_fmt(m['good'])} | '
      '${_fmt(m['poor'])} | ${m['items'] ?? ''} | ${m['rating']} |',
    );
  }
  return rows.join('\n');
}

String _triageTable(Map<dynamic, dynamic> triage) {
  final rows = <String>[
    '## Failed requests by owner',
    '',
    '| Owner | Count | Retry | Example |',
    '|---|---:|---|---|',
  ];
  for (final e in triage.entries) {
    if (e.value is! Map) continue;
    final m = e.value as Map;
    final example = (m['examples'] as List).first as Map;
    rows.add(
      '| ${e.key} | ${m['count']} | ${m['retry']} | '
      '${example['endpoint']} ${example['status'] ?? example['error'] ?? ''}: '
      '${example['reason']} |',
    );
  }
  return rows.join('\n');
}

String _networkTable(Map<dynamic, dynamic> network) {
  final rows = <String>[
    '## Network (last measured run, query strings removed)',
    '',
    'Requests ${network['request_count']}, failed ${network['failed_count']}, '
        'p95 ${_fmt(network['request_p95_ms'])} ms, '
        '${_fmt(network['response_kb'])} KB',
    '',
    '| Endpoint | Count | Worst ms | KB | Failures |',
    '|---|---:|---:|---:|---:|',
  ];
  for (final e in (network['endpoints'] as List? ?? const [])) {
    final m = e as Map;
    rows.add(
      '| ${m['endpoint']}${m['slow'] == true ? ' (slow)' : ''} | ${m['count']} | '
      '${_fmt(m['worst_ms'])} | ${_fmt(m['response_kb'])} | ${m['failures']} |',
    );
  }
  return rows.join('\n');
}

String _latestMarkdown(Map<String, dynamic> latest) {
  final env = latest['environment'] as Map;
  final buffer = StringBuffer()
    ..writeln('# Performance run: ${latest['status']}')
    ..writeln()
    ..writeln(
      '${env['device_name']} (${env['platform']}), flavor ${env['flavor']}, '
      'Flutter ${env['flutter_version']}, ${latest['timestamp']}',
    )
    ..writeln()
    ..writeln('| Target | Gate | Rating | Failures | Report |')
    ..writeln('|---|---|---|---|---|');
  for (final t in latest['targets'] as List) {
    final m = t as Map;
    final proposed = (m['targets'] as Map?)?['status'] == 'proposed';
    buffer.writeln(
      '| ${m['id']} | ${m['status']} | ${m['rating'] ?? 'n/a'}'
      '${proposed ? ' (proposed targets)' : ''} | '
      '${(m['failures'] as List).join('; ')} | ${m['report']} |',
    );
  }
  for (final t in latest['targets'] as List) {
    final m = t as Map;
    final diagnosis = m['diagnosis'];
    final network = m['network'];
    if (diagnosis is Map || network is Map) {
      buffer
        ..writeln()
        ..writeln('### ${m['id']}');
    }
    if (diagnosis is Map) buffer.writeln(_hotspotTable(diagnosis));
    if (network is Map) buffer.writeln(_networkTable(network));
  }
  final pending = latest['pending_reruns'] as List;
  if (pending.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Waiting for a re-run')
      ..writeln();
    for (final p in pending) {
      final m = p as Map;
      buffer.writeln(
        '- ${m['id']}: ${m['reason']} (owners: ${(m['owners'] as List).join(', ')}). '
        '${m['action']}',
      );
    }
  }
  final uncovered = latest['uncovered_routes'] as List;
  buffer
    ..writeln()
    ..writeln(
      'Routes without scenarios: '
      '${uncovered.isEmpty ? 'none' : uncovered.join(', ')}',
    );
  return buffer.toString();
}
