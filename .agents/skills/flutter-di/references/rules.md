# DI — Rules, Environments & Checklist

## Environments (dev / staging / prod)

```dart
// Environment-specific config via @module
@module
abstract class EnvModule {
  @dev
  @singleton
  String get baseUrl => 'https://api-dev.example.com';

  @prod
  @singleton
  String get baseUrl => 'https://api.example.com';
}

// Pass environment when initializing
await configureDependencies(
  environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
);
```

## Naming conventions

| Pattern | Example |
|---|---|
| Module class | `NetworkModule`, `StorageModule` |
| Module file | `network_module.dart` |
| Entry point | `injection.dart` |
| Generated file | `injection.config.dart` |
| Global instance | `getIt` (keep this name — don't rename) |

## Checklist

- [ ] `configureDependencies()` called before `runApp()` in main.dart
- [ ] BLoC/Cubit uses `@injectable` (factory)
- [ ] Repository uses `@LazySingleton()` (no `as:` parameter)
- [ ] Remote API uses `@injectable` + `@factoryMethod` (Retrofit-generated)
- [ ] Local API uses `@injectable` (concrete class)
- [ ] External libs (Dio, SharedPrefs) registered via `@module`
- [ ] `@preResolve` used for async deps (SharedPrefs)
- [ ] Concrete classes injected directly (no abstract interfaces)
- [ ] `build_runner` executed after adding new annotations
- [ ] `injection.config.dart` committed to git
