import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:delivery_go/core/common/enum.dart';

class AppConfig {
  final Environment _environment;

  Map<String, dynamic> _config = {};

  String get baseUrl => _config[_Config.BASE_URL];

  Environment get env => _environment;

  AppConfig(Environment environment) : _environment = environment;

  Future<void> setup() async {
    await dotenv.load(fileName: '.env');
    switch (_environment) {
      case Environment.LOCAL:
        _config = _Config().localConstants;
        break;
      case Environment.DEV:
        _config = _Config().devConstants;
        break;
      case Environment.STAGING:
        _config = _Config().stagingConstants;
        break;
      case Environment.PROD:
        _config = _Config().prodConstants;
        break;
    }
  }
}

class _Config {
  static const BASE_URL = 'BASE_URL';

  Map<String, dynamic> get localConstants => {
        BASE_URL: dotenv.env['BASE_URL_LOCAL'] ?? '',
      };

  Map<String, dynamic> get devConstants => {
        BASE_URL: dotenv.env['BASE_URL_DEV'] ?? '',
      };

  Map<String, dynamic> stagingConstants = {
    BASE_URL: dotenv.env['BASE_URL_STAGING'] ?? '',
  };

  Map<String, dynamic> prodConstants = {
    BASE_URL: dotenv.env['BASE_URL_PROD'] ?? '',
  };
}
