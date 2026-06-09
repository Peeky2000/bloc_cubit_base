---
name: flutter-di
description: >
  Guide for Dependency Injection in this base using get_it with manual registration
  in lib/di/injection.dart (Injector). Use when registering Cubits, UseCases,
  repositories, or data sources. Trigger: "dependency injection", "get_it",
  "Injector", "registerFactory", "setupDomain".
---

# Flutter DI — get_it (manual)

## Entry point

```
lib/di/injection.dart
└── class Injector
    ├── setupEnvironment()
    ├── setupData()
    ├── setupDomain()
    └── setupPresentation()
```

Access: `Injector.getIt.get<T>()`

## Registration guide

| Type | Method | Example |
|------|--------|---------|
| Cubit | `registerFactory` | `registerFactory<SignInCubit>(() => SignInCubit())` |
| UseCase | `registerLazySingleton` | `registerLazySingleton<AuthUseCase>(() => AuthUseCase(getIt(), getIt()))` |
| Repo interface | `registerLazySingleton<AuthRepo>(() => AuthRepoImpl(getIt(), getIt()))` |
| DataSource | `registerLazySingleton` | `registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(getIt()))` |
| ApiHandler | `registerLazySingleton` | `registerLazySingleton<ApiHandler>(() => ApiClient(...))` |

## Rules

- **No** `injectable`, **no** `injection.config.dart`
- Cubits: always **factory**
- Register repo as **interface** type, impl in closure
- Add imports at top of `injection.dart` for new types

## References

| Topic | File |
|-------|------|
| Scopes | `project-convention/rules/di-scopes.md` |
| Full example | `lib/di/injection.dart` |

## Rules files (still valid conceptually)

- `rules/bloc-is-factory.md` — apply as `registerFactory` for Cubits
- `rules/inject-interface-not-impl.md` — register `AuthRepo`, not only `AuthRepoImpl` in getIt type
- Ignore `rules/external-libs-use-module.md` injectable `@module` — register SharedPreferences in `setupData` like existing code
