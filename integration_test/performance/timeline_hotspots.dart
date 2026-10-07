/// Summarizes a VM timeline captured during an instrumented diagnosis run.
///
/// Pure Dart so it can be unit tested on the host.
library;

/// Framework phase events; reported as totals, not as widget hotspots.
const _phaseNames = <String>{
  'Frame',
  'Animate',
  'BUILD',
  'LAYOUT',
  'LAYOUT (root)',
  'PAINT',
  'PAINT (root)',
  'UPDATING COMPOSITING BITS',
  'UPDATING COMPOSITING BITS (root)',
  'SEMANTICS',
  'SEMANTICS (root)',
  'FINALIZE TREE',
  'Semantics.updateChildren',
  'Semantics.ensureGeometry',
};

class _Span {
  _Span(this.name, this.start, this.end);
  final String name;
  final num start;
  final num end;
  num childTime = 0;
  num get duration => end - start;
}

/// Returns phase totals, the slowest widget/render-object spans by self time,
/// and GC counts. Absolute values are inflated by instrumentation, so callers
/// must compare entries relative to each other.
Map<String, Object> summarizeTimeline(
  Map<String, dynamic> timeline, {
  int limit = 15,
}) {
  final events = timeline['traceEvents'];
  final spansByThread = <Object?, List<_Span>>{};
  final openByThread = <Object?, List<Map<String, dynamic>>>{};
  var newGen = 0;
  var oldGen = 0;
  for (final raw in events is List ? events : const <Object?>[]) {
    if (raw is! Map) continue;
    final event = raw.cast<String, dynamic>();
    final name = event['name'];
    final category = event['cat'];
    if (category == 'GC') {
      if (name == 'CollectNewGeneration') newGen++;
      if (name == 'CollectOldGeneration') oldGen++;
      continue;
    }
    if (category != 'Dart' || name is! String) continue;
    final tid = event['tid'];
    final ts = event['ts'];
    if (ts is! num) continue;
    switch (event['ph']) {
      case 'X':
        final dur = event['dur'];
        if (dur is num) {
          (spansByThread[tid] ??= []).add(_Span(name, ts, ts + dur));
        }
      case 'B':
        (openByThread[tid] ??= []).add(event);
      case 'E':
        final open = openByThread[tid];
        if (open == null || open.isEmpty) continue;
        final begin = open.removeLast();
        (spansByThread[tid] ??= []).add(
          _Span(begin['name'] as String, begin['ts'] as num, ts),
        );
    }
  }

  final self = <String, num>{};
  final total = <String, num>{};
  final count = <String, int>{};
  for (final spans in spansByThread.values) {
    spans.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : b.end.compareTo(a.end);
    });
    final stack = <_Span>[];
    for (final span in spans) {
      while (stack.isNotEmpty && stack.last.end <= span.start) {
        stack.removeLast();
      }
      if (stack.isNotEmpty) stack.last.childTime += span.duration;
      stack.add(span);
    }
    for (final span in spans) {
      self[span.name] = (self[span.name] ?? 0) + span.duration - span.childTime;
      total[span.name] = (total[span.name] ?? 0) + span.duration;
      count[span.name] = (count[span.name] ?? 0) + 1;
    }
  }

  double ms(num micros) => (micros / 1000 * 100).roundToDouble() / 100;
  final hotspots = self.keys.where((n) => !_phaseNames.contains(n)).toList()
    ..sort((a, b) => self[b]!.compareTo(self[a]!));
  return {
    'note':
        'Instrumented run: absolute times are inflated. Compare entries '
        'relative to each other; never use them as benchmark numbers.',
    'phases_ms': {
      for (final name in _phaseNames)
        if (total.containsKey(name)) name: ms(total[name]!),
    },
    'hotspots': [
      for (final name in hotspots.take(limit))
        {
          'name': name,
          'self_ms': ms(self[name]!),
          'total_ms': ms(total[name]!),
          'count': count[name]!,
        },
    ],
    'gc': {'new_gen': newGen, 'old_gen': oldGen},
  };
}
