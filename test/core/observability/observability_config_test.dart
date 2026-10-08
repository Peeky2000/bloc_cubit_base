import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('observability is off by default in every environment', () {
    for (final environment in AppEnvironment.values) {
      expect(
        AppConfig.forEnvironment(environment).observabilityEnabled,
        isFalse,
        reason: '$environment',
      );
    }
  });
}
