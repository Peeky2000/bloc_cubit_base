import 'dart:convert';
import 'dart:io';

const _usage = 'Usage: dart run tool/perf.dart [--approve-baseline]';

const _metrics = <String>[
  'frame_p50_ms',
  'frame_p95_ms',
  'frame_p99_ms',
  'jank_percent',
  'frame_count',
  'build_p95_ms',
  'raster_p95_ms',
  'scenario_ms',
];

/// Gated metric -> hard-limit key in `thresholds`.
const _limits = <String, String>{
  'jank_percent': 'max_jank_percent',
  'frame_p95_ms': 'max_frame_p95_ms',
  'frame_p99_ms': 'max_frame_p99_ms',
  'scenario_ms': 'max_scenario_ms',
};

const _zeroBaselineKey = 'zero_baseline_regression_delta';

Future<void> run(List<String> args) async {
  final approve = args.length == 1 && args.single == '--approve-baseline';
  if (args.isNotEmpty && !approve) {
    stderr.writeln(_usage);
    exitCode = 2;
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
    final thresholds = _thresholds(config);
    final zeroBaselineDelta = _zeroBaselineDelta(config);
    final reportRoot = _required(config, 'report_directory');
    final historyPath = _required(config, 'history_file');
    final baselineRoot = _required(config, 'baseline_directory');
    final all = _scenarios(_required(config, 'scenario_directory'));
    final uncovered = _uncoveredRoutes(_required(config, 'routes_file'), all);
    stdout.writeln(
      'Routes without enabled scenarios: '
      '${uncovered.isEmpty ? 'none' : uncovered.join(', ')}',
    );
    final scenarios = all.where((s) => s.enabled).toList();
    if (scenarios.isEmpty) {
      throw const FormatException(
        'No enabled scenario. Add one under '
        'integration_test/performance/scenarios.',
      );
    }
    final flutter = await _flutter();
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
        'Select a connected Android/iOS device with FLUTTER_PERF_DEVICE '
        '(${available.length} available).',
      );
    }
    final device = requested ?? available.single['id'] as String;
    final match = available.where((d) => d['id'] == device).toList();
    if (match.length != 1) {
      throw StateError('Unsupported device: $device');
    }
    final platform = _platformOf(match.single)!;
    final flutterInfo = jsonDecode(version.stdout as String) as Map;
    final environment = <String, dynamic>{
      'device_id': device,
      'platform': platform,
      'emulator': match.single['emulator'],
      'flavor': flavor,
      'flutter_version': flutterInfo['frameworkVersion'],
      'dart_version': Platform.version,
      'build_mode': 'profile',
      'cpu': 'unsupported',
      'memory': 'unsupported',
    };
    var anyFailure = false;
    final pendingBaselines = <File, Map<String, dynamic>>{};
    for (final scenario in scenarios) {
      final binary = await _prebuild(flutter, platform, flavor, scenario);
      final measured = <Map<String, dynamic>>[];
      for (var i = 0; i < runs + warmups; i++) {
        final warmup = i < warmups;
        stdout.writeln(
          '${scenario.id}: ${warmup ? 'warmup' : 'run'} '
          '${warmup ? i + 1 : i - warmups + 1}',
        );
        final result = await _process(flutter, [
          'drive',
          '--profile',
          '--flavor',
          flavor,
          '-d',
          device,
          '--driver=test_driver/perf_driver.dart',
          '--target=${scenario.test}',
          if (binary != null) '--use-application-binary=$binary',
        ]);
        _echo(result);
        if (result.exitCode != 0) {
          throw StateError(
            '${scenario.id}: profile run failed (${result.exitCode})',
          );
        }
        final sample = _marker('${result.stdout}\n${result.stderr}');
        if (sample == null) {
          throw StateError('${scenario.id}: no metrics returned');
        }
        _validate(sample, scenario.id);
        if (!warmup) measured.add(sample);
      }
      final summary = <String, double>{
        for (final key in _metrics)
          key: _median(
            measured.map((r) => (r[key] as num).toDouble()).toList(),
          ),
      };
      final baselineFile = File(
        '$baselineRoot/${scenario.id}/${_safe(device)}.json',
      );
      final baseline = baselineFile.existsSync() ? _json(baselineFile) : null;
      final comparable =
          baseline != null &&
          _sameEnvironment(baseline, scenario.id, environment);
      if (baseline != null && !comparable) {
        if (!approve) {
          throw FormatException(
            '${scenario.id}: baseline scenario/device/flavor/Flutter differs; '
            'use the same environment or approve a new baseline.',
          );
        }
        stdout.writeln(
          '${scenario.id}: existing baseline was recorded in another '
          'environment and is not compared.',
        );
      }
      // An approval run is still compared with the existing baseline, so a
      // regression can never be approved silently.
      final previous = comparable
          ? baseline['summary'] as Map<String, dynamic>?
          : null;
      final comparison = <String, dynamic>{
        if (previous != null)
          for (final key in _metrics)
            if (previous[key] is num)
              key: {
                'baseline': previous[key],
                'current': summary[key],
                'difference': summary[key]! - (previous[key] as num),
                'change_percent': previous[key] == 0
                    ? null
                    : (summary[key]! / (previous[key] as num) - 1) * 100,
              },
      };
      final failures = <String>[];
      for (final entry in _limits.entries) {
        final metric = entry.key;
        final current = summary[metric]!;
        final limit = thresholds[entry.value]!;
        if (current > limit) {
          failures.add('$metric ${_fmt(current)} > ${_fmt(limit)}');
        }
        final base = previous?[metric];
        if (base is! num) continue;
        if (base == 0) {
          // A relative change is undefined; use an absolute floor instead.
          final allowed = zeroBaselineDelta[metric]!;
          if (current - base > allowed) {
            failures.add(
              '$metric regression ${_fmt(current)} from zero baseline '
              '(allowed +${_fmt(allowed)})',
            );
          }
        } else {
          final change = (current / base - 1) * 100;
          if (change > thresholds['max_regression_percent']!) {
            failures.add('$metric regression +${change.toStringAsFixed(2)}%');
          }
        }
      }
      final minFrames = thresholds['min_frame_count']!;
      if (summary['frame_count']! < minFrames) {
        failures.add(
          'frame_count ${_fmt(summary['frame_count']!)} < ${_fmt(minFrames)}; '
          'too few frames for reliable percentiles',
        );
      }
      final status = failures.isEmpty ? 'PASS' : 'FAIL';
      anyFailure |= failures.isNotEmpty;
      final now = DateTime.now().toUtc();
      final report = <String, dynamic>{
        'timestamp': now.toIso8601String(),
        'scenario': scenario.id,
        'description': scenario.description,
        'routes': scenario.routes,
        'uncovered_routes': uncovered,
        'environment': environment,
        'config': config,
        'runs': measured.length,
        'raw_results': measured,
        'summary': summary,
        'baseline': baseline,
        'comparison': comparison,
        'status': status,
        'failures': failures,
      };
      final reportDir = Directory('$reportRoot/${scenario.id}')
        ..createSync(recursive: true);
      final stamp = now.toIso8601String().replaceAll(':', '-');
      File(
        '${reportDir.path}/$stamp.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      File('${reportDir.path}/$stamp.md').writeAsStringSync(_markdown(report));
      final history = File(historyPath)..createSync(recursive: true);
      history.writeAsStringSync(
        '${jsonEncode({'timestamp': now.toIso8601String(), 'scenario': scenario.id, 'device_id': device, 'flavor': flavor, ...summary, 'status': status})}\n',
        mode: FileMode.append,
      );
      if (approve && failures.isEmpty) {
        pendingBaselines[baselineFile] = {
          'approved_at_utc': now.toIso8601String(),
          'scenario': scenario.id,
          'environment': environment,
          'summary': summary,
        };
      }
      stdout.writeln('PERFORMANCE ${scenario.id}: $status');
      for (final key in <String>[
        'frame_p50_ms',
        'frame_p95_ms',
        'frame_p99_ms',
        'jank_percent',
        'scenario_ms',
      ]) {
        final change = (comparison[key] as Map?)?['change_percent'];
        stdout.writeln(
          '$key: ${_fmt(summary[key]!)}'
          '${change is num ? ' (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)' : ''}',
        );
      }
      for (final failure in failures) {
        stdout.writeln('- $failure');
      }
      stdout.writeln('Report: ${reportDir.path}/$stamp.json');
    }
    if (approve && !anyFailure) {
      for (final entry in pendingBaselines.entries) {
        entry.key.parent.createSync(recursive: true);
        entry.key.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(entry.value),
        );
        stdout.writeln('Baseline approved: ${entry.key.path}');
      }
    } else if (approve) {
      stdout.writeln(
        'Baselines unchanged because at least one scenario failed.',
      );
    }
    exitCode = anyFailure ? 1 : 0;
  } catch (error) {
    stderr.writeln('Performance tooling error: $error');
    exitCode = 2;
  }
}

