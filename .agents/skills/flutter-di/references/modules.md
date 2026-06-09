# Registering External Libraries — @module

Use `@module` for any dependency you don't own — Dio, SharedPreferences, Hive, Retrofit impls.
You can't annotate their constructors directly, so you declare a module class that tells
injectable how to create and wire them. See `rules/external-libs-use-module.md` for the reasoning.

---

## Network module

```dart
// core/di/modules/network_module.dart
@module
abstract class NetworkModule {
  @singleton
  Dio dio(AuthInterceptor authInterceptor) {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )..interceptors.addAll([
      authInterceptor,
      LogInterceptor(responseBody: true),
    ]);
  }
}
```

---

## Storage module

```dart
// core/di/modules/storage_module.dart
@module
abstract class StorageModule {
  @preResolve  // async — awaited during configureDependencies()
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}
```

---

## Hive module

```dart
// core/di/modules/hive_module.dart
@module
abstract class HiveModule {
  @preResolve  // must complete before any DataSource opens a Hive box
  @singleton
  Future<HiveInterface> get hive async {
    await Hive.initFlutter();
    // Register TypeAdapters here if using typed boxes
    // Hive.registerAdapter(ProductModelAdapter());
    return Hive;
  }
}
```

---

## Retrofit DataSource module

Retrofit generates classes via factory constructors — can't annotate them directly:

```dart
// core/di/modules/datasource_module.dart
@module
abstract class DataSourceModule {
  @singleton
  AuthRemoteDataSource authRemoteDataSource(Dio dio) =>
      AuthRemoteDataSourceImpl(dio, baseUrl: AppConstants.baseUrl);

  @singleton
  ProductRemoteDataSource productRemoteDataSource(Dio dio) =>
      ProductRemoteDataSourceImpl(dio);

  @singleton
  OrderRemoteDataSource orderRemoteDataSource(Dio dio) =>
      OrderRemoteDataSourceImpl(dio);
}
```

---

## @preResolve — when to use it

Add `@preResolve` only when the provider is async (`Future<T>`).
injectable will `await` all `@preResolve` deps before completing `configureDependencies()`.

| Dep | Needs @preResolve? |
|---|---|
| `SharedPreferences.getInstance()` | ✅ Yes — async factory |
| `Hive.initFlutter()` | ✅ Yes — async init |
| `FlutterSecureStorage()` | ❌ No — sync constructor |
| `Dio(...)` | ❌ No — sync constructor |