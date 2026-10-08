import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late RecordingAnalyticsTracker adapter;
  late AnalyticsTracker analytics;

  setUp(() {
    adapter = RecordingAnalyticsTracker();
    analytics = Observability(
      crash: RecordingCrashReporter(),
      analytics: adapter,
      performance: RecordingPerformanceTracer(),
      flags: LocalFeatureFlags(debugLogging: false),
      debugLogging: false,
    ).analytics;
  });

  test('keeps non-personal primitive parameters', () async {
    await analytics.event(
      'checkout_completed',
      params: {'items': 3, 'total': 12.5, 'express': true, 'method': 'cod'},
    );

    expect(adapter.events.single.$1, 'checkout_completed');
    expect(adapter.events.single.$2, {
      'items': 3,
      'total': 12.5,
      'express': true,
      'method': 'cod',
    });
  });

  test('drops personal keys, personal values and non-primitives', () async {
    await analytics.event(
      'profile_saved',
      params: {
        'email': 'not-an-email-but-key-is-personal',
        'user_id': 'u-1',
        'access_token': 'abc',
        'contact': 'ada@example.com',
        'source': 'https://example.com/p?ref=0901234567',
        'note': '0901234567',
        'tags': const ['a'],
        'ratio': double.nan,
        'bad key': 'x',
        'step': 'review',
      },
    );

    expect(adapter.events.single.$2, {'step': 'review'});
  });

  test('drops events with invalid or reserved names', () async {
    await analytics.event('has space');
    await analytics.event('1starts_with_digit');
    await analytics.event('firebase_custom');
    await analytics.event('a' * 41);

    expect(adapter.events, isEmpty);
  });

  test('limits parameter count and string length', () async {
    await analytics.event(
      'bulk',
      params: {for (var i = 0; i < 30; i++) 'p$i': 'v' * 150},
    );

    final params = adapter.events.single.$2;
    expect(params, hasLength(SanitizingAnalyticsTracker.maxParams));
    expect(
      params.values.every(
        (value) =>
            (value as String).length ==
            SanitizingAnalyticsTracker.maxValueLength,
      ),
      isTrue,
    );
  });

  test('strips query and fragment from screen names', () async {
    await analytics.screenView('/orders?phone=0901234567#top');
    await analytics.screenView('?only=query');

    expect(adapter.screens, ['/orders']);
  });
}