class _Scenario {
  const _Scenario(
    this.id,
    this.description,
    this.routes,
    this.test,
    this.enabled,
  );
  final String id;
  final String description;
  final List<String> routes;
  final String test;
  final bool enabled;
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
  final ids = <String>{};
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
    result.add(
      _Scenario(
        id,
        _required(value, 'description'),
        routes.cast<String>(),
        test,
        value['enabled'] as bool,
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

Map<String, num> _thresholds(Map<String, dynamic> config) {
  final raw = config['thresholds'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('thresholds is required');
  }
  return {
    for (final key in [
      ..._limits.values,
      'max_regression_percent',
      'min_frame_count',
    ])
      key: _number(raw, key, 'thresholds.$key'),
  };
}

Map<String, num> _zeroBaselineDelta(Map<String, dynamic> config) {
  final raw = (config['thresholds'] as Map<String, dynamic>)[_zeroBaselineKey];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('thresholds.$_zeroBaselineKey is required');
  }
  return {
    for (final key in _limits.keys)
      key: _number(raw, key, 'thresholds.$_zeroBaselineKey.$key'),
  };
}

/// Maps a `flutter devices --machine` entry to `android`/`ios`, or null.
String? _platformOf(Map<String, dynamic> device) {
  final target = '${device['targetPlatform'] ?? device['platformType'] ?? ''}';
  if (target.startsWith('android')) return 'android';
  if (target == 'ios') return 'ios';
  return null;
}

bool _sameEnvironment(
  Map<String, dynamic> baseline,
  String scenario,
  Map<String, dynamic> environment,
) {
  final previous = baseline['environment'];
  return baseline['scenario'] == scenario &&
      previous is Map &&
      previous['device_id'] == environment['device_id'] &&
      previous['flavor'] == environment['flavor'] &&
      previous['flutter_version'] == environment['flutter_version'];
}

/// Builds the profile APK once per scenario so every warmup/measured run
/// reuses the same binary. iOS requires a signed IPA for reuse, so iOS keeps
/// building inside `flutter drive`.
Future<String?> _prebuild(
  List<String> flutter,
  String platform,
  String flavor,
  _Scenario scenario,
) async {
  if (platform != 'android') return null;
  stdout.writeln('${scenario.id}: building profile APK once');
  final result = await _process(flutter, [
    'build',
    'apk',
    '--profile',
    '--flavor',
    flavor,
    '--target=${scenario.test}',
  ]);
  _echo(result);
  if (result.exitCode != 0) {
    throw StateError('${scenario.id}: profile build failed');
  }
  final apk = File('build/app/outputs/flutter-apk/app-$flavor-profile.apk');
  if (!apk.existsSync()) {
    throw StateError('${scenario.id}: missing ${apk.path}');
  }
  return apk.path;
}

String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

String _fmt(num value) => value.toStringAsFixed(2);

/// Uses the same Flutter resolution as every derry task.
Future<List<String>> _flutter() async {
  if (!Platform.isWindows) return ['./scripts/flutterw.sh'];
  final fvm = await Process.run('where.exe', ['fvm']);
  return fvm.exitCode == 0 ? ['fvm', 'flutter'] : ['flutter.bat'];
}

Future<ProcessResult> _process(List<String> command, List<String> args) =>
    Process.run(command.first, [
      ...command.skip(1),
      ...args,
    ], runInShell: Platform.isWindows);

void _echo(ProcessResult result) {
  stdout.write(result.stdout);
  stderr.write(result.stderr);
}

Map<String, dynamic>? _marker(String text) {
  final matches = RegExp(r'PERF_RESULT:(\{[^\r\n]+\})').allMatches(text);
  return matches.isEmpty
      ? null
      : jsonDecode(matches.last.group(1)!) as Map<String, dynamic>;
}

void _validate(Map<String, dynamic> sample, String id) {
  for (final key in _metrics) {
    final value = sample[key];
    if (value is! num || !value.isFinite || value < 0) {
      throw FormatException('$id missing/invalid $key');
    }
  }
  if (sample['frame_count'] == 0 ||
      sample['raw_frames'] is! List ||
      (sample['raw_frames'] as List).isEmpty) {
    throw FormatException('$id has no frame samples');
  }
}

double _median(List<double> values) {
  values.sort();
  final m = values.length ~/ 2;
  return values.length.isOdd ? values[m] : (values[m - 1] + values[m]) / 2;
}

String _markdown(Map<String, dynamic> report) {
  final summary = report['summary'] as Map;
  final comparison = report['comparison'] as Map;
  final rows = <String>[
    '| Metric | Current | Baseline | Change |',
    '|---|---:|---:|---:|',
  ];
  for (final key in _metrics) {
    final entry = comparison[key] as Map?;
    final change = entry?['change_percent'];
    rows.add(
      '| $key | ${summary[key]} | ${entry?['baseline'] ?? 'n/a'} | '
      '${change is num ? '${change.toStringAsFixed(2)}%' : 'n/a'} |',
    );
  }
  return '# ${report['scenario']}: ${report['status']}\n\n${rows.join('\n')}\n\n'
      'Failures: ${(report['failures'] as List).join('; ')}\n\n'
      'Uncovered routes: ${(report['uncovered_routes'] as List).join(', ')}\n';
}
