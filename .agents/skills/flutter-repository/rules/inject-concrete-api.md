# Rule: Inject Concrete API Class and DAO

**Why:** In the simplified architecture, there are no abstract DataSource interfaces.
Repository constructor takes concrete API classes and DAOs directly. The API classes
(Retrofit-generated) and DAOs (Drift-generated) are already well-defined contracts
that don't need an extra abstraction layer.

---

## Bad

```dart
// Unnecessary abstract interface wrapping a Retrofit class
abstract class ProductRemoteDataSource {
  Future<List<Product>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  // just delegates to Retrofit — pointless indirection
}

@LazySingleton()
class ProductRepository {
  ProductRepository(this._remote); // depends on abstract interface

  final ProductRemoteDataSource _remote;
}
```

---

## Good

```dart
@LazySingleton()
class ProductRepository {
  ProductRepository(this._remoteApi, this._productDao);

  final ProductRemoteApi _remoteApi;   // concrete Retrofit-generated API class
  final ProductDao _productDao;         // concrete Drift DAO class
}
```

DI registration is straightforward — no `as:` parameter needed:

```dart
// injectable resolves this automatically:
// ProductRemoteApi is registered as @lazySingleton in the API module
// ProductDao is provided by the Drift database module
```

For testing, use `mocktail` to mock the concrete classes:

```dart
class MockProductRemoteApi extends Mock implements ProductRemoteApi {}
class MockProductDao extends Mock implements ProductDao {}

// Test setup
final repo = ProductRepository(
  MockProductRemoteApi(),
  MockProductDao(),
);
```
