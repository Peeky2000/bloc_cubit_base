# Rule: Catch Specific Exceptions, Not the Base Exception

**Why:** Catching `catch (e)` or `on Exception` swallows *everything* — including
null pointer errors, type cast failures, and assertion errors that are bugs in your
own code. These should crash loudly in development, not be silently swallowed as
"Something went wrong". Specific exception types also let you write tailored
error messages — "No internet connection" is far more useful than a generic fallback.

---

## ❌ Bad

```dart
class ProductCubit extends Cubit<ProductState> {
  Future<void> loadProducts() async {
    emit(const ProductState.loading());
    try {
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } catch (e) {
      // ❌ Catches NPEs, type errors, assertion failures — all hidden as UI errors
      // A bug in _repo.getProducts() will show "Something went wrong" instead of crashing
      emit(const ProductState.error('Something went wrong'));
    }
  }

  Future<void> submitOrder(Order order) async {
    emit(const ProductState.loading());
    try {
      await _repo.submitOrder(order);
      emit(const ProductState.loaded([]));
    } on Exception catch (e) {
      // ❌ on Exception is too broad — still catches programming errors
      emit(ProductState.error(e.toString())); // shows internal exception message to user
    }
  }
}
```

---

## ✅ Good

```dart
class ProductCubit extends Cubit<ProductState> {
  Future<void> loadProducts() async {
    emit(const ProductState.loading());
    try {
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } on ServerException catch (e) {
      // ✅ API-level error — show server's message if available
      emit(ProductState.error(e.message ?? 'Failed to load products'));
    } on NetworkException {
      // ✅ No connectivity — specific user-facing message
      emit(const ProductState.error('No internet connection'));
    }
    // ✅ NullPointerException, CastError, etc. propagate → crash in dev, Crashlytics in prod
  }

  Future<void> loadProfile() async {
    emit(const ProductState.loading());
    try {
      final profile = await _repo.getProfile();
      emit(ProductState.loaded([profile]));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed to load profile'));
    } on NetworkException {
      emit(const ProductState.error('No internet connection'));
    } on UnauthorizedException {
      // ✅ Specific type — router/auth guard reacts to this separately
      emit(const ProductState.error('Session expired. Please log in again.'));
    }
  }
}
```

---

## Exception types to define in `core/errors/exceptions.dart`

```dart
class ServerException implements Exception {
  final int? statusCode;
  final String? message;
  const ServerException({this.statusCode, this.message});
}

class NetworkException implements Exception {
  const NetworkException();
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}
```

---

## When each exception is thrown

| Exception | Thrown by | Meaning |
|---|---|---|
| `ServerException` | Dio interceptor | 4xx / 5xx response from API |
| `NetworkException` | Dio interceptor | No connectivity / timeout |
| `CacheException` | LocalDataSource | Hive / SharedPrefs read-write failure |
| `UnauthorizedException` | Repository | 401 transformed to trigger auth redirect |
