import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/rating.dart';

void main() {
  const orders = DataBudget(
    metric: 'scenario_ms',
    itemsMetric: 'data_items',
    baseMs: 1000,
    baseItems: 50,
    perUnitMs: 200,
    unit: 100,
    capMs: 2500,
  );

  test('data budget grows with data size and stops at the cap', () {
    expect(orders.goodLimit(20), 1000);
    expect(orders.goodLimit(250), 1400);
    expect(orders.goodLimit(2000), 2500);
    expect(orders.poorLimit(250), 2800);
  });

  test('the same time is good for much data and poor for little data', () {
    final big = rateMetrics(
      {'scenario_ms': 2000, 'data_items': 2000},
      budgets: {'scenario_ms': orders},
    );
    final small = rateMetrics(
      {'scenario_ms': 2100, 'data_items': 20},
      budgets: {'scenario_ms': orders},
    );
    expect(big['scenario_ms']!.rating, Rating.good);
    expect(small['scenario_ms']!.rating, Rating.poor);
    expect(big['scenario_ms']!.toJson()['items'], 2000);
  });

  test('bands rate three levels and a budget overrides a band', () {
    final ratings = rateMetrics(
      {'frame_p95_ms': 20, 'scenario_ms': 1200, 'data_items': 50},
      bands: {
        'frame_p95_ms': const Band(16.67, 33),
        'scenario_ms': const Band(500, 800),
      },
      budgets: {'scenario_ms': orders},
    );
    expect(ratings['frame_p95_ms']!.rating, Rating.needsImprovement);
    expect(ratings['scenario_ms']!.rating, Rating.needsImprovement);
    expect(overallRating(ratings.values), Rating.needsImprovement);
  });

  test('config errors are explicit', () {
    expect(() => Band.fromJson('x', [10, 5]), throwsFormatException);
    expect(
      () => DataBudget.fromJson('x', {'base_ms': 1}),
      throwsFormatException,
    );
  });
}
