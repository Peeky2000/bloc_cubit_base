import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart' as driver;

Future<void> main() async {
  await driver.integrationDriver(
    responseDataCallback: (data) async {
      final performance = data?['performance'];
      final diagnosis = data?['diagnosis'];
      if (performance == null && diagnosis == null) {
        throw StateError('Integration test returned no performance metrics.');
      }
      // Keep each marker on one line so the runner can parse exact JSON.
      if (performance != null) {
        // ignore: avoid_print
        print('PERF_RESULT:${jsonEncode(performance)}');
      }
      if (diagnosis != null) {
        // ignore: avoid_print
        print('PERF_DIAGNOSIS:${jsonEncode(diagnosis)}');
      }
    },
  );
}
