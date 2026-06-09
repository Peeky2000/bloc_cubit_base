# Cache Strategies

## Decision table

| Data characteristic | Strategy |
|---|---|
| Changes frequently (feed, cart, user profile) | Remote-first |
| Changes rarely (categories, config, country list) | Cache-first |
| UX-critical, latency must be near-zero | Stale-while-revalidate |
| Write operations (create, update, delete) | No cache — remote only |

---

## 1. Remote-first

Always fetch from the network. On `NetworkException`, fall back to cached data.
Update cache on every successful fetch.

```dart
Future<List<Product>> getProducts() async {
  try {
    final products = await _remoteApi.getProducts();
    await _productDao.insertAll(products.map(productModelToCompanion).toList());
    return products;
  } on NetworkException {
    final cached = await _productDao.getAll();
    if (cached.isEmpty) rethrow; // no cache to fall back to — let BLoC handle it
    return cached.map(productRowToModel).toList();
  }
}
```

---

## 2. Cache-first

Return cached data immediately if available.
Hit the network only when the cache is empty (cold start or after `clearCache()`).

```dart
Future<List<Category>> getCategories() async {
  final cached = await _categoryDao.getAll();
  if (cached.isNotEmpty) {
    return cached.map(categoryRowToModel).toList();
  }
  // cache empty — must wait for remote
  final categories = await _remoteApi.getCategories();
  await _categoryDao.insertAll(categories.map(categoryModelToCompanion).toList());
  return categories;
}
```

---

## 3. Stale-while-revalidate

Return cached data immediately for instant UX.
Refresh cache in the background (fire-and-forget) so the next call gets fresher data.

```dart
Future<List<Product>> getProducts() async {
  final cached = await _productDao.getAll();
  if (cached.isNotEmpty) {
    // return stale data now, refresh silently in the background
    _remoteApi.getProducts().then(
      (products) => _productDao.insertAll(products.map(productModelToCompanion).toList()),
      onError: (_) {}, // swallow background refresh errors — stale data is acceptable
    );
    return cached.map(productRowToModel).toList();
  }
  // no cache yet — must wait for the first remote fetch
  final products = await _remoteApi.getProducts();
  await _productDao.insertAll(products.map(productModelToCompanion).toList());
  return products;
}
```

---

## Error handling per strategy

| Situation | Action |
|---|---|
| Remote fails, cache available | Return cache (remote-first / SWR) |
| Remote fails, cache empty | `rethrow` — BLoC shows error state |
| Background refresh fails (SWR) | Swallow with `onError: (_) {}` |
| 401 Unauthorized | Catch → throw `UnauthorizedException` for the router |
| Any other error | `rethrow` — let BLoC handle it |

```dart
// 401 transform — the one case where Repository catches to change type
Future<UserProfile> getProfile() async {
  try {
    return await _remoteApi.getProfile();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) throw UnauthorizedException();
    rethrow;
  }
}
```
