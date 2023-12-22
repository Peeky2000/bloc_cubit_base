import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('Change Cubit: ${bloc.runtimeType}, $change', name: 'Giaohang247');
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('Create Cubit: ${bloc.runtimeType}', name: 'Giaohang247');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('Close Cubit: ${bloc.runtimeType}', name: 'Giaohang247');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('Error Cubit: ${bloc.runtimeType}, $error, $stackTrace',
        name: 'Giaohang247');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder,
    {required Environment environment}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      await Firebase.initializeApp();
      await Injector.setupEnvironment(environment);
      await Injector.setupData();
      await Injector.setupDomain();
      await Injector.setupPresentation();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarBrightness: Brightness.light));
      runApp(await builder());
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}
