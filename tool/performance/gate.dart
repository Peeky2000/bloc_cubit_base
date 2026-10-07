/// Pure regression gate shared by every benchmark target.
///
/// Kept free of `dart:io` so it can be unit tested without a device.
class GateConfig {
  const GateConfig({
    required this.limits,
    required this.maxRegressionPercent,
    this.zeroBaselineDelta = const {},
    this.minFrameCount,
    this.optionalLimits = const {},
  });

  /// Gated metric -> hard maximum.
  final Map<String, num> limits;

  /// Allowed relative growth versus a non-zero baseline.
  final num maxRegressionPercent;

  /// Gated metric -> allowed absolute growth when the baseline value is 0.
  final Map<String, num> zeroBaselineDelta;

  /// Minimum median `frame_count`; null when the target has no frames.
  final num? minFrameCount;

  /// Hard maximums applied only when the metric was measured, such as
  /// network failures that need the VM service.
  final Map<String, num> optionalLimits;
}

class GateResult {
  const GateResult(this.comparison, this.failures);

  /// Metric -> baseline/current/difference/change_percent.
  final Map<String, Map<String, num?>> comparison;
  final List<String> failures;

  bool get passed => failures.isEmpty;
}

GateResult evaluate(
  Map<String, double> summary,
  Map<String, dynamic>? baseline,
  GateConfig config,
) {
  final comparison = <String, Map<String, num?>>{
    if (baseline != null)
      for (final entry in summary.entries)
        if (baseline[entry.key] is num)
          entry.key: _compare(entry.value, baseline[entry.key] as num),
  };
  final failures = <String>[];
  for (final limit in config.limits.entries) {
    final metric = limit.key;
    final current = summary[metric];
    if (current == null) {
      failures.add('$metric missing from the measurement');
      continue;
    }
    if (current > limit.value) {
      failures.add('$metric ${_fmt(current)} > ${_fmt(limit.value)}');
    }
    final base = baseline?[metric];
    if (base is! num) continue;
    if (base == 0) {
      final allowed = config.zeroBaselineDelta[metric] ?? 0;
      if (current - base > allowed) {
        failures.add(
          '$metric regression ${_fmt(current)} from zero baseline '
          '(allowed +${_fmt(allowed)})',
        );
      }
    } else {
      final change = (current / base - 1) * 100;
      if (change > config.maxRegressionPercent) {
        failures.add('$metric regression +${change.toStringAsFixed(2)}%');
      }
    }
  }
  for (final limit in config.optionalLimits.entries) {
    final current = summary[limit.key];
    if (current != null && current > limit.value) {
      failures.add('${limit.key} ${_fmt(current)} > ${_fmt(limit.value)}');
    }
  }
  final minFrames = config.minFrameCount;
  final frames = summary['frame_count'];
  if (minFrames != null && frames != null && frames < minFrames) {
    failures.add(
      'frame_count ${_fmt(frames)} < ${_fmt(minFrames)}; '
      'too few frames for reliable percentiles',
    );
  }
  return GateResult(comparison, failures);
}

Map<String, num?> _compare(double current, num base) => {
  'baseline': base,
  'current': current,
  'difference': current - base,
  'change_percent': base == 0 ? null : (current / base - 1) * 100,
};

String _fmt(num value) => value.toStringAsFixed(2);
