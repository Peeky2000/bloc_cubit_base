# Rule: Inject Concrete Classes Directly

**Why:** This project uses a simplified architecture with no abstract interfaces for
Repository or API classes. BLoC constructors take concrete `ProductRepository`,
Repository constructors take concrete `ProductRemoteApi` and `ProductDao`.
There is no `Impl` suffix — the class IS the implementation. DI still provides
value by centralising object creation and managing lifetimes (factory vs singleton).

---

## ❌ Bad — old pattern with abstract interfaces

```dart
// WRONG — no abstract interfaces in this project
abstract class ProductRepository { ... }

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository { ... }

@injectable
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo);
  final ProductRepository _repo; // ❌ abstract interface — we don't use these
}
```

---

## ✅ Good — concrete classes everywhere

```dart
// Repository — concrete class, no interface, no Impl suffix
@LazySingleton()
class ProductRepository {
  ProductRepository(this._remoteApi, this._productDao);

  final ProductRemoteApi _remoteApi; // ✅ concrete Retrofit API
  final ProductDao _productDao;      // ✅ concrete Drift DAO

  Future<List<ProductModel>> getProducts() async {
    final products = await _remoteApi.getProducts();
    await _productDao.upsertAll(products);
    return products;
  }
}

// BLoC — takes concrete Repository
@injectable
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo) : super(const ProductState.initial());

  final ProductRepository _repo; // ✅ concrete class
}
```

injectable resolves the concrete class automatically because of `@LazySingleton()`
on `ProductRepository`:

```
getIt<ProductRepository>()  →  resolves to  →  ProductRepository (singleton)
getIt<ProductCubit>()       →  injects       →  ProductRepository instance
```

---

## Testing: use mocktail for mocking concrete classes

```dart
class MockProductRepository extends Mock implements ProductRepository {}

// Test setup
final mockRepo = MockProductRepository();
final cubit = ProductCubit(mockRepo);

when(() => mockRepo.getProducts()).thenAnswer(
  (_) async => [ProductModel(id: '1', name: 'Test', price: 9.99)],
);

blocTest<ProductCubit, ProductState>(
  'emits loaded state on success',
  build: () => cubit,
  act: (c) => c.loadProducts(),
  expect: () => [
    const ProductState.loading(),
    isA<ProductLoaded>(),
  ],
);
```
