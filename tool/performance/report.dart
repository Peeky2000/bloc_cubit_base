/// Markdown rendering of benchmark reports and the run summary.
///
/// Pure Dart so the output is unit tested without a device.
library;

/// Two decimals for numbers, `n/a` otherwise.
String formatValue(Object? value) =>
    value is num ? value.toStringAsFixed(2) : 'n/a';

/// Markdown for one target report: metrics, failures, diagnosis, rating,
/// targets label, request triage, network and the log tail.
String targetMarkdown(Map<String, dynamic> report) {
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
        '| ${entry.key} | ${formatValue(entry.value)} | ${formatValue(c?['baseline'])} | '
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
      ..writeln(hotspotTable(diagnosis));
  }
  final ratings = report['ratings'];
  if (ratings is Map && ratings.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(ratingTable(report['rating'], ratings));
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
      ..writeln(triageTable(triage));
  }
  final network = report['network'];
  if (network is Map) {
    buffer
      ..writeln()
      ..writeln(networkTable(network));
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

/// Slowest widgets of an instrumented diagnosis run.
String hotspotTable(Map<dynamic, dynamic> diagnosis) {
  final rows = <String>[
    '## Slowest widgets (instrumented run, compare relatively)',
    '',
    '| Widget / render object | Self ms | Total ms | Count |',
    '|---|---:|---:|---:|',
  ];
  for (final h in (diagnosis['hotspots'] as List? ?? const [])) {
    final m = h as Map;
    rows.add(
      '| ${m['name']} | ${formatValue(m['self_ms'])} | ${formatValue(m['total_ms'])} | '
      '${m['count']} |',
    );
  }
  return rows.join('\n');
}

/// Per-metric GOOD/NEEDS_IMPROVEMENT/POOR table under the overall rating.
String ratingTable(Object? overall, Map<dynamic, dynamic> ratings) {
  final rows = <String>[
    '## Rating: $overall',
    '',
    '| Metric | Value | Good up to | Poor above | Data size | Rating |',
    '|---|---:|---:|---:|---:|---|',
  ];
  for (final e in ratings.entries) {
    final m = e.value as Map;
    rows.add(
      '| ${e.key} | ${formatValue(m['value'])} | ${formatValue(m['good'])} | '
      '${formatValue(m['poor'])} | ${m['items'] ?? ''} | ${m['rating']} |',
    );
  }
  return rows.join('\n');
}

/// Failed requests grouped by owner, one example each.
String triageTable(Map<dynamic, dynamic> triage) {
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

/// Request totals and per-endpoint rows of the last measured run.
String networkTable(Map<dynamic, dynamic> network) {
  final rows = <String>[
    '## Network (last measured run, query strings removed)',
    '',
    'Requests ${network['request_count']}, failed ${network['failed_count']}, '
        'p95 ${formatValue(network['request_p95_ms'])} ms, '
        '${formatValue(network['response_kb'])} KB',
    '',
    '| Endpoint | Count | Worst ms | KB | Failures |',
    '|---|---:|---:|---:|---:|',
  ];
  for (final e in (network['endpoints'] as List? ?? const [])) {
    final m = e as Map;
    rows.add(
      '| ${m['endpoint']}${m['slow'] == true ? ' (slow)' : ''} | ${m['count']} | '
      '${formatValue(m['worst_ms'])} | ${formatValue(m['response_kb'])} | ${m['failures']} |',
    );
  }
  return rows.join('\n');
}

/// Markdown for `summary.json`: one row per target, then details,
/// pending re-runs and uncovered routes.
String summaryMarkdown(Map<String, dynamic> latest) {
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
    if (diagnosis is Map) buffer.writeln(hotspotTable(diagnosis));
    if (network is Map) buffer.writeln(networkTable(network));
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
