/// Pure decisions of the performance benchmark: config validation, retry,
/// triage, summaries, status precedence and secret masking.
///
/// Kept free of `dart:io` so every rule that turns measurements into
/// PASS/FAIL/ERROR is unit tested without a device. `run.dart` only does the
/// process, device and file work around these functions.
library;

import 'dart:convert';

import 'gate.dart';
import 'rating.dart';

// ---------------------------------------------------------------------------
// Metrics

/// Metrics every scenario run must return; they are always summarized.
const scenarioMetrics = <String>[
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
const optionalMetrics = <String>[
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

/// Metrics summarized for the cold-start target.
const startupMetrics = <String>[
  'startup_first_frame_ms',
  'startup_framework_init_ms',
];

/// Owners whose failures are temporary and worth an automatic re-run.
const retryableOwners = <String>{'network', 'backend'};

/// Gated scenario metric -> hard-limit key in `thresholds`.
const scenarioLimits = <String, String>{
  'jank_percent': 'max_jank_percent',
  'frame_p95_ms': 'max_frame_p95_ms',
  'frame_p99_ms': 'max_frame_p99_ms',
  'scenario_ms': 'max_scenario_ms',
};

// ---------------------------------------------------------------------------
// Status

/// Outcome of one benchmark target, and of the whole run.
enum TargetStatus {
  /// Measured and every gate passed.
  pass('PASS', 0),

  /// Measured, but a gate failed.
  fail('FAIL', 1),

  /// Could not be measured reliably (build, device or request failures).
  error('ERROR', 3);

  const TargetStatus(this.label, this.exitCode);

  /// Label written to JSON, Markdown and the console.
  final String label;

  /// Process exit code when this is the overall status.
  final int exitCode;

  /// [pass] when the gate passed, otherwise [fail].
  static TargetStatus fromGate(bool passed) => passed ? pass : fail;

  /// The overall status: ERROR beats FAIL beats PASS; PASS when empty.
  static TargetStatus overall(Iterable<TargetStatus> statuses) =>
      statuses.fold(pass, (worst, s) => s.index > worst.index ? s : worst);
}

// ---------------------------------------------------------------------------
// Config primitives

/// Non-empty string at [key], otherwise `FormatException('<key> is required')`.
String requireString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key is required');
  }
  return value;
}

