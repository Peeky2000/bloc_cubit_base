import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:bloc_cubit_base/core/network/network_inspector.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
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

  @preResolve
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
  ) => ApiClient(
    baseUrl: config.baseUrl,
    tokenProvider: tokenProvider,
    networkChecker: networkChecker,
    networkInspector: networkInspector,
  );
}
