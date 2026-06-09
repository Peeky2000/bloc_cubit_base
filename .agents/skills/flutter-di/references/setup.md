# DI Setup — get_it + injectable

## pubspec.yaml

```yaml
dependencies:
  get_it: ^7.6.4
  injectable: ^2.3.2

dev_dependencies:
  injectable_generator: ^2.4.1
  build_runner: ^2.4.8
```

---

## Folder structure

```
core/di/
├── injection.dart            ← entry point
├── injection.config.dart     ← generated — commit to git
└── modules/
    ├── network_module.dart
    ├── storage_module.dart
    ├── hive_module.dart
    └── datasource_module.dart
```

---

## injection.dart — entry point

```dart
// core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String environment = 'prod'}) async =>
    getIt.init(environment: environment);
```

---

## main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies(
    environment: const String.fromEnvironment('ENV', defaultValue: 'prod'),
  );

  runApp(const App());
}
```

---

## Running code generation

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# During active development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Run again whenever you add or modify `@injectable`, `@singleton`, or `@module`.

---

## Environments — dev vs prod

```dart
// core/config/api_config.dart
abstract class ApiConfig {
  String get baseUrl;
}

@dev
@Singleton(as: ApiConfig)
class DevApiConfig implements ApiConfig {
  @override
  String get baseUrl => 'https://api-dev.example.com';
}

@prod
@Singleton(as: ApiConfig)
class ProdApiConfig implements ApiConfig {
  @override
  String get baseUrl => 'https://api.example.com';
}
```

Pass the environment at launch:

```bash
flutter run --dart-define=ENV=dev
flutter run --dart-define=ENV=prod
```