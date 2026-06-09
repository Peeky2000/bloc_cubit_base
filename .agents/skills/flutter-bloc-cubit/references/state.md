# Defining State with Freezed

## Core rule

Always use `@freezed sealed class`. Never use `bool isLoading`, nullable `String? error`,
or any flag-based approach. See `rules/sealed-state.md` for the full reasoning.

---

## Basic state

```dart
// features/product/presentation/bloc/product_state.dart
part of 'product_cubit.dart';

@freezed
sealed class ProductState with _$ProductState {
  const factory ProductState.initial() = ProductInitial;
  const factory ProductState.loading() = ProductLoading;
  const factory ProductState.loaded(List<Product> products) = ProductLoaded;
  const factory ProductState.error(String message) = ProductError;
}
```

---

## Pagination state

```dart
@freezed
sealed class ProductState with _$ProductState {
  const factory ProductState.initial() = ProductInitial;
  const factory ProductState.loading() = ProductLoading;
  const factory ProductState.loaded({
    required List<Product> products,
    required bool hasMore,
    @Default(1) int currentPage,
  }) = ProductLoaded;
  const factory ProductState.loadingMore(List<Product> products) = ProductLoadingMore;
  const factory ProductState.error(String message) = ProductError;
}
```

---

## Auth state (multiple variants carrying data)

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}
```

---

## Consuming State in UI — exhaustive pattern matching

```dart
BlocBuilder<ProductCubit, ProductState>(
  builder: (context, state) => switch (state) {
    ProductInitial()                      => const SizedBox.shrink(),
    ProductLoading()                      => const ShimmerList(),
    ProductLoaded(:final products)        => ProductListView(products: products),
    ProductLoadingMore(:final products)   => ProductListView(products: products, showFooterSpinner: true),
    ProductError(:final message)          => ErrorView(message: message),
  },
)
```

The compiler enforces exhaustive handling — adding a new state variant causes
a compile error at every `switch` site that hasn't handled it yet.

---

## Naming conventions

| Element | Example |
|---|---|
| State sealed class | `ProductState`, `AuthState` |
| State variant | `ProductLoaded`, `AuthAuthenticated` |
| State file | `product_state.dart` |
| Part declaration | `part of 'product_cubit.dart';` |
