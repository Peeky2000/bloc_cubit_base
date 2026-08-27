import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('creates a non-production environment with inspector enabled', () {
      final config = AppConfig.forEnvironment(AppEnvironment.development);

      expect(config.baseUri.isScheme('https'), isTrue);
      expect(config.enableNetworkInspector, isTrue);
    });

    test('disables inspector in production', () {
      final config = AppConfig.forEnvironment(AppEnvironment.production);

      expect(config.enableNetworkInspector, isFalse);
    });

    test('rejects a malformed base URL', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.development,
          baseUri: Uri.parse('not-a-url'),
          enableNetworkInspector: true,
        ),
        throwsArgumentError,
      );
    });

    test('requires HTTPS in production', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.production,
          baseUri: Uri.parse('http://api.example.com'),
          enableNetworkInspector: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
