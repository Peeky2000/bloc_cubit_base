# Rule: Register External Libraries via @module

**Why:** You can't add `@injectable` or `@singleton` to classes you don't own —
`Dio`, `SharedPreferences`, `FlutterSecureStorage`, `Hive`. They have no source file
you can annotate. Manually calling `getIt.registerSingleton(...)` in `main.dart` works
at runtime but bypasses injectable's code generation entirely: the dependency graph is
no longer tracked, constructor injection stops working for anything that depends on
these types, and `injection.config.dart` has no knowledge of them. `@module` is the
correct mechanism — it lets injectable see and wire these deps as part of the
generated graph.

---

## ❌ Bad

```dart
// Manually registering in main.dart — breaks injectable's dependency graph
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ❌ Registered outside injectable — not in injection.config.dart
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ❌ Same problem for Dio
  getIt.registerSingleton<Dio>(
    Dio(BaseOptions(baseUrl: 'https://api.example.com')),
  );

  await configureDependencies(); // too late — graph is already polluted
  runApp(const App());
}

// Now injectable can't resolve constructors that take Dio or SharedPreferences
// because it doesn't know about the manually registered instances
```

---

## ✅ Good

```dart
// All external deps declared in @module classes — fully tracked by injectable
@module
abstract class NetworkModule {
  @singleton
  Dio dio(AuthInterceptor interceptor) => Dio(
    BaseOptions(baseUrl: AppConstants.baseUrl),
  )..interceptors.add(interceptor); // ✅ AuthInterceptor also injected by the graph
}

@module
abstract class StorageModule {
  @preResolve  // awaited — SharedPreferences.getInstance() is async
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}

@module
abstract class HiveModule {
  @preResolve  // awaited — Hive.initFlutter() must complete before any box opens
  @singleton
  Future<HiveInterface> get hive async {
    await Hive.initFlutter();
    return Hive;
  }
}

// main.dart — one call, modules auto-discovered by build_runner
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(); // ✅ modules included in injection.config.dart
  runApp(const App());
}
```

---

## @preResolve — what it does

Without `@preResolve`, injectable registers async factories lazily — the `Future` is
stored, not awaited. Any class that depends on `SharedPreferences` would receive a
`Future<SharedPreferences>`, not a `SharedPreferences`. `@preResolve` tells injectable
to `await` that future during `configureDependencies()` so the resolved value is available
synchronously to all dependents.

```dart
// ❌ Without @preResolve — injected as Future<SharedPreferences>
@singleton
Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

// ✅ With @preResolve — injected as SharedPreferences (already resolved)
@preResolve
@singleton
Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
```
