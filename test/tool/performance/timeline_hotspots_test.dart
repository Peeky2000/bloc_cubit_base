import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/performance/timeline_hotspots.dart';

Map<String, dynamic> _b(String name, int ts, {int tid = 1}) => {
  'name': name,
  'cat': 'Dart',
  'ph': 'B',
  'ts': ts,
  'tid': tid,
};

Map<String, dynamic> _e(String name, int ts, {int tid = 1}) => {
  'name': name,
  'cat': 'Dart',
  'ph': 'E',
  'ts': ts,
  'tid': tid,
};

void main() {
  test('ranks widgets by self time and excludes framework phases', () {
    final summary = summarizeTimeline({
      'traceEvents': [
        _b('BUILD', 0),
        _b('OrderList', 0),
        _b('OrderTile', 1000),
        _e('OrderTile', 7000),
        _e('OrderList', 8000),
        _b('Header', 8000),
        _e('Header', 9000),
        _e('BUILD', 10000),
        {'name': 'CollectNewGeneration', 'cat': 'GC', 'ph': 'X', 'ts': 1},
        {'name': 'CollectOldGeneration', 'cat': 'GC', 'ph': 'X', 'ts': 2},
      ],
    });

    final hotspots = (summary['hotspots']! as List).cast<Map>();
    expect(hotspots.map((h) => h['name']), [
      'OrderTile',
      'OrderList',
      'Header',
    ]);
    expect(hotspots.first['self_ms'], 6.0);
    // OrderList total includes its child, self time does not.
    expect(hotspots[1]['total_ms'], 8.0);
    expect(hotspots[1]['self_ms'], 2.0);
    expect((summary['phases_ms']! as Map)['BUILD'], 10.0);
    expect(summary['gc'], {'new_gen': 1, 'old_gen': 1});
  });

  test('handles complete events and separate threads', () {
    final summary = summarizeTimeline({
      'traceEvents': [
        {
          'name': 'RenderParagraph',
          'cat': 'Dart',
          'ph': 'X',
          'ts': 0,
          'dur': 3000,
          'tid': 2,
        },
        _b('Card', 0, tid: 1),
        _e('Card', 2000, tid: 1),
        _e('Unmatched', 5000),
      ],
    });
    final names = (summary['hotspots']! as List).map((h) => (h as Map)['name']);
    expect(names, ['RenderParagraph', 'Card']);
  });

  test('returns empty sections for an empty timeline', () {
    final summary = summarizeTimeline(const {});
    expect(summary['hotspots'], isEmpty);
    expect(summary['phases_ms'], isEmpty);
  });
}
