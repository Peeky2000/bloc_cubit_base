import 'dart:convert';
import 'dart:io';

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

Future<void> run(List<String> args) async {
  final approve = args.length == 1 && args.single == '--approve-baseline';
  if (args.isNotEmpty && !approve) {
    stderr.writeln('Usage: dart run perf [--approve-baseline]');
    exitCode = 2;
    return;
  }
  try {
    final config = _json(File('tool/performance/config.json'));
    if (config['command'] != 'dart run perf') {
      throw const FormatException('command must be dart run perf');
    }
    final runs = _count(config, 'runs');
    final warmups = _count(config, 'warmup_runs', zero: true);
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
    final available = (jsonDecode(devices.stdout) as List)
        .whereType<Map<String, dynamic>>()
        .where(
          (d) =>
              d['isSupported'] != false &&
              (d['platformType'] == 'android' || d['platformType'] == 'ios'),
        )
        .toList();
    final requested = Platform.environment['FLUTTER_PERF_DEVICE'];
    if (requested == null && available.length != 1) {
      throw StateError(
        'Select a connected device with FLUTTER_PERF_DEVICE '
        '(${available.length} available).',
      );
    }
    final device = requested ?? available.single['id'] as String;
    final match = available.where((d) => d['id'] == device).toList();
    if (match.length != 1) throw StateError('Unsupported device: $device');
    final flutterInfo = jsonDecode(version.stdout) as Map<String, dynamic>;
    final environment = <String, dynamic>{
      'device_id': device,
      'platform': match.single['platformType'],
      'emulator': match.single['emulator'],
      'flutter_version': flutterInfo['frameworkVersion'],
      'dart_version': Platform.version,
      'build_mode': 'profile',
      'cpu': 'unsupported',
      'memory': 'unsupported',
    };
    var anyFailure = false;
    final pendingBaselines = <File, Map<String, dynamic>>{};
    for (final scenario in scenarios) {
      final measured = <Map<String, dynamic>>[];
      for (var i = 0; i < runs + warmups; i++) {
        stdout.writeln(
          '${scenario.id}: ${i < warmups ? 'warmup' : 'run'} '
          '${i < warmups ? i + 1 : i - warmups + 1}',
        );
        final result = await _process(flutter, [
          'drive',
          '--profile',
          '-d',
          device,
          '--driver=test_driver/perf_driver.dart',
          '--target=${scenario.test}',
        ]);
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        if (result.exitCode != 0) {
          throw StateError(
            '${scenario.id}: profile run failed (${result.exitCode})',
          );
        }
        final sample = _marker('${result.stdout}\n${result.stderr}');
        if (sample == null)
          throw StateError('${scenario.id}: no metrics returned');
        _validate(sample, scenario.id);
        if (i >= warmups) measured.add(sample);
      }
      final summary = {
        for (final key in _metrics)
          key: _median(
            measured.map((r) => (r[key] as num).toDouble()).toList(),
          ),
      };
      final baselineFile = File(
        '${_required(config, 'baseline_directory')}/'
        '${scenario.id}/${_safe(device)}.json',
      );
      final baseline = approve || !baselineFile.existsSync()
          ? null
          : _json(baselineFile);
      if (baseline != null &&
          (baseline['scenario'] != scenario.id ||
              (baseline['environment'] as Map)['device_id'] != device ||
              (baseline['environment'] as Map)['flutter_version'] !=
                  environment['flutter_version'])) {
        throw FormatException(
          '${scenario.id}: baseline device/Flutter differs; '
          'use the same environment or approve a new baseline.',
        );
      }
      final previous = baseline?['summary'] as Map<String, dynamic>?;
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
      final thresholds = config['thresholds'] as Map<String, dynamic>;
      final failures = <String>[];
      for (final pair in <String, String>{
        'jank_percent': 'max_jank_percent',
        'frame_p95_ms': 'max_frame_p95_ms',
        'frame_p99_ms': 'max_frame_p99_ms',
        'scenario_ms': 'max_scenario_ms',
      }.entries) {
        if (summary[pair.key]! > (thresholds[pair.value] as num)) {
          failures.add(
            '${pair.key} ${summary[pair.key]} > ${thresholds[pair.value]}',
          );
        }
        final delta = (comparison[pair.key] as Map?)?['change_percent'];
        if (delta is num &&
            delta > (thresholds['max_regression_percent'] as num)) {
          failures.add('${pair.key} regression +${delta.toStringAsFixed(2)}%');
        }
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
      final reportDir = Directory(
        '${_required(config, 'report_directory')}/${scenario.id}',
      )..createSync(recursive: true);
      final stamp = now.toIso8601String().replaceAll(':', '-');
      File(
        '${reportDir.path}/$stamp.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      File('${reportDir.path}/$stamp.md').writeAsStringSync(_markdown(report));
      final history = File(_required(config, 'history_file'))
        ..createSync(recursive: true);
      history.writeAsStringSync(
        '${jsonEncode({'timestamp': now.toIso8601String(), 'scenario': scenario.id, 'device_id': device, ...summary, 'status': status})}\n',
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
          '$key: ${summary[key]!.toStringAsFixed(2)}'
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
  if (!folder.existsSync())
    throw FormatException('Missing scenario directory: $path');
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
  if (value is! String || value.isEmpty)
    throw FormatException('$key is required');
  return value;
}

int _count(Map<String, dynamic> map, String key, {bool zero = false}) {
  final value = map[key];
  if (value is! int || value < (zero ? 0 : 1))
    throw FormatException('Invalid $key');
  return value;
}

String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
Future<List<String>> _flutter() async {
  final command = await Process.run(
    Platform.isWindows ? 'where.exe' : 'which',
    ['fvm'],
  );
  return command.exitCode == 0
      ? ['fvm', 'flutter']
      : [Platform.isWindows ? 'flutter.bat' : 'flutter'];
}

Future<ProcessResult> _process(List<String> command, List<String> args) =>
    Process.run(command.first, [
      ...command.skip(1),
      ...args,
    ], runInShell: Platform.isWindows);
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
