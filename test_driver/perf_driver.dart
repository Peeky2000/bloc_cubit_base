import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart' as driver;

Future<void> main() async {
  await driver.integrationDriver(
    responseDataCallback: (data) async {
      final performance = data?['performance'];
      if (performance == null) {
        throw StateError('Integration test returned no performance metrics.');
      }
      // Keep the marker on one line so the opt-in runner can parse exact JSON.
      // ignore: avoid_print
      print('PERF_RESULT:${jsonEncode(performance)}');
    },
  );
}
