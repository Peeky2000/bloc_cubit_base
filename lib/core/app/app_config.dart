enum AppEnvironment {
  local,
  development,
  staging,
  production;

  bool get isProduction => this == AppEnvironment.production;
}

/// Immutable runtime configuration selected by a minimal environment entry point.
class AppConfig {
  AppConfig({
    required this.environment,
    required this.baseUri,
    required this.enableNetworkInspector,
  }) {
    _validate();
  }

  factory AppConfig.forEnvironment(AppEnvironment environment) {
    const baseUrlOverride = String.fromEnvironment('API_BASE_URL');
    final defaultBaseUrl = switch (environment) {
      AppEnvironment.local => 'http://localhost:3000',
      AppEnvironment.development => 'https://api.dev.example.com',
      AppEnvironment.staging => 'https://api.staging.example.com',
      AppEnvironment.production => 'https://api.example.com',
    };
    const inspectorOverride = String.fromEnvironment(
      'ENABLE_NETWORK_INSPECTOR',
    );

    return AppConfig(
      environment: environment,
      baseUri: Uri.parse(
        baseUrlOverride.isEmpty ? defaultBaseUrl : baseUrlOverride,
      ),
      enableNetworkInspector: _parseInspectorOverride(
        inspectorOverride,
        defaultValue: !environment.isProduction,
      ),
    );
  }

  final AppEnvironment environment;
  final Uri baseUri;
  final bool enableNetworkInspector;

  String get baseUrl => baseUri.toString();

  static bool _parseInspectorOverride(
    String value, {
    required bool defaultValue,
  }) {
    if (value.isEmpty) {
      return defaultValue;
    }
    return switch (value.toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw ArgumentError.value(
        value,
        'ENABLE_NETWORK_INSPECTOR',
        'Expected true or false.',
      ),
    };
  }

  void _validate() {
    if (!baseUri.hasScheme || !baseUri.hasAuthority) {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'A base URL must include an HTTP(S) scheme and host.',
      );
    }
    if (baseUri.scheme != 'http' && baseUri.scheme != 'https') {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'Only HTTP(S) base URLs are supported.',
      );
    }
    if (environment.isProduction && baseUri.scheme != 'https') {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'Production requires HTTPS.',
      );
    }
    if (environment.isProduction && enableNetworkInspector) {
      throw ArgumentError(
        'The network inspector cannot be enabled in production.',
      );
    }
  }
}
