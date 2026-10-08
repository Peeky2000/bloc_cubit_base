import 'dart:convert';
import 'dart:io';

import 'gate.dart';
import 'policy.dart';
import 'rating.dart';
import 'report.dart';

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

/// Environment variables forwarded to scenarios as `--dart-define`. Values
/// are secrets and are masked in every log and report.
const _secretDefines = <String>['PERF_USERNAME', 'PERF_PASSWORD'];

/// Environment variables forwarded as `--dart-define` to every app launch.
/// They are configuration, not secrets, and are not masked.
const _publicDefines = <String>['API_BASE_URL'];

/// Current values of [_secretDefines].
List<String> get _secrets => [
  for (final name in _secretDefines) ?Platform.environment[name],
];

/// `--dart-define` flags for the set environment variables in [names].
List<String> _environmentDefines(List<String> names) => [
  for (final name in names)
    if (Platform.environment[name]?.isNotEmpty ?? false)
      '--dart-define=$name=${Platform.environment[name]}',
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
  if (args.contains('--help') || args.contains('-h')) {
    stdout.write(_usage);
    exitCode = 0;
    return;
  }
  final options = _parse(args);
  if (options == null) {
    stderr.write(_usage);
    exitCode = 2;
    return;
  }
  try {
    if (!File('pubspec.yaml').existsSync()) {
      throw StateError('Run the benchmark from the project root.');
    }
    final config = _json(File('tool/performance/config.json'));
    // Validate the whole config before any slow device work starts.
    bool exists(String path) => File(path).existsSync();
    final runs = requireCount(config, 'runs');
    final warmups = requireCount(config, 'warmup_runs', zero: true);
    final flavor = requireString(config, 'flavor');
    final diagnoseOnFailure = config['diagnose_on_failure'] == true;
    final gate = parseScenarioGate(config);
    final bands = parseBands(config);
    final budgets = parseBudgets(config);
    final retry = parseRetryPolicy(config);
    final pendingPath = requireString(config, 'pending_file');
    final startup = parseStartup(config, exists: exists);
    final reportRoot = requireString(config, 'report_directory');
    final latestRoot = requireString(config, 'latest_directory');
    final historyPath = requireString(config, 'history_file');
    final baselineRoot = requireString(config, 'baseline_directory');
    final all = parseScenarios(
      _descriptorFiles(requireString(config, 'scenario_directory')),
      exists: exists,
    );
    final uncovered = _uncoveredRoutes(
      requireString(config, 'routes_file'),
      all,
    );
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
    final outcomes = <String, TargetStatus>{};
    final pendingBaselines = <File, Map<String, dynamic>>{};

    /// Writes the report, Markdown and history line of a target. `status` in
    /// [body] is a [TargetStatus]; it is written as its label.
    Future<void> record(
      String id,
      String kind,
      Map<String, dynamic> body,
    ) async {
      final status = body['status'] as TargetStatus;
      outcomes[id] = status;
      final labelled = {...body, 'status': status.label};
      final reportDir = Directory('$reportRoot/$id')
        ..createSync(recursive: true);
      final report = <String, dynamic>{
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'target': id,
        'kind': kind,
        'environment': environment,
        ...labelled,
      };
      final reportFile = File('${reportDir.path}/$stamp.json')
        ..writeAsStringSync(_pretty(report));
      File(
        '${reportDir.path}/$stamp.md',
      ).writeAsStringSync(mask(targetMarkdown(report), _secrets));
      final summary = body['summary'];
      final history = {
        'timestamp': report['timestamp'],
        'target': id,
        'device_id': device,
        'flavor': flavor,
        if (summary is Map) ...summary,
        'status': status.label,
      };
      File(historyPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '${encodeMasked(history, _secrets, pretty: false)}\n',
          mode: FileMode.append,
        );
      results.add(
        resultEntry(
          id: id,
          kind: kind,
          body: labelled,
          reportPath: reportFile.path,
        ),
      );
      _printTarget(id, labelled);
    }

    Map<String, dynamic>? baselineFor(String id) {
      final file = File('$baselineRoot/$id/${_safe(device)}.json');
      if (!file.existsSync()) return null;
      final baseline = _json(file);
      if (sameEnvironment(baseline, id, environment)) {
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
        final summary = summarize(samples, startupMetrics);
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
          'status': TargetStatus.fromGate(result.passed),
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
          try {
            validateSample(sample);
          } on InvalidSampleException catch (error) {
            throw _TargetError(error.message);
          }
          if (warmup) continue;
          final decision = decideRetry(
            sample,
            discardedCount: discarded.length,
            policy: retry,
          );
          if (decision.discard) {
            discarded.add(decision.discardedRun(attempts));
            stdout.writeln(
              '${scenario.id}: discarded run, '
              '${decision.owners.join('/')} failure',
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
        final summary = summarizeScenario(measured);
        final result = evaluate(summary, baselineFor(scenario.id), gate);
        // Scenario targets override global bands; global data budgets
        // remain a fallback for scenarios without their own.
        final targets = scenario.targets;
        final ratings = rateMetrics(
          summary,
          bands: {...bands, ...?targets?.bands},
          budgets: {...?budgets[scenario.id], ...?targets?.budgets},
        );
        final requestFailures = triage(measured.last, discarded);
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
          'status': TargetStatus.fromGate(result.passed),
          'rating': overallRating(ratings.values).label,
          'ratings': {for (final r in ratings.entries) r.key: r.value.toJson()},
          if (targets != null) 'targets': targets.toJson(),
          'source': ?scenario.source,
          'failures': result.failures,
          'request_failures': requestFailures,
          'discarded_runs': discarded,
          'diagnosis': diagnosis,
          if (network is Map) 'network': network,
          'log': log.path,
        });
      } on _TargetError catch (error) {
        final requestFailures = triage(null, error.failures);
        await record(scenario.id, 'scenario', {
          ..._errorBody(error, log),
          'description': scenario.description,
          'routes': scenario.routes,
          'request_failures': requestFailures,
          'discarded_runs': error.failures,
        });
        _queue(
          pendingPath,
          pendingEntry(
            id: scenario.id,
            reason: error.message,
            triage: requestFailures,
            deviceId: environment['device_id'],
            queuedAt: DateTime.now(),
          ),
        );
      }
    }

    for (final entry in outcomes.entries) {
      if (entry.value != TargetStatus.error) _unqueue(pendingPath, entry.key);
    }
    final overall = TargetStatus.overall(outcomes.values);
    final approved = <String>[];
    if (options.approve && overall == TargetStatus.pass) {
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
      'status': overall.label,
      'command': mask(
        ['dart', 'run', 'tool/perf.dart', ...args].join(' '),
        _secrets,
      ),
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
    ).writeAsStringSync(mask(summaryMarkdown(latest), _secrets));
    stdout.writeln('PERFORMANCE: ${overall.label}');
    stdout.writeln('Summary: ${latestDir.path}/summary.json');
    exitCode = overall.exitCode;
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
      mask(
        '\$ ${command.join(' ')}\n${result.stdout}\n${result.stderr}\n'
        'exit ${result.exitCode}\n\n',
        _secrets,
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
  'status': TargetStatus.error,
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
    ..._environmentDefines([..._publicDefines, ..._secretDefines]),
    if (binary != null) '--use-application-binary=$binary',
  ];
  final result = await _process(flutter, args);
  log.add([...flutter, ...args], result);
  if (result.exitCode != 0) {
    throw _TargetError('flutter drive failed (${result.exitCode})');
  }
  return '${result.stdout}\n${result.stderr}';
}

Future<List<Map<String, dynamic>>> _measureStartup(
  List<String> flutter,
  String platform,
  String flavor,
  String device,
  StartupConfig startup,
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
        ..._environmentDefines(_publicDefines),
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
// Config files

/// Decoded scenario descriptors of [path], sorted by file path.
List<({String path, Map<String, dynamic> json})> _descriptorFiles(String path) {
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
  return [for (final file in files) (path: file.path, json: _json(file))];
}

List<String> _uncoveredRoutes(String path, List<ScenarioDescriptor> scenarios) {
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

List<dynamic> _readPending(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];
  final value = jsonDecode(file.readAsStringSync());
  return value is List ? value : const [];
}

/// Records a target that could not be measured so it is re-run later.
void _queue(String path, Map<String, dynamic> entry) {
  final pending = withoutPending(_readPending(path), entry['id'] as String);
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(_pretty([...pending, entry]));
}

void _unqueue(String path, String id) {
  final file = File(path);
  if (!file.existsSync()) return;
  file.writeAsStringSync(_pretty(withoutPending(_readPending(path), id)));
}

Map<String, dynamic> _json(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

// ---------------------------------------------------------------------------
// Helpers

/// Maps a `flutter devices --machine` entry to `android`/`ios`, or null.
String? _platformOf(Map<String, dynamic> device) {
  final target = '${device['targetPlatform'] ?? device['platformType'] ?? ''}';
  if (target.startsWith('android')) return 'android';
  if (target == 'ios') return 'ios';
  return null;
}

String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

/// Indented JSON with every secret masked, for every file the run writes.
String _pretty(Object value) => encodeMasked(value, _secrets);

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
        '${entry.key}: ${formatValue(entry.value)}'
        '${change is num ? ' (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)' : ''}',
      );
    }
  }
  for (final failure in body['failures'] as List) {
    stdout.writeln('- $failure');
  }
}
