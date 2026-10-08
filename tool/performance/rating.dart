/// Data-aware budgets and three-level ratings for performance metrics.
///
/// Pure Dart so it can be unit tested without a device.
library;

enum Rating { good, needsImprovement, poor }

extension RatingLabel on Rating {
  String get label => switch (this) {
    Rating.good => 'GOOD',
    Rating.needsImprovement => 'NEEDS_IMPROVEMENT',
    Rating.poor => 'POOR',
  };
}

/// A latency budget that grows with the amount of data a screen loads.
///
/// `good = baseMs + perUnitMs * max(0, items - baseItems) / unit`, capped at
/// [capMs]. [poorFactor] times the good budget is the poor line. Example for
/// an orders list: 1000 ms for the first 50 orders, +200 ms per 100 more
/// orders, never above 2500 ms.
class DataBudget {
  const DataBudget({
    required this.metric,
    required this.itemsMetric,
    required this.baseMs,
    this.baseItems = 0,
    this.perUnitMs = 0,
    this.unit = 100,
    this.capMs,
    this.poorFactor = 2,
  });

  factory DataBudget.fromJson(String metric, Map<String, dynamic> json) {
    num read(String key, {num? fallback}) {
      final value = json[key] ?? fallback;
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('budget.$metric.$key must be a number >= 0');
      }
      return value;
    }

    final itemsMetric = json['items_metric'];
    if (itemsMetric is! String || itemsMetric.isEmpty) {
      throw FormatException('budget.$metric.items_metric is required');
    }
    final cap = json['cap_ms'];
    if (cap != null && (cap is! num || cap <= 0)) {
      throw FormatException('budget.$metric.cap_ms must be > 0');
    }
    return DataBudget(
      metric: metric,
      itemsMetric: itemsMetric,
      baseMs: read('base_ms'),
      baseItems: read('base_items', fallback: 0),
      perUnitMs: read('per_unit_ms', fallback: 0),
      unit: read('unit', fallback: 100),
      capMs: cap as num?,
      poorFactor: read('poor_factor', fallback: 2),
    );
  }

  final String metric;
  final String itemsMetric;
  final num baseMs;
  final num baseItems;
  final num perUnitMs;
  final num unit;
  final num? capMs;
  final num poorFactor;

  num goodLimit(num items) {
    final extra = items > baseItems ? (items - baseItems) / unit : 0;
    final limit = baseMs + perUnitMs * extra;
    final cap = capMs;
    return cap != null && limit > cap ? cap : limit;
  }

  num poorLimit(num items) => goodLimit(items) * poorFactor;
}

/// Fixed GOOD/POOR lines for a metric; values in between need improvement.
class Band {
  const Band(this.good, this.poor);

  factory Band.fromJson(String metric, Object? json) {
    if (json is! List ||
        json.length != 2 ||
        json.any((v) => v is! num) ||
        (json[0] as num) > (json[1] as num)) {
      throw FormatException(
        'bands.$metric must be [good, poor] with good <= poor',
      );
    }
    return Band(json[0] as num, json[1] as num);
  }

  final num good;
  final num poor;

  Rating rate(num value) => value <= good
      ? Rating.good
      : value <= poor
      ? Rating.needsImprovement
      : Rating.poor;
}

class MetricRating {
  const MetricRating(
    this.metric,
    this.value,
    this.good,
    this.poor,
    this.rating, {
    this.items,
  });

  final String metric;
  final num value;
  final num good;
  final num poor;
  final Rating rating;

  /// Data size the limits were scaled for, when a [DataBudget] applied.
  final num? items;

  Map<String, Object> toJson() => {
    'value': value,
    'good': good,
    'poor': poor,
    'rating': rating.label,
    'items': ?items,
  };
}

/// Rates every metric that has a band or a data budget. A budget wins over a
/// band for the same metric, because it accounts for data size.
Map<String, MetricRating> rateMetrics(
  Map<String, num> summary, {
  Map<String, Band> bands = const {},
  Map<String, DataBudget> budgets = const {},
}) {
  final result = <String, MetricRating>{};
  for (final entry in bands.entries) {
    final value = summary[entry.key];
    if (value == null) continue;
    result[entry.key] = MetricRating(
      entry.key,
      value,
      entry.value.good,
      entry.value.poor,
      entry.value.rate(value),
    );
  }
  for (final budget in budgets.values) {
    final value = summary[budget.metric];
    final items = summary[budget.itemsMetric];
    if (value == null || items == null) continue;
    final band = Band(budget.goodLimit(items), budget.poorLimit(items));
    result[budget.metric] = MetricRating(
      budget.metric,
      value,
      band.good,
      band.poor,
      band.rate(value),
      items: items,
    );
  }
  return result;
}

/// The worst rating, or GOOD when nothing was rated.
Rating overallRating(Iterable<MetricRating> ratings) => ratings.fold(
  Rating.good,
  (worst, r) => r.rating.index > worst.index ? r.rating : worst,
);
