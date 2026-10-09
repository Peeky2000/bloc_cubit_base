import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _flag = FeatureFlag('kill_switch', true);

Future<void> _exercise(Observability observability) async {
  await observability.crash.recordError(_Unprintable(), StackTrace.current);
  await observability.crash.recordError('plain', null, fatal: true);
  await observability.crash.log('note for 0901234567');
  await observability.crash.setUserIdentifier('not-a-hash');
  await observability.analytics.screenView('');
  await observability.analytics.screenView('/home');
  await observability.analytics.event('opened', params: {'n': 1});
  await observability.analytics.event('bad name!');
  final trace = observability.performance.start('cold_start')
    ..setAttribute('k', 'v');
  await trace.stop();
  await trace.stop();
  await observability.performance.start('bad name!').stop();
  expect(observability.flags.value(_flag), isTrue);
  await observability.flags.refresh();
}

final class _Unprintable {
  @override
  String toString() => throw StateError('cannot print');
}

void main() {
  for (final debugLogging in [true, false]) {
    test('local implementations never throw (debug: $debugLogging)', () async {
      final sink = LogSink();

      await _exercise(
        Observability.local(log: sink.call, debugLogging: debugLogging),
      );

      expect(sink.lines, debugLogging ? isNotEmpty : isEmpty);
    });
  }

  test('local diagnostics are redacted', () async {
    final sink = LogSink();
    final observability = Observability.local(
      log: sink.call,
      debugLogging: true,
    );

    await observability.crash.recordError(Exception('ada@example.com'), null);
    await observability.crash.log('call 0901234567');

    expect(sink.lines.join('\n'), isNot(contains('ada@example.com')));
    expect(sink.lines.join('\n'), isNot(contains('0901234567')));
  });

  test('a failing log sink never escapes', () async {
    void broken(String message, {Object? error, StackTrace? stackTrace}) =>
        throw StateError('console gone');

    await _exercise(Observability.local(log: broken, debugLogging: true));
  });

  test('throwing adapters never reach the caller', () async {
    for (final throwOnStart in [true, false]) {
      final adapter = ThrowingAdapters(throwOnStart: throwOnStart);
      await _exercise(
        Observability(
          crash: adapter,
          analytics: adapter,
          performance: adapter,
          flags: adapter,
          debugLogging: false,
        ),
      );
    }
  });

  group('Observability.select', () {
    test('stays local when disabled, even with remote adapters', () async {
      final remote = RecordingAnalyticsTracker();
      final observability = Observability.select(
        enabled: false,
        debugLogging: false,
        remote: () => Observability(
          crash: RecordingCrashReporter(),
          analytics: remote,
          performance: RecordingPerformanceTracer(),
          flags: LocalFeatureFlags(debugLogging: false),
        ),
      );

      await observability.analytics.screenView('/home');

      expect(remote.screens, isEmpty);
    });

    test('uses remote adapters when enabled', () async {
      final remote = RecordingAnalyticsTracker();
      final observability = Observability.select(
        enabled: true,
        debugLogging: false,
        remote: () => Observability(
          crash: RecordingCrashReporter(),
          analytics: remote,
          performance: RecordingPerformanceTracer(),
          flags: LocalFeatureFlags(debugLogging: false),
        ),
      );

      await observability.analytics.screenView('/home');

      expect(remote.screens, ['/home']);
    });

    test('falls back to local when remote setup throws', () async {
      final sink = LogSink();
      final observability = Observability.select(
        enabled: true,
        log: sink.call,
        debugLogging: true,
        remote: () => throw StateError('no Firebase app'),
      );

      await _exercise(observability);
      expect(sink.lines.first, contains('using local diagnostics'));
    });

    test('falls back to local when enabled without adapters', () async {
      await _exercise(Observability.select(enabled: true, debugLogging: false));
    });
  });
}
