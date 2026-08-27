import 'package:bloc_cubit_base/bootstrap.dart';
import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/core/app/main_app.dart';

Future<void> main() async {
  await bootstrap(buildMainApp, environment: AppEnvironment.production);
}
