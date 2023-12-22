import 'package:delivery_go/data/datasource/local/user_local_data_source.dart';
import 'package:delivery_go/data/repositories/user_repo_impl.dart';
import 'package:delivery_go/domain/repositories/user_repo.dart';
import 'package:delivery_go/presentation/confirm_information/cubit/confirm_information_cubit.dart';
import 'package:delivery_go/presentation/home_page/cubit/home_page_cubit.dart';
import 'package:delivery_go/presentation/reset_password/cubit/reset_password_cubit.dart';
import 'package:delivery_go/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:delivery_go/presentation/sign_up/cubit/sign_up_cubit.dart';
import 'package:get_it/get_it.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_go/core/app/app_config.dart';
import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/app/app_cubit/app_cubit.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/core/helper/network/network_checker.dart';
import 'package:delivery_go/data/datasource/local/app_local_data_source.dart';
import 'package:delivery_go/data/datasource/local/auth_local_data_source.dart';
import 'package:delivery_go/data/datasource/local/token_provider.dart';
import 'package:delivery_go/data/datasource/remote/api_client.dart';
import 'package:delivery_go/data/datasource/remote/auth_remote_data_source.dart';
import 'package:delivery_go/data/repositories/app_repo_impl.dart';
import 'package:delivery_go/data/repositories/auth_repo_impl.dart';
import 'package:delivery_go/domain/repositories/app_repo.dart';
import 'package:delivery_go/domain/repositories/auth_repo.dart';
import 'package:delivery_go/domain/use_case/app_use_case.dart';
import 'package:delivery_go/domain/use_case/auth_use_case.dart';
import 'package:delivery_go/presentation/splash/cubit/splash_cubit.dart';

class Injector {
  static final getIt = GetIt.instance..allowReassignment = true;

  static Future<void> setupEnvironment(Environment env) async {
    AppConfig appConfig = AppConfig(env);
    await appConfig.setup();
    getIt.registerLazySingleton<AppConfig>(() => appConfig);
    getIt.registerFactory<AppController>(() => AppController());
  }

  static Future<void> setupData() async {
    NetworkChecker networkChecker = NetworkChecker();
    await networkChecker.init();
    getIt.registerLazySingleton<NetworkChecker>(() => networkChecker);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    // di for local datasource
    getIt
      ..registerLazySingleton<AppLocalDataSource>(
          () => AppLocalDataSource(sharedPreferences))
      ..registerLazySingleton<TokenProvider>(
          () => TokenProvider(sharedPreferences))
      ..registerLazySingleton<AuthLocalDataSource>(
          () => AuthLocalDataSource(sharedPreferences))
      ..registerLazySingleton<UserLocalDataSource>(
          () => UserLocalDataSourceImpl(sharedPreferences));
    // di for remote data source
    getIt
      ..registerLazySingleton<ApiHandler>(() => ApiClient(
          baseUrl: getIt.get<AppConfig>().baseUrl, tokenProvider: getIt()))
      ..registerLazySingleton<AuthRemoteDataSource>(
          () => AuthRemoteDataSourceImpl(getIt()));
  }

  static Future<void> setupDomain() async {
    // di for repositories
    getIt
      ..registerLazySingleton<AppRepo>(() => AppRepoImpl(getIt()))
      ..registerLazySingleton<AuthRepo>(() => AuthRepoImpl(getIt(), getIt()))
      ..registerLazySingleton<UserRepo>(() => UserRepoImpl(getIt()));

    // di for usecase
    getIt
      ..registerLazySingleton<AppUseCase>(() => AppUseCase(getIt()))
      ..registerLazySingleton<AuthUseCase>(() => AuthUseCase(getIt(), getIt()));
  }

  static Future<void> setupPresentation() async {
    getIt
      ..registerLazySingleton<AppCubit>(() => AppCubit())
      ..registerFactory<SplashCubit>(() => SplashCubit())
      ..registerFactory<SignUpCubit>(() => SignUpCubit())
      ..registerFactory<SignInCubit>(() => SignInCubit())
      ..registerFactory<ResetPasswordCubit>(() => ResetPasswordCubit())
      ..registerFactory<ConfirmInformationCubit>(
          () => ConfirmInformationCubit())
      ..registerFactory<HomePageCubit>(() => HomePageCubit());
  }
}
