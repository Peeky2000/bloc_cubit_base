import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:bloc_cubit_base/core/routing/route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late RecordingAnalyticsTracker adapter;
  late GlobalKey<NavigatorState> navigatorKey;

  Future<void> pumpApp(WidgetTester tester, SLIRouteObserver observer) =>
      tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          initialRoute: '/',
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Text(settings.name ?? ''),
          ),
        ),
      );

  setUp(() {
    adapter = RecordingAnalyticsTracker();
    navigatorKey = GlobalKey<NavigatorState>();
  });

  testWidgets('reports screen views on push, pop and replace', (tester) async {
    final analytics = Observability(
      crash: RecordingCrashReporter(),
      analytics: adapter,
      performance: RecordingPerformanceTracer(),
      flags: LocalFeatureFlags(debugLogging: false),
      debugLogging: false,
    ).analytics;
    await pumpApp(
      tester,
      SLIRouteObserver(RoutingCache(), analytics: analytics),
    );

    navigatorKey.currentState!.pushNamed('/orders?phone=0901234567');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushReplacementNamed('/profile');
    await tester.pumpAndSettle();

    expect(adapter.screens, ['/', '/orders', '/', '/profile']);
  });

  testWidgets('reports the screen left on top after a route is removed', (
    tester,
  ) async {
    await pumpApp(tester, SLIRouteObserver(RoutingCache(), analytics: adapter));

    navigatorKey.currentState!.pushNamed('/orders');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushNamedAndRemoveUntil('/home', (_) => false);
    await tester.pumpAndSettle();

    expect(adapter.screens, ['/', '/orders', '/home']);
  });

  testWidgets('ignores dialogs and keeps the page as the current screen', (
    tester,
  ) async {
    await pumpApp(tester, SLIRouteObserver(RoutingCache(), analytics: adapter));

    showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(adapter.screens, ['/']);
  });

  testWidgets('without a tracker navigation is not reported', (tester) async {
    final routing = RoutingCache();
    await pumpApp(tester, SLIRouteObserver(routing));

    navigatorKey.currentState!.pushNamed('/orders');
    await tester.pumpAndSettle();

    expect(routing.current, '/orders');
    expect(adapter.screens, isEmpty);
  });

  testWidgets('navigation keeps working when the tracker fails', (
    tester,
  ) async {
    final routing = RoutingCache();
    await pumpApp(
      tester,
      SLIRouteObserver(routing, analytics: ThrowingAdapters()),
    );

    navigatorKey.currentState!.pushNamed('/orders');
    await tester.pumpAndSettle();

    expect(routing.current, '/orders');
    expect(tester.takeException(), isNull);
  });
}
