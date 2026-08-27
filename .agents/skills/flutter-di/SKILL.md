---
name: flutter-di
description: >
  Dependency injection for this base using get_it, injectable, generated
  injection.config.dart, constructor injection, and explicit runtime modules.
  Trigger: dependency injection, get_it, injectable, @injectable,
  @lazySingleton, configureDependencies, injection.config.dart.
---

# Flutter DI — get_it + injectable

## Source of truth

| File | Role |
|---|---|
| `lib/di/injection.dart` | owns `getIt` and `configureDependencies()` |
| `lib/di/register_module.dart` | platform/runtime dependencies and pre-resolved async values |
| `lib/di/injection.config.dart` | generated graph; never edit manually |

## Scopes

| Type | Annotation |
|---|---|
| Screen-scoped Cubit/BLoC | `@injectable` (factory) |
| Stateless UseCase/service | `@lazySingleton` |
| Repository binding | `@LazySingleton(as: XxxRepo)` on implementation |
| DataSource binding | `@LazySingleton(as: XxxDataSource)` on implementation |
| App-lifetime coordinator | `@singleton`, only with an explicit lifetime reason |
| External/async dependency | provider in `@module` / `@preResolve` |

## Required pattern

```dart
@injectable
class ProductCubit extends BaseCubit<ProductState> {
  ProductCubit(this._useCase) : super(ProductState.initial());

  final ProductUseCase _useCase;
}

@LazySingleton(as: ProductRepo)
class ProductRepoImpl implements ProductRepo {
  ProductRepoImpl(this._remoteDataSource);
  final ProductRemoteDataSource _remoteDataSource;
}
```

After annotations or constructor dependencies change, run `derry gen` and
commit the regenerated config.

## Rules

- Do not call `getIt`, `Injector`, or `GetIt.instance` inside a Cubit/BLoC,
  UseCase, repository, or data source.
- Resolution is allowed only in composition roots: bootstrap, route/screen
  builders, and explicit integration adapters.
- Depend on domain interfaces, not data implementations.
- Prefer constructor injection; do not add field injection or hidden globals.
- Cubits/BLoCs are factories unless an app-lifetime state owner is explicitly
  documented and provided with `BlocProvider.value`.
- Never hand-edit `injection.config.dart`.

See `docs/architecture/dependency-injection.md` and
`project-convention/rules/di-scopes.md`.
