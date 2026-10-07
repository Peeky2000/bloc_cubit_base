import 'package:bloc_cubit_base/bootstrap.dart';
import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/core/app/main_app.dart';
import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:bloc_cubit_base/widget/delivery_go_button.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/material.dart' show TextField;
import 'package:flutter_test/flutter_test.dart';

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

/// Logs in with the real backend using [perfUsername] and [perfPassword],
/// starting from the sign-in screen, and waits for Home.
///
/// Fails with a clear message when credentials are missing. Session tokens
/// persist in secure storage, so later runs may start already logged in;
/// call this only when the sign-in screen is shown.
Future<void> logInWithTestAccount(WidgetTester tester) async {
  if (perfUsername.isEmpty || perfPassword.isEmpty) {
    fail(
      'Set PERF_USERNAME and PERF_PASSWORD in the environment for a '
      'dedicated test account. The runner forwards them to the app.',
    );
  }
  final fields = find.descendant(
    of: find.byType(SignInScreen),
    matching: find.byType(TextField),
  );
  await pumpUntilFound(tester, fields);
  await tester.enterText(fields.at(0), perfUsername);
  await tester.enterText(fields.at(1), perfPassword);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  final button = find.descendant(
    of: find.byType(SignInScreen),
    matching: find.byType(DeliveryGoButton),
  );
  await tester.tap(button);
  await pumpUntilFound(tester, find.byType(HomePageScreen));
}

/// Opens the app and makes sure the test account is on Home.
Future<void> pumpLoggedInApp(WidgetTester tester) async {
  await pumpPerfApp(tester);
  final signIn = find.byType(SignInScreen);
  await pumpUntilFound(
    tester,
    find.byWidgetPredicate((w) => w is SignInScreen || w is HomePageScreen),
  );
  if (signIn.evaluate().isNotEmpty) await logInWithTestAccount(tester);
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
