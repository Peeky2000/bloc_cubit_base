# Dependency Injection Scopes

All registration lives in `lib/di/injection.dart` inside class `Injector`.

## Setup phases (call order in `main_*.dart`)

| Method | Registers |
|--------|-----------|
| `setupEnvironment` | `AppConfig`, `AppController` |
| `setupData` | `NetworkChecker`, local/remote data sources, `ApiHandler` |
| `setupDomain` | Repository impls (as interfaces), **UseCases** |
| `setupPresentation` | `AppCubit`, feature **Cubits** |

## Scope table

| Class type | Registration | Scope |
|------------|--------------|-------|
| Cubit | `registerFactory` | New instance per screen/session |
| UseCase | `registerLazySingleton` | One per app |
| Repository (interface) | `registerLazySingleton<AuthRepo>(() => AuthRepoImpl(...))` | One per app |
| DataSource / ApiHandler | `registerLazySingleton` | One per app |
| AppCubit | `registerLazySingleton` | App-wide |
| AppConfig / AppController | lazy singleton / factory | Per env |

## Example — adding a new feature Cubit

```dart
// In Injector.setupPresentation()
..registerFactory<ProductCubit>(() => ProductCubit());
```

Register `ProductUseCase` and `ProductRepo` in `setupDomain`, data sources in `setupData`.

## Resolving dependencies

```dart
import 'package:<app>/di/injection.dart';

final authUseCase = Injector.getIt.get<AuthUseCase>();
```

Cubits in this base often resolve via `Injector.getIt` in the constructor body (see `SignInCubit`).

## Rules

- **Never** register Cubits as `registerLazySingleton` (shared state across routes).
- Register **repository interface** type, construct **impl** in the factory closure.
- After adding registrations, no code-gen step — only `flutter analyze`.
