import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:bloc_cubit_base/core/network/network_inspector.dart';
import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/local/session_expiry_coordinator.dart';
import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/domain/repositories/app_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/app_use_case.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

late AppConfig _runtimeAppConfig;

void setRuntimeAppConfig(AppConfig config) {
  _runtimeAppConfig = config;
}

@module
abstract class RegisterModule {
  @singleton
  AppConfig get appConfig => _runtimeAppConfig;

  @preResolve
  Future<SharedPreferences> get preferences => SharedPreferences.getInstance();

  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  AppUseCase appUseCase(AppRepo appRepo) => AppUseCase(appRepo);

  @lazySingleton
  AuthUseCase authUseCase(
    AuthRepo authRepo,
    SessionRepo sessionRepo,
    PhoneVerificationRepo phoneVerificationRepo,
  ) => AuthUseCase(authRepo, sessionRepo, phoneVerificationRepo);

  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @preResolve
  Future<TokenProvider> tokenProvider(
    FlutterSecureStorage secureStorage,
    SharedPreferences preferences,
  ) => TokenProvider(secureStorage, preferences).init();

  @lazySingleton
  NetworkInspector networkInspector(AppConfig config) => NetworkInspector(
    enabled: config.enableNetworkInspector,
    navigatorKey: SLIRouting.key,
  );

  /// Local, debug-only diagnostics unless `AppConfig.observabilityEnabled`
  /// is true and remote adapters are passed here. A fork with Firebase adds
  /// `remote: createFirebaseObservability`; see
  /// docs/guides/enable-version-health.md.
  @lazySingleton
  Observability observability(AppConfig config) =>
      Observability.select(enabled: config.observabilityEnabled);

  @lazySingleton
  CrashReporter crashReporter(Observability observability) =>
      observability.crash;

  @lazySingleton
  AnalyticsTracker analyticsTracker(Observability observability) =>
      observability.analytics;

  @lazySingleton
  PerformanceTracer performanceTracer(Observability observability) =>
      observability.performance;

  @lazySingleton
  FeatureFlags featureFlags(Observability observability) => observability.flags;

  @preResolve
  @Singleton(dispose: disposeNetworkChecker)
  Future<NetworkChecker> networkChecker() async {
    final checker = NetworkChecker();
    await checker.init();
    return checker;
  }

  @lazySingleton
  ApiHandler apiHandler(
    AppConfig config,
    TokenProvider tokenProvider,
    NetworkChecker networkChecker,
    NetworkInspector networkInspector,
    SessionExpiryCoordinator sessionExpiryCoordinator,
  ) => ApiClient(
    baseUrl: config.baseUrl,
    tokenProvider: tokenProvider,
    networkChecker: networkChecker,
    networkInspector: networkInspector,
    sessionExpiryCoordinator: sessionExpiryCoordinator,
  );
}

Future<void> disposeNetworkChecker(NetworkChecker checker) => checker.dispose();