/// Integer at [key] that is >= 1, or >= 0 when [zero] is true.
int requireCount(Map<String, dynamic> map, String key, {bool zero = false}) {
  final value = map[key];
  if (value is! int || value < (zero ? 0 : 1)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

/// Finite number >= 0 at [key]; [label] names it in the error.
num requireNumber(Map<String, dynamic> map, String key, String label) {
  final value = map[key];
  if (value is! num || !value.isFinite || value < 0) {
    throw FormatException('Invalid $label');
  }
  return value;
}

Map<String, dynamic> _thresholds(Map<String, dynamic> config) {
  final raw = config['thresholds'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('thresholds is required');
  }
  return raw;
}

num _maxRegression(Map<String, dynamic> thresholds) => requireNumber(
  thresholds,
  'max_regression_percent',
  'thresholds.max_regression_percent',
);

// ---------------------------------------------------------------------------
// Config sections

/// Gate for every scenario, from `thresholds`.
GateConfig parseScenarioGate(Map<String, dynamic> config) {
  final raw = _thresholds(config);
  final zero = raw['zero_baseline_regression_delta'];
  if (zero is! Map<String, dynamic>) {
    throw const FormatException(
      'thresholds.zero_baseline_regression_delta is required',
    );
  }
  return GateConfig(
    limits: {
      for (final entry in scenarioLimits.entries)
        entry.key: requireNumber(raw, entry.value, 'thresholds.${entry.value}'),
    },
    maxRegressionPercent: _maxRegression(raw),
    zeroBaselineDelta: {
      for (final key in scenarioLimits.keys)
        key: requireNumber(
          zero,
          key,
          'thresholds.zero_baseline_regression_delta.$key',
        ),
    },
    minFrameCount: requireNumber(
      raw,
      'min_frame_count',
      'thresholds.min_frame_count',
    ),
    optionalLimits: {
      'network_failed_count': requireNumber(
        raw,
        'max_network_failures',
        'thresholds.max_network_failures',
      ),
    },
  );
}

/// Global GOOD/POOR bands, from `bands`.
Map<String, Band> parseBands(Map<String, dynamic> config) {
  final raw = config['bands'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('bands is required');
  }
  return {for (final e in raw.entries) e.key: Band.fromJson(e.key, e.value)};
}

/// Scenario id -> metric -> budget, from the optional `data_budgets`.
Map<String, Map<String, DataBudget>> parseBudgets(Map<String, dynamic> config) {
  final raw = config['data_budgets'] ?? const <String, dynamic>{};
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('data_budgets must be an object');
  }
  return {
    for (final scenario in raw.entries)
      scenario.key: _budgetMap(scenario.value, 'data_budgets.${scenario.key}'),
  };
}

Map<String, DataBudget> _budgetMap(Object? raw, String label) {
  if (raw is! Map<String, dynamic>) {
    throw FormatException('$label must be an object');
  }
  return {
    for (final metric in raw.entries)
      metric.key: metric.value is Map<String, dynamic>
          ? DataBudget.fromJson(
              metric.key,
              metric.value as Map<String, dynamic>,
            )
          : throw FormatException('$label.${metric.key} must be an object'),
  };
}

/// How many runs may be discarded for temporary failures, and the pause.
class RetryPolicy {
  const RetryPolicy(this.maxExtraRuns, this.delay);

  /// Extra runs allowed per scenario after discarded ones.
  final int maxExtraRuns;

  /// Wait before the next attempt after a discarded run.
  final Duration delay;
}

/// Retry policy, from `retry`.
RetryPolicy parseRetryPolicy(Map<String, dynamic> config) {
  final raw = config['retry'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('retry is required');
  }
  return RetryPolicy(
    requireCount(raw, 'max_extra_runs', zero: true),
    Duration(seconds: requireCount(raw, 'delay_seconds', zero: true)),
  );
}

/// The cold-start target.
class StartupConfig {
  const StartupConfig(this.target, this.runs, this.gate, this.bands);

  /// Entry point measured with `flutter run --trace-startup`.
  final String target;
  final int runs;
  final GateConfig gate;
  final Map<String, Band> bands;
}

/// Startup target from `startup`, or null when absent or disabled.
///
/// Reads `thresholds.max_regression_percent` itself, so it does not depend on
/// [parseScenarioGate] having validated `thresholds` first. [exists] checks
/// that `startup.target` is a file.
StartupConfig? parseStartup(
  Map<String, dynamic> config, {
  required bool Function(String path) exists,
}) {
  final raw = config['startup'];
  if (raw == null) return null;
  if (raw is! Map<String, dynamic> || raw['enabled'] is! bool) {
    throw const FormatException('startup.enabled must be a bool');
  }
  if (raw['enabled'] != true) return null;
  final target = requireString(raw, 'target');
  if (!exists(target)) {
    throw FormatException('startup.target does not exist: $target');
  }
  final runs = requireCount(raw, 'runs');
  final firstFrame = requireNumber(
    raw,
    'max_first_frame_ms',
    'startup.max_first_frame_ms',
  );
  final maxRegression = _maxRegression(_thresholds(config));
  final bands = raw['bands'] ?? const <String, dynamic>{};
  if (bands is! Map<String, dynamic>) {
    throw const FormatException('startup.bands must be an object');
  }
  return StartupConfig(
    target,
    runs,
    GateConfig(
      limits: {'startup_first_frame_ms': firstFrame},
      maxRegressionPercent: maxRegression,
    ),
    {for (final e in bands.entries) e.key: Band.fromJson(e.key, e.value)},
  );
}

// ---------------------------------------------------------------------------
// Scenario descriptors

/// Per-scenario bands and data budgets. `proposed` targets were inferred by
/// an agent and still need PM approval; they rate runs but are labelled.
class ScenarioTargets {
  const ScenarioTargets(this.status, this.rationale, this.bands, this.budgets);

  /// `proposed` or `approved`.
  final String status;
  final String rationale;
  final Map<String, Band> bands;
  final Map<String, DataBudget> budgets;

  Map<String, Object> toJson() => {'status': status, 'rationale': rationale};
}

/// Scenario `targets` object, or null when absent. [file] names the error.
ScenarioTargets? parseTargets(Object? raw, String file) {
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
  return ScenarioTargets(status as String, rationale, {
    for (final e in bands.entries) e.key: Band.fromJson(e.key, e.value),
  }, _budgetMap(budgets, '$file: targets.data_budgets'));
}

/// One measured user flow, from `integration_test/performance/scenarios`.
class ScenarioDescriptor {
  const ScenarioDescriptor(
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

  /// Integration test file driven by `flutter drive`.
  final String test;
  final bool enabled;

  /// Where the flow came from, such as an acceptance criterion.
  final Map<String, dynamic>? source;

  /// Scenario-specific rating targets derived from the requirement.
  final ScenarioTargets? targets;
}

/// Validates decoded descriptors in the given order. Ids must be unique,
/// lowercase snake case and not `startup`; [exists] checks each `test` file.
List<ScenarioDescriptor> parseScenarios(
  List<({String path, Map<String, dynamic> json})> files, {
  required bool Function(String path) exists,
}) {
  final ids = <String>{'startup'};
  final result = <ScenarioDescriptor>[];
  for (final file in files) {
    final value = file.json;
    final id = requireString(value, 'id');
    final test = requireString(value, 'test');
    final routes = value['routes'];
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id) ||
        !ids.add(id) ||
        routes is! List ||
        routes.any((r) => r is! String) ||
        value['enabled'] is! bool ||
        !exists(test)) {
      throw FormatException('Invalid scenario descriptor: ${file.path}');
    }
    final source = value['source'];
    if (source != null && source is! Map<String, dynamic>) {
      throw FormatException('${file.path}: source must be an object');
    }
    result.add(
      ScenarioDescriptor(
        id,
        requireString(value, 'description'),
        routes.cast<String>(),
        test,
        value['enabled'] as bool,
        source: source as Map<String, dynamic>?,
        targets: parseTargets(value['targets'], file.path),
      ),
    );
  }
  return result;
}

