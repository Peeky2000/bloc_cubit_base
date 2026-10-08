import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'measure_scenario.dart';
import 'support/perf_app.dart';

/// Real app start against the real backend of the configured flavor:
/// bootstrap, splash, session restore and the first real screen.
///
/// When no session exists, the test account from PERF_USERNAME/PERF_PASSWORD
/// logs in, so the measurement always ends on Home with real data. Missing
/// credentials fail the run instead of measuring the sign-in screen.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app start to first real screen', (tester) async {
    await measureScenario(tester, binding, () async {
      await pumpPerfApp(tester);
      await pumpUntilFound(
        tester,
        find.byWidgetPredicate((w) => w is SignInScreen || w is HomePageScreen),
      );
      if (find.byType(SignInScreen).evaluate().isNotEmpty) {
        // Fails with a clear message when PERF_USERNAME/PERF_PASSWORD are
        // missing, instead of silently measuring the sign-in screen.
        await logInWithTestAccount(tester);
      }
      // Keep producing frames while the first screen loads real data.
      await pumpFor(tester, const Duration(seconds: 2));
    });
  });
}
