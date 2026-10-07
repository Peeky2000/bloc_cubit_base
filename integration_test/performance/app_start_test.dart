import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'measure_scenario.dart';
import 'support/perf_app.dart';

/// Real app start against the real backend of the configured flavor:
/// bootstrap, splash, session restore and the first real screen.
///
/// With PERF_USERNAME/PERF_PASSWORD set, the test account logs in when no
/// session exists, so the measurement ends on Home with real data. Without
/// credentials it ends on the sign-in screen.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app start to first real screen', (tester) async {
    await measureScenario(tester, binding, () async {
      await pumpPerfApp(tester);
      await pumpUntilFound(
        tester,
        find.byWidgetPredicate((w) => w is SignInScreen || w is HomePageScreen),
      );
      final onSignIn = find.byType(SignInScreen).evaluate().isNotEmpty;
      if (onSignIn && perfUsername.isNotEmpty) {
        await logInWithTestAccount(tester);
      }
      // Keep producing frames while the first screen loads real data.
      await pumpFor(tester, const Duration(seconds: 2));
    });
  });
}
