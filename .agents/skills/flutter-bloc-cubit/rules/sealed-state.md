# Rule: State Must Be a Sealed Class

**Why:** Flag-based state (`bool isLoading`, `String? error`) can represent impossible
combinations — e.g. `isLoading: true` and `error: 'something'` at the same time.
Sealed classes make every state a distinct, self-contained type. The compiler
enforces exhaustive handling in the UI: if you add a new state, every unhandled
`switch` site becomes a compile error instead of a silent runtime bug.

---

## ❌ Bad

```dart
// Flag-based state — impossible combinations are representable
class ProductState {
  final bool isLoading;
  final List<Product> products;
  final String? error;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.error,
  });

  ProductState copyWith({bool? isLoading, List<Product>? products, String? error}) =>
      ProductState(
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        error: error ?? this.error,
      );
}

// Cubit emitting impossible combination by accident
emit(state.copyWith(isLoading: true, error: 'oops')); // ❌ invalid state, compiles fine

// UI must manually decide which flag wins
Widget build(BuildContext context) {
  final state = context.watch<ProductCubit>().state;
  if (state.isLoading) return const Spinner();          // checked first
  if (state.error != null) return Text(state.error!);  // what if both are true?
  if (state.products.isEmpty) return const Empty();    // is this initial or loaded-empty?
  return ProductList(state.products);
}
```

---

## ✅ Good

```dart
// Sealed class — each state is a distinct, self-contained type
@freezed
sealed class ProductState with _$ProductState {
  const factory ProductState.initial() = ProductInitial;
  const factory ProductState.loading() = ProductLoading;
  const factory ProductState.loaded(List<Product> products) = ProductLoaded;
  const factory ProductState.error(String message) = ProductError;
}

// Cubit: only one valid state at a time
emit(const ProductState.loading());        // ✅ unambiguous
emit(ProductState.loaded(products));       // ✅ carries its own data
emit(ProductState.error('Network error')); // ✅ can't also be loading

// UI: exhaustive switch — compiler catches missing cases
BlocBuilder<ProductCubit, ProductState>(
  builder: (context, state) => switch (state) {
    ProductInitial()               => const SizedBox.shrink(),
    ProductLoading()               => const ShimmerList(),
    ProductLoaded(:final products) => ProductListView(products: products),
    ProductError(:final message)   => ErrorView(message: message),
    // Forget to add ProductLoadingMore here? → compile error, not a runtime blank screen
  },
)
```

---

## Comparison

| | Flag-based | Sealed class |
|---|---|---|
| Invalid states | Possible, compiles fine | Impossible by construction |
| UI exhaustiveness | Manual `if/else` chains | Compiler-enforced `switch` |
| Adding a new state | Silent — UI ignores it | Compile error at every unhandled `switch` |
| Data per state | Shared fields on the class | Each variant carries exactly what it needs |