// ---------------------------------------------------------------------------
// Samples

/// A scenario sample that cannot be used as a measurement.
class InvalidSampleException implements Exception {
  const InvalidSampleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Throws [InvalidSampleException] unless every [scenarioMetrics] value is a
/// finite number >= 0 and the sample has raw frames.
void validateSample(Map<String, dynamic> sample) {
  for (final key in scenarioMetrics) {
    final value = sample[key];
    if (value is! num || !value.isFinite || value < 0) {
      throw InvalidSampleException('missing/invalid $key');
    }
  }
  final frames = sample['raw_frames'];
  if (sample['frame_count'] == 0 || frames is! List || frames.isEmpty) {
    throw const InvalidSampleException('no frame samples');
  }
}

/// Failed requests of a sample, from `sample['network']['failures']`.
List<Map<dynamic, dynamic>> networkFailures(Map<String, dynamic>? sample) {
  final network = sample?['network'];
  final failures = network is Map ? network['failures'] : null;
  return failures is List ? failures.whereType<Map>().toList() : const [];
}

/// Owners of the failed requests of a sample.
Set<String> failureOwners(Map<String, dynamic> sample) => {
  for (final f in networkFailures(sample)) '${f['owner']}',
};

/// Whether a measured run is kept or discarded and measured again.
class RetryDecision {
  const RetryDecision._(this.discard, this.owners, this.failures);

  /// True when the run showed a temporary error state and is re-measured.
  final bool discard;

  /// Owners of the run's failed requests.
  final Set<String> owners;

  /// The run's failed requests.
  final List<Map<dynamic, dynamic>> failures;

