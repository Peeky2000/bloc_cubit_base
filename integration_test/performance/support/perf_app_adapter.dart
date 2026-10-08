import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:bloc_cubit_base/widget/delivery_go_button.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_test/flutter_test.dart';

/// The only performance file that knows this app's auth screens.
///
/// When a fork replaces the sample sign-in or home screen, update this file
/// and nothing else under `integration_test/performance/`. Agents writing
/// scenarios must not import feature screens for sign-in; they call
/// `pumpLoggedInApp` instead.
abstract interface class PerfAppAdapter {
  bool isSignInScreen(Widget widget);

  bool isHomeScreen(Widget widget);

  /// Performs the app's own sign-in steps on the sign-in screen.
  Future<void> signIn(WidgetTester tester, String username, String password);
}

const PerfAppAdapter perfAppAdapter = _SampleAuthAdapter();

/// Adapter for the base template's sample phone/password sign-in.
class _SampleAuthAdapter implements PerfAppAdapter {
  const _SampleAuthAdapter();

  @override
  bool isSignInScreen(Widget widget) => widget is SignInScreen;

  @override
  bool isHomeScreen(Widget widget) => widget is HomePageScreen;

  @override
  Future<void> signIn(
    WidgetTester tester,
    String username,
    String password,
  ) async {
    final fields = find.descendant(
      of: find.byType(SignInScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), username);
    await tester.enterText(fields.at(1), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SignInScreen),
        matching: find.byType(DeliveryGoButton),
      ),
    );
  }
}
