import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:bloc_cubit_base/di/injection.config.dart';
import 'package:bloc_cubit_base/di/register_module.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true)
Future<GetIt> configureDependencies(
  AppConfig config, {
  bool reset = false,
}) async {
  if (reset) {
    await getIt.reset();
  }
  setRuntimeAppConfig(config);
  return getIt.init();
}

/// Backward-compatible access for route/widget composition during migration.
///
/// Feature classes must receive dependencies through constructors.
abstract final class Injector {
  static GetIt get getIt => GetIt.instance;

  static Future<void> reset() => getIt.reset();
}
