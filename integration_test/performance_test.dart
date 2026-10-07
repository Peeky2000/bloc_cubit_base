import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'performance/measure_scenario.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('template home first render example', (tester) async {
    await measureScenario(tester, binding, () async {
      await tester.pumpWidget(const MaterialApp(home: HomePageScreen()));
      await tester.pumpAndSettle();
    });
  });
}
