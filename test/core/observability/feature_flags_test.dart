import 'dart:async';

import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _newCheckout = FeatureFlag('new_checkout_enabled', false);
const _pageSize = FeatureFlag('orders_page_size', 20);
const _ratio = FeatureFlag('sample_ratio', 0.1);
const _banner = FeatureFlag('banner_text', 'hello');

final class _RemoteFlags implements FeatureFlags {
  _RemoteFlags(this._refresh, [this.values = const {}]);

  final Future<bool> Function() _refresh;
  final Map<String, Object> values;

  @override
  T value<T extends Object>(FeatureFlag<T> flag) {
    final value = values[flag.key];
    return value is T ? value : flag.defaultValue;
  }

  @override
  Future<bool> refresh() => _refresh();
}

FeatureFlags _wrap(FeatureFlags flags, {Duration? timeout}) => Observability(
  crash: RecordingCrashReporter(),
  analytics: RecordingAnalyticsTracker(),
  performance: RecordingPerformanceTracer(),
  flags: flags,
  debugLogging: false,
  flagRefreshTimeout: timeout ?? const Duration(seconds: 10),
).flags;

void main() {
  test('local flags return typed in-code defaults', () async {
    final flags = Observability.local(debugLogging: false).flags;

    expect(await flags.refresh(), isFalse);
    expect(flags.value(_newCheckout), isFalse);
    expect(flags.value(_pageSize), 20);
    expect(flags.value(_ratio), 0.1);
    expect(flags.value(_banner), 'hello');
  });

  test('local overrides apply only when the type matches', () {
    final flags = Observability.local(
      debugLogging: false,
      flagOverrides: {'new_checkout_enabled': true, 'orders_page_size': 'ten'},
    ).flags;

    expect(flags.value(_newCheckout), isTrue);
    expect(flags.value(_pageSize), 20);
  });

  test('a failing refresh returns false and keeps defaults', () async {
    final flags = _wrap(ThrowingAdapters());

    expect(await flags.refresh(), isFalse);
    expect(flags.value(_newCheckout), isFalse);
    expect(flags.value(_pageSize), 20);
  });

  test('a refresh that never answers times out to the defaults', () async {
    final never = Completer<bool>();
    final flags = _wrap(
      _RemoteFlags(() => never.future),
      timeout: const Duration(milliseconds: 10),
    );

    expect(await flags.refresh(), isFalse);
    expect(flags.value(_pageSize), 20);
  });

  test('a successful refresh exposes remote values', () async {
    final flags = _wrap(
      _RemoteFlags(() async => true, {'orders_page_size': 50}),
    );

    expect(await flags.refresh(), isTrue);
    expect(flags.value(_pageSize), 50);
    expect(flags.value(_newCheckout), isFalse);
  });
}
