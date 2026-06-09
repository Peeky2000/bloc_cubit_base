# Repository — Concrete Class

## Naming conventions

| Pattern | Example |
|---|---|
| Class name | `ProductRepository` (no `Impl` suffix) |
| File name | `product_repository.dart` |
| Method — fetch list | `getProducts()` |
| Method — fetch one | `getProductById(String id)` |
| Method — create | `createProduct(Product product)` |
| Method — delete | `deleteProduct(String id)` |
| Method — boolean check | `isAuthenticated()` |

---

## Concrete repository

Location: `shared/repositories/sales/product_repository.dart`

```dart
@LazySingleton()
class ProductRepository {
  ProductRepository(this._remoteApi, this._productDao);

  final ProductRemoteApi _remoteApi;
  final ProductDao _productDao;

  Future<List<Product>> getProducts({int page = 1, int limit = 20}) async {
    final cached = await _productDao.getAll();
    if (cached.isNotEmpty) {
      return cached.map(productRowToModel).toList();
    }
    return _remoteApi.getProducts(page, limit);
  }

  Future<Product> getProductById(String id) async {
    final row = await _productDao.getById(id);
    if (row != null) return productRowToModel(row);
    return _remoteApi.getProductById(id);
  }
}
```

**Key points:**
- No abstract interface — just a concrete class
- No `Impl` suffix — just `ProductRepository`
- DI: `@LazySingleton()` (no `as:` parameter needed)
- Returns Model directly (the unified class)
- Uses mapper functions from `core/database/mappers/` to convert Drift rows to Model
- Method names reflect business intent, not HTTP verbs (`getProducts` not `fetchApiProducts`)

---

## Input / Output

| | Input | Output |
|---|---|---|
| **From BLoC** | Primitive or Model (unified class) | — |
| **To BLoC** | — | `Future<Model>` or `Future<List<Model>>` |
| **To API** | Primitive or Model | — |
| **From API** | Model | — |
| **To DAO** | Drift row / companion | — |
| **From DAO** | Drift row | — |
