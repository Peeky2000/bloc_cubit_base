# BLoC / Cubit Error Handling

BLoC is the **only layer** that catches exceptions and converts them into UI state.

## Standard Cubit pattern

```dart
Future<void> loadProducts() async {
  emit(const ProductState.loading());
  try {
    final products = await _repository.getProducts();
    emit(ProductState.loaded(products));
  } on NetworkException {
    emit(const ProductState.error('No internet connection'));
  } on ServerException catch (e) {
    emit(ProductState.error(e.message ?? 'Failed to load products'));
  }
  // ✅ Programming errors (NPE, cast) are NOT caught — they crash in dev,
  //    get reported to Crashlytics in prod
}
```

## Standard BLoC pattern

```dart
Future<void> _onLoginPressed(
  LoginPressed event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState.loading());
  try {
    final user = await _repository.login(event.email, event.password);
    emit(AuthState.authenticated(user));
  } on NetworkException {
    emit(const AuthState.error('No internet connection'));
  } on ServerException catch (e) {
    emit(AuthState.error(e.message ?? 'Login failed'));
  } on UnauthorizedException {
    emit(const AuthState.error('Invalid credentials'));
  }
}
```

## Transient action errors (add to cart, delete, submit form)

For one-shot actions where the screen should stay visible after an error, use a separate error field in state rather than replacing the whole state:

```dart
// State has both data and an optional action error
@freezed
sealed class CartState with _$CartState {
  const factory CartState.loaded({
    required List<CartItem> items,
    CartSummary? summary,
    String? actionError,          // ← transient error from add/remove actions
  }) = CartLoaded;

  const factory CartState.loading() = CartLoading;
  const factory CartState.error(String message) = CartError;
}

// Cubit: add to cart — keep existing items visible, show error inline
Future<void> addToCart(Product product) async {
  try {
    await _repository.addToCart(product);
    final items = await _repository.getCart();
    emit(CartState.loaded(items: items));
  } on ServerException catch (e) {
    // ✅ Emit loaded with actionError — cart list stays visible
    final current = state as CartLoaded;
    emit(current.copyWith(actionError: e.message ?? 'Could not add item'));
  } on NetworkException {
    final current = state as CartLoaded;
    emit(current.copyWith(actionError: 'No internet connection'));
  }
}
```

## Exception catch order

Always catch more specific types first:

```dart
// ✅ Specific before general
} on UnauthorizedException {
  ...
} on ServerException catch (e) {
  ...
} on NetworkException {
  ...
}

// ❌ Wrong order — ServerException catches everything before UnauthorizedException
} on ServerException catch (e) {
  ...
} on UnauthorizedException {  // never reached if Unauthorized extends ServerException
  ...
}
```

## What to put in error message

| Source | What to emit |
|---|---|
| `ServerException` with message | `e.message` (already user-safe from API) |
| `ServerException` without message | Generic fallback: `'Something went wrong'` |
| `NetworkException` | `'No internet connection'` |
| `UnauthorizedException` | `'Session expired. Please log in again.'` |
| `CacheException` | `'Could not load saved data'` (not `e.message` — internal detail) |
