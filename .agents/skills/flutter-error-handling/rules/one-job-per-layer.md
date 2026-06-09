# Rule: Each layer has exactly one error job

## Why

When multiple layers both transform and catch exceptions, it becomes impossible to reason about where an error is handled, and errors get swallowed silently.

## The contract

| Layer | Error job | What it must NOT do |
|---|---|---|
| `DioInterceptor` | Transform `DioException` → `AppException` subtype | Catch and swallow; log to UI |
| `DataSource` | Throw without catching (or rethrow if transforming type) | Return fallback values on error |
| `Repository` | Rethrow OR implement cache fallback strategy | Catch just to log; emit UI state |
| `BLoC / Cubit` | Catch typed exceptions, emit error state | Let raw exceptions reach UI |
| `UI (Page)` | Render error state or show snackbar | Catch exceptions directly |

## ❌ Bad — multiple layers catching the same error

```dart
// DataSource swallows and returns empty
class ProductDataSourceImpl {
  Future<List<ProductModel>> getProducts() async {
    try {
      return await _dio.get('/products');
    } catch (e) {
      return []; // ❌ swallows — Repository and BLoC never see the error
    }
  }
}

// Repository also catches as safety net
class ProductRepositoryImpl {
  Future<List<Product>> getProducts() async {
    try {
      return (await _remote.getProducts()).map((m) => m.toEntity()).toList();
    } catch (e) {
      return []; // ❌ double-catch — now definitely silent
    }
  }
}
```

## ✅ Good — single responsibility per layer

```dart
// Interceptor transforms
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    throw _mapToAppException(err); // ✅ transforms only
  }
}

// DataSource: no try/catch — just calls Dio
class ProductDataSourceImpl {
  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get('/products'); // ✅ throws on error, that's correct
    return (response.data as List).map((e) => ProductModel.fromJson(e)).toList();
  }
}

// Repository: only catches for cache fallback
class ProductRepositoryImpl {
  Future<List<Product>> getProducts() async {
    try {
      final models = await _remote.getProducts();
      await _local.cacheProducts(models);
      return models.map((m) => m.toEntity()).toList();
    } on NetworkException {
      final cached = await _local.getCachedProducts(); // ✅ cache fallback is repo's job
      if (cached.isEmpty) rethrow;
      return cached.map((m) => m.toEntity()).toList();
    }
    // ServerException is NOT caught here — BLoC handles it
  }
}

// BLoC: the final catcher
Future<void> loadProducts() async {
  emit(const ProductState.loading());
  try {
    final products = await _repository.getProducts();
    emit(ProductState.loaded(products));
  } on NetworkException {
    emit(const ProductState.error('No internet connection')); // ✅ only place that emits error state
  } on ServerException catch (e) {
    emit(ProductState.error(e.message ?? 'Failed to load products'));
  }
}
```
