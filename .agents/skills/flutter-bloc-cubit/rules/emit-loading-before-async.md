# Rule: Emit Loading State Before Every Async Call

**Why:** Without a loading state, the UI stays visually frozen in whatever state it was in —
showing stale data, an empty screen, or nothing at all — while the async work runs.
The user has no feedback that anything is happening. Emitting loading first gives
the UI a clear signal to show a spinner or skeleton immediately.

---

## ❌ Bad

```dart
class ProductCubit extends Cubit<ProductState> {
  Future<void> loadProducts() async {
    // ❌ No loading emitted — UI shows stale products (or initial empty state)
    //    for however long the network call takes
    try {
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed'));
    }
  }

  Future<void> deleteProduct(String id) async {
    // ❌ No loading — user taps delete, nothing visible happens,
    //    they tap again (double-delete), then the list finally refreshes
    await _repo.deleteProduct(id);
    final products = await _repo.getProducts();
    emit(ProductState.loaded(products));
  }

  Future<void> submitForm(String title, String body) async {
    // ❌ Button stays tappable, no spinner — user submits multiple times
    await _repo.createPost(title: title, body: body);
    emit(const ProductState.loaded([]));
  }
}
```

---

## ✅ Good

```dart
class ProductCubit extends Cubit<ProductState> {
  Future<void> loadProducts() async {
    emit(const ProductState.loading()); // ✅ UI shows shimmer immediately
    try {
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed to load products'));
    } on NetworkException {
      emit(const ProductState.error('No internet connection'));
    }
  }

  Future<void> deleteProduct(String id) async {
    emit(const ProductState.loading()); // ✅ UI shows spinner, button is gone
    try {
      await _repo.deleteProduct(id);
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed to delete'));
    }
  }

  Future<void> submitForm(String title, String body) async {
    emit(const ProductState.loading()); // ✅ form replaced with spinner
    try {
      await _repo.createPost(title: title, body: body);
      emit(const ProductState.loaded([]));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed to submit'));
    }
  }
}
```

---

## Exception: synchronous local operations

Skip loading only when the operation is instant and doesn't touch the network:

```dart
// ✅ No loading needed — synchronous, in-memory, zero latency
void filterByCategory(String categoryId) {
  final current = state;
  if (current is! ProductLoaded) return;
  final filtered = current.products
      .where((p) => p.categoryId == categoryId)
      .toList();
  emit(ProductState.loaded(filtered));
}

void toggleSortOrder() {
  final current = state;
  if (current is! ProductLoaded) return;
  emit(ProductState.loaded(current.products.reversed.toList()));
}
```
