# Rule: No Business Logic in API

**Why:** API has one job — move data between the app and an external source.
Filtering, sorting, validation, and any decision-making belong in BLoC (user input rules)
or Repository (data strategy). Putting logic here makes it untestable and breaks
the single-responsibility principle.

---

## Bad

```dart
class ProductRemoteApi {
  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/products');
    final all = (response.data as List)
        .map((e) => Product.fromJson(e))
        .toList();

    // Filtering in API — Repository/BLoC never see the full list
    return all.where((p) => p.isActive && p.stock > 0).toList();
  }

  Future<Product> getProductById(String id) async {
    // Input validation in API — this belongs in BLoC
    if (id.isEmpty) throw ArgumentError('ID cannot be empty');

    final response = await _dio.get('/products/$id');
    return Product.fromJson(response.data);
  }
}
```

---

## Good

```dart
// API: maps data, nothing more
@RestApi()
@injectable
abstract class ProductRemoteApi {
  @factoryMethod
  factory ProductRemoteApi(Dio dio) = _ProductRemoteApi;

  @GET('/products')
  Future<List<Product>> getProducts(); // full list returned — callers decide

  @GET('/products/{id}')
  Future<Product> getProductById(@Path('id') String id); // trusts its caller
}

// Filtering belongs in Cubit
void filterActive() {
  final current = state;
  if (current is! ProductLoaded) return;
  final filtered = current.products
      .where((p) => p.isActive && p.stock > 0)
      .toList();
  emit(ProductState.loaded(filtered)); // UI-driven filter in BLoC
}

// Validation belongs in BLoC
Future<void> _onLoad(LoadProductDetail event, Emitter<ProductState> emit) async {
  if (event.id.isEmpty) {        // validation in BLoC
    emit(const ProductState.error('Invalid product ID'));
    return;
  }
  emit(const ProductState.loading());
  final product = await _repo.getProductById(event.id);
  emit(ProductState.loaded([product]));
}
```
