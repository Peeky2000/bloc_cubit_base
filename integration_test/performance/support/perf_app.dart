import 'package:bloc_cubit_base/bootstrap.dart';
import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/core/app/main_app.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';

import 'perf_app_adapter.dart';

/// Credentials of a dedicated performance test account on a real backend.
///
/// The runner passes them with `--dart-define` from environment variables, so
/// they never live in the repo or in reports.
const perfUsername = String.fromEnvironment('PERF_USERNAME');
const perfPassword = String.fromEnvironment('PERF_PASSWORD');

/// Starts the real app through [bootstrap] with production DI, theme,
/// routing, localization, network and the backend of [environment].
///
/// Scenarios use real data. The account and data set must be stable so
/// numbers stay comparable: use a dedicated test account whose data is not
/// edited by hand.
Future<void> pumpPerfApp(
  WidgetTester tester, {
  AppEnvironment environment = AppEnvironment.development,
}) async {
  // bootstrap installs the app's error logger; the test binding must get its
  // own handler back or it reports the change as a test failure.
  final testErrorHandler = FlutterError.onError;
  try {
    await bootstrap(buildMainApp, environment: environment);
  } finally {
    FlutterError.onError = testErrorHandler;
  }
  await tester.pumpAndSettle();
}

/// Opens the app and makes sure the test account is signed in and on the
/// first signed-in screen. App-specific screens and steps come from
/// [perfAppAdapter], so this file never changes when the auth flow does.
Future<void> pumpLoggedInApp(WidgetTester tester) async {
  await pumpPerfApp(tester);
  await pumpUntilFound(
    tester,
    find.byWidgetPredicate(
      (w) => perfAppAdapter.isSignInScreen(w) || perfAppAdapter.isHomeScreen(w),
    ),
  );
  if (find
      .byWidgetPredicate(perfAppAdapter.isSignInScreen)
      .evaluate()
      .isNotEmpty) {
    await logInWithTestAccount(tester);
  }
}

/// Signs in with [perfUsername] and [perfPassword] using the app's own sign-in
/// steps from [perfAppAdapter], then waits for the home screen.
///
/// Fails with a clear message when credentials are missing.
Future<void> logInWithTestAccount(WidgetTester tester) async {
  if (perfUsername.isEmpty || perfPassword.isEmpty) {
    fail(
      'Set PERF_USERNAME and PERF_PASSWORD in the environment for a '
      'dedicated test account. The runner forwards them to the app.',
    );
  }
  await perfAppAdapter.signIn(tester, perfUsername, perfPassword);
  await pumpUntilFound(
    tester,
    find.byWidgetPredicate(perfAppAdapter.isHomeScreen),
  );
}

/// Waits for real async work such as network calls while frames keep being
/// produced, until [finder] appears or [timeout] passes.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Check the backend, network and test account.',
  );
}

/// Pumps frames for a fixed duration so idle animations produce frames.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Scrolls [finder] by [delta] in [steps] drags so the run produces enough
/// frames for stable percentiles.
Future<void> scrollSteps(
  WidgetTester tester,
  Finder finder, {
  Offset delta = const Offset(0, -300),
  int steps = 10,
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.drag(finder, delta);
    await tester.pumpAndSettle();
  }
}
