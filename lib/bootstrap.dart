import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('Change: ${bloc.runtimeType}, $change', name: 'bloc_cubit_base');
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('Create: ${bloc.runtimeType}', name: 'bloc_cubit_base');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('Close: ${bloc.runtimeType}', name: 'bloc_cubit_base');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log(
      'Error: ${bloc.runtimeType}, $error',
      name: 'bloc_cubit_base',
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required AppEnvironment environment,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    final config = AppConfig.forEnvironment(environment);
    await Firebase.initializeApp();
    await configureDependencies(config);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
    );
    runApp(await builder());
  }, (error, stackTrace) => log(error.toString(), stackTrace: stackTrace));
}
