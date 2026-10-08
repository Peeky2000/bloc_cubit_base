import 'dart:async';

import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:bloc_cubit_base/di/injection.config.dart';
import 'package:bloc_cubit_base/di/register_module.dart';

final GetIt getIt = GetIt.instance;

typedef DependencyGraphInitializer = FutureOr<GetIt> Function(GetIt container);

@InjectableInit(initializerName: 'init', preferRelativeImports: true)
Future<GetIt> configureDependencies(
  AppConfig config, {
  bool reset = false,
  DependencyGraphInitializer? initializeGraph,
}) async {
  if (reset) {
    await getIt.reset();
  }
  setRuntimeAppConfig(config);
  return await (initializeGraph ?? (container) => container.init())(getIt);
}

/// The app's dependency-injection entry point for composition roots.
///
/// Route builders, `MainApp`, `bootstrap` and DI modules resolve objects with
/// `Injector.getIt.get<T>()`. Feature classes (Cubit/BLoC, use cases,
/// repositories, data sources, widgets) never use it: they receive their
/// dependencies through constructors. See ADR-0011.
abstract final class Injector {
  static GetIt get getIt => GetIt.instance;

  static Future<void> reset() => getIt.reset();
}
