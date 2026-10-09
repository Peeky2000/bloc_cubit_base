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
    this.observabilityEnabled = false,
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
    const observabilityOverride = String.fromEnvironment(
      'ENABLE_OBSERVABILITY',
    );

    return AppConfig(
      environment: environment,
      baseUri: Uri.parse(
        baseUrlOverride.isEmpty ? defaultBaseUrl : baseUrlOverride,
      ),
      enableNetworkInspector: _parseBoolOverride(
        inspectorOverride,
        name: 'ENABLE_NETWORK_INSPECTOR',
        defaultValue: !environment.isProduction,
      ),
      observabilityEnabled: _parseBoolOverride(
        observabilityOverride,
        name: 'ENABLE_OBSERVABILITY',
        // Off everywhere in the base. A fork with Firebase adapters turns it
        // on per environment here or with --dart-define.
        defaultValue: false,
      ),
    );
  }

  final AppEnvironment environment;
  final Uri baseUri;
  final bool enableNetworkInspector;

  /// Sends crash reports, analytics, traces and remote flags through the
  /// remote adapters registered in DI. When false, or when no adapters are
  /// registered, everything stays on the device.
  final bool observabilityEnabled;

  String get baseUrl => baseUri.toString();

  static bool _parseBoolOverride(
    String value, {
    required String name,
    required bool defaultValue,
  }) {
    if (value.isEmpty) {
      return defaultValue;
    }
    return switch (value.toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw ArgumentError.value(value, name, 'Expected true or false.'),
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
