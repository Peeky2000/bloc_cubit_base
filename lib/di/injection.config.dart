// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/app/app_config.dart' as _i806;
import '../core/app/app_controller.dart' as _i77;
import '../core/app/app_cubit/app_cubit.dart' as _i688;
import '../core/helper/network/network_checker.dart' as _i484;
import '../core/network/network_inspector.dart' as _i556;
import '../data/datasource/local/app_local_data_source.dart' as _i641;
import '../data/datasource/local/token_provider.dart' as _i508;
import '../data/datasource/local/user_local_data_source.dart' as _i278;
import '../data/datasource/remote/api_client.dart' as _i44;
import '../data/datasource/remote/auth_remote_data_source.dart' as _i519;
import '../data/repositories/app_repo_impl.dart' as _i482;
import '../data/repositories/auth_repo_impl.dart' as _i743;
import '../data/repositories/user_repo_impl.dart' as _i114;
import '../domain/repositories/app_repo.dart' as _i546;
import '../domain/repositories/auth_repo.dart' as _i218;
import '../domain/repositories/user_repo.dart' as _i1042;
import '../domain/use_case/app_use_case.dart' as _i1036;
import '../domain/use_case/auth_use_case.dart' as _i358;
import '../presentation/confirm_information/cubit/confirm_information_cubit.dart'
    as _i453;
import '../presentation/home_page/cubit/home_page_cubit.dart' as _i927;
import '../presentation/reset_password/cubit/reset_password_cubit.dart'
    as _i955;
import '../presentation/sign_in/cubit/sign_in_cubit.dart' as _i805;
import '../presentation/sign_up/cubit/sign_up_cubit.dart' as _i800;
import '../presentation/splash/cubit/splash_cubit.dart' as _i565;
import '../presentation/test/cubit/test_cubit.dart' as _i1002;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.preferences,
      preResolve: true,
    );
    gh.factory<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.factory<_i558.FlutterSecureStorage>(() => registerModule.secureStorage);
    await gh.factoryAsync<_i484.NetworkChecker>(
      () => registerModule.networkChecker(),
      preResolve: true,
    );
    gh.factory<_i927.HomePageCubit>(() => _i927.HomePageCubit());
    gh.factory<_i1002.TestCubit>(() => _i1002.TestCubit());
    gh.singleton<_i77.AppController>(() => _i77.AppController());
    gh.singleton<_i806.AppConfig>(() => registerModule.appConfig);
    gh.lazySingleton<_i278.UserLocalDataSource>(
      () => _i278.UserLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i556.NetworkInspector>(
      () => registerModule.networkInspector(gh<_i806.AppConfig>()),
    );
    gh.lazySingleton<_i641.AppLocalDataSource>(
      () => _i641.AppLocalDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1042.UserRepo>(
      () => _i114.UserRepoImpl(gh<_i278.UserLocalDataSource>()),
    );
    gh.lazySingleton<_i546.AppRepo>(
      () => _i482.AppRepoImpl(gh<_i641.AppLocalDataSource>()),
    );
    await gh.factoryAsync<_i508.TokenProvider>(
      () => registerModule.tokenProvider(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i460.SharedPreferences>(),
      ),
      preResolve: true,
    );
    gh.lazySingleton<_i44.ApiHandler>(
      () => registerModule.apiHandler(
        gh<_i806.AppConfig>(),
        gh<_i508.TokenProvider>(),
        gh<_i484.NetworkChecker>(),
        gh<_i556.NetworkInspector>(),
      ),
    );
    gh.lazySingleton<_i1036.AppUseCase>(
      () => _i1036.AppUseCase(gh<_i546.AppRepo>()),
    );
    gh.lazySingleton<_i519.AuthRemoteDataSource>(
      () => _i519.AuthRemoteDataSourceImpl(gh<_i44.ApiHandler>()),
    );
    gh.singleton<_i688.AppCubit>(() => _i688.AppCubit(gh<_i1036.AppUseCase>()));
    gh.lazySingleton<_i218.AuthRepo>(
      () => _i743.AuthRepoImpl(
        gh<_i519.AuthRemoteDataSource>(),
        gh<_i508.TokenProvider>(),
      ),
    );
    gh.lazySingleton<_i358.AuthUseCase>(
      () => _i358.AuthUseCase(
        gh<_i218.AuthRepo>(),
        gh<_i1042.UserRepo>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i453.ConfirmInformationCubit>(
      () => _i453.ConfirmInformationCubit(
        gh<_i358.AuthUseCase>(),
        gh<_i77.AppController>(),
      ),
    );
    gh.factory<_i955.ResetPasswordCubit>(
      () => _i955.ResetPasswordCubit(
        gh<_i358.AuthUseCase>(),
        gh<_i77.AppController>(),
      ),
    );
    gh.factory<_i805.SignInCubit>(
      () =>
          _i805.SignInCubit(gh<_i358.AuthUseCase>(), gh<_i77.AppController>()),
    );
    gh.factory<_i800.SignUpCubit>(
      () =>
          _i800.SignUpCubit(gh<_i358.AuthUseCase>(), gh<_i77.AppController>()),
    );
    gh.factory<_i565.SplashCubit>(
      () => _i565.SplashCubit(gh<_i358.AuthUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
