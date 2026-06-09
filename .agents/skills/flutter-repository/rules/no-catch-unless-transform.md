# Rule: Don't Catch Unless You're Transforming

**Why:** BLoC is the designated error handler — it catches exceptions and emits the correct
error state so the UI can react. If Repository catches an exception without rethrowing,
BLoC never sees it and the UI gets stuck. Repository should only catch when it needs to
*change* the exception type or implement a cache fallback strategy.

---

## Bad

```dart
class AuthRepository {
  Future<User> login(String email, String password) async {
    try {
      return await _remoteApi.login(email, password);
    } catch (e) {
      // Catching just to log — adds noise, BLoC still can't react meaningfully
      debugPrint('Login failed: $e');
      rethrow;
    }
  }
}

class ProductRepository {
  Future<List<Product>> getProducts() async {
    try {
      return await _remoteApi.getProducts();
    } on ServerException {
      // Silently returning empty list — BLoC thinks the call succeeded
      // UI shows an empty state instead of an error state
      return [];
    }
  }
}
```

---

## Good

```dart
class AuthRepository {
  Future<User> login(String email, String password) async {
    // No try/catch — ServerException / NetworkException bubble up to BLoC
    return await _remoteApi.login(email, password);
  }
}

class ProductRepository {
  Future<List<Product>> getProducts() async {
    try {
      final products = await _remoteApi.getProducts();
      await _productDao.insertAll(products.map(productModelToCompanion).toList());
      return products;
    } on NetworkException {
      // Cache fallback — Repository owns this strategy
      final cached = await _productDao.getAll();
      if (cached.isEmpty) rethrow; // no fallback available — let BLoC show error
      return cached.map(productRowToModel).toList();
    }
    // ServerException is NOT caught here — BLoC handles it
  }

  Future<UserProfile> getProfile() async {
    try {
      return await _remoteApi.getProfile();
    } on DioException catch (e) {
      // Transform-only catch — changes type so the router can redirect to login
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      rethrow; // anything else still bubbles up
    }
  }
}
```

---

## When it's OK to catch in Repository

| Situation | Action |
|---|---|
| Network down, cache available | Catch `NetworkException` → return cached data |
| Network down, cache empty | Catch `NetworkException` → `rethrow` |
| 401 Unauthorized | Catch `DioException` → `throw UnauthorizedException()` |
| Any other error | Do NOT catch — let BLoC handle it |
| Background refresh failure | `onError: (_) {}` inside `.then()` only |
