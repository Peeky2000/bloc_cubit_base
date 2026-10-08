import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'measure_scenario.dart';
import 'support/perf_app.dart';

/// Real app start against the real backend of the configured flavor:
/// bootstrap, splash, session restore or test-account sign-in, and the first
/// signed-in screen with real data.
///
/// Missing PERF_USERNAME/PERF_PASSWORD fail the run instead of measuring the
/// sign-in screen. App-specific screens come from `support/perf_app_adapter.dart`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app start to first signed-in screen', (tester) async {
    await measureScenario(tester, binding, () async {
      await pumpLoggedInApp(tester);
      // Keep producing frames while the first screen loads real data.
      await pumpFor(tester, const Duration(seconds: 2));
    });
  });
}