  /// Entry for `discarded_runs` in the report.
  Map<String, dynamic> discardedRun(int attempt) => {
    'attempt': attempt,
    'owners': owners.toList(),
    'failures': failures,
  };
}

/// Discards a run only when it has failures, every owner is in
/// [retryableOwners] and fewer than `maxExtraRuns` runs were discarded. A
/// temporary network/backend failure means the app showed an error state,
/// not the real screen. Mobile or environment failures are kept so the gate
/// reports them.
RetryDecision decideRetry(
  Map<String, dynamic> sample, {
  required int discardedCount,
  required RetryPolicy policy,
}) {
  final failures = networkFailures(sample);
  final owners = {for (final f in failures) '${f['owner']}'};
  final discard =
      owners.isNotEmpty &&
      owners.every(retryableOwners.contains) &&
      discardedCount < policy.maxExtraRuns;
  return RetryDecision._(discard, owners, failures);
}

/// Groups failed requests of discarded runs and the last measured run by
/// owner, so the report says who has to act.
Map<String, dynamic> triage(
  Map<String, dynamic>? lastSample,
  List<Map<String, dynamic>> discarded,
) {
  final all = <Map>[
    for (final d in discarded)
      for (final f in (d['failures'] as List? ?? const [])) f as Map,
    ...networkFailures(lastSample),
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

// ---------------------------------------------------------------------------
// Pending re-runs

/// True unless an owner in [triage] says a re-run will never help.
bool shouldRetryLater(Map<String, dynamic> triage) => triage.entries
    .where((e) => e.value is Map)
    .every((e) => (e.value as Map)['retry'] != 'never');

/// `pending.json` entry for a target that could not be measured.
Map<String, dynamic> pendingEntry({
  required String id,
  required String reason,
  required Map<String, dynamic> triage,
  required Object? deviceId,
  required DateTime queuedAt,
}) => {
  'id': id,
  'queued_at': queuedAt.toUtc().toIso8601String(),
  'reason': reason,
  'owners': [
    for (final e in triage.entries)
      if (e.value is Map) e.key,
  ],
  'action': shouldRetryLater(triage)
      ? 'Re-run later: dart run tool/perf.dart --scenario=$id'
      : 'Fix the cause first; a re-run will fail the same way.',
  'device_id': deviceId,
};

/// [pending] without entries for [id].
List<dynamic> withoutPending(List<dynamic> pending, String id) =>
    pending.where((p) => p is! Map || p['id'] != id).toList();

// ---------------------------------------------------------------------------
// Baselines and summaries

/// True when [baseline] was recorded for [id] on the same device, flavor and
/// Flutter version as [environment].
bool sameEnvironment(
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

/// Median of non-empty [values]; does not modify the input.
double median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  final m = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[m] : (sorted[m - 1] + sorted[m]) / 2;
}

/// Metric -> median over [samples]; every sample must have every metric.
Map<String, double> summarize(
  List<Map<String, dynamic>> samples,
  List<String> metrics,
) => {
  for (final key in metrics)
    key: median(samples.map((r) => (r[key] as num).toDouble())),
};

/// Medians of [scenarioMetrics], plus [optionalMetrics] and `data_*` values
/// that every measured run returned as numbers.
Map<String, double> summarizeScenario(List<Map<String, dynamic>> measured) {
  bool everywhere(String key) => measured.every((r) => r[key] is num);
  return summarize(measured, [
    ...scenarioMetrics,
    for (final key in optionalMetrics)
      if (everywhere(key)) key,
    for (final key in measured.first.keys)
      if (key.startsWith('data_') && everywhere(key)) key,
  ]);
}

// ---------------------------------------------------------------------------
// Results

/// Keys copied from a report body into the `targets` list of summary.json.
const _resultKeys = <String>[
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
];

/// Entry for the `targets` list of summary.json. Keys and their order are
/// part of the output contract; missing body values become null.
Map<String, dynamic> resultEntry({
  required String id,
  required String kind,
  required Map<String, dynamic> body,
  required String reportPath,
}) => {
  'id': id,
  'kind': kind,
  for (final key in _resultKeys) key: body[key],
  'report': reportPath,
  'log': body['log'],
};

// ---------------------------------------------------------------------------
// Secrets

/// Replaces every secret in [text] with `***`, both as written and in its
/// JSON-escaped form, longest secret first.
///
/// Values shorter than 3 characters are ignored: masking every `1` or `a`
/// would destroy logs and reports, and such a value is not a usable secret.
String mask(String text, Iterable<String> secrets) {
  final values = {
    for (final s in secrets)
      if (s.length >= 3) ...[s, _jsonEscaped(s)],
  }.toList()..sort((a, b) => b.length.compareTo(a.length));
  var masked = text;
  for (final value in values) {
    masked = masked.replaceAll(value, '***');
  }
  return masked;
}

String _jsonEscaped(String value) {
  final encoded = jsonEncode(value);
  return encoded.substring(1, encoded.length - 1);
}

/// Copy of a decoded JSON [value] with secrets masked inside every string
/// and key, so encoding it always yields valid JSON.
Object? maskJson(Object? value, Iterable<String> secrets) => switch (value) {
  String() => mask(value, secrets),
  Map() => {
    for (final e in value.entries)
      e.key is String ? mask(e.key as String, secrets) : e.key: maskJson(
        e.value,
        secrets,
      ),
  },
  List() => [for (final v in value) maskJson(v, secrets)],
  _ => value,
};

/// JSON text of [value] with secrets masked; indented when [pretty].
String encodeMasked(
  Object? value,
  Iterable<String> secrets, {
  bool pretty = true,
}) {
  final masked = maskJson(value, secrets);
  return mask(
    pretty
        ? const JsonEncoder.withIndent('  ').convert(masked)
        : jsonEncode(masked),
    secrets,
  );
}
