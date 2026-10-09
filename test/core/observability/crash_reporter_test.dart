import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late RecordingCrashReporter adapter;
  late Observability observability;

  setUp(() {
    adapter = RecordingCrashReporter();
    observability = Observability(
      crash: adapter,
      analytics: RecordingAnalyticsTracker(),
      performance: RecordingPerformanceTracer(),
      flags: LocalFeatureFlags(debugLogging: false),
      debugLogging: false,
    );
  });

  test('redacts personal data before the error reaches the adapter', () async {
    final stack = StackTrace.current;

    await observability.crash.recordError(
      StateError(
        'GET https://api.example.com/users?phone=0901234567 failed for '
        'ada@example.com with Bearer abc.def-123 and token '
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl',
      ),
      stack,
      fatal: true,
      reason: 'while loading profile of ada@example.com',
    );

    final recorded = adapter.errors.single;
    final message = recorded.error.toString();
    expect(recorded.error, isA<RedactedError>());
    expect((recorded.error as RedactedError).originalType, 'StateError');
    expect(message, contains('https://api.example.com/users?<redacted>'));
    expect(message, contains('Bearer <redacted>'));
    expect(message, isNot(contains('0901234567')));
    expect(message, isNot(contains('ada@example.com')));
    expect(message, isNot(contains('abc.def-123')));
    expect(message, isNot(contains('eyJhbGci')));
    expect(recorded.reason, 'while loading profile of <redacted>');
    expect(recorded.stack, same(stack));
    expect(recorded.fatal, isTrue);
  });

  test('keeps ordinary error text readable', () async {
    await observability.crash.recordError(
      const FormatException('Unexpected character at offset 12'),
      null,
    );

    expect(
      adapter.errors.single.error.toString(),
      'FormatException: Unexpected character at offset 12',
    );
    expect(adapter.errors.single.fatal, isFalse);
  });

  test('redacts breadcrumbs', () async {
    await observability.crash.log('signed in as +84 901 234 567');

    expect(adapter.breadcrumbs.single, 'signed in as <redacted>');
  });

  test('accepts only hashed user identifiers', () async {
    const hashed =
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

    await observability.crash.setUserIdentifier('ada@example.com');
    await observability.crash.setUserIdentifier('0901234567');
    await observability.crash.setUserIdentifier(hashed);
    await observability.crash.setUserIdentifier('');

    expect(adapter.userIds, [hashed, '']);
  });

  test('does not wrap the adapter twice', () {
    final wrapped = Observability(
      crash: observability.crash,
      analytics: observability.analytics,
      performance: observability.performance,
      flags: observability.flags,
    );

    expect(wrapped.crash, same(observability.crash));
    expect(wrapped.analytics, same(observability.analytics));
    expect(wrapped.performance, same(observability.performance));
    expect(wrapped.flags, same(observability.flags));
  });
}
