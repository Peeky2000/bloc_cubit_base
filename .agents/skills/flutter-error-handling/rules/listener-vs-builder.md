# Rule: Use BlocListener for transient errors, BlocBuilder for persistent errors

## Why

- `BlocBuilder` re-renders the widget tree — if you show a snackbar inside `builder`, it triggers on every rebuild, not just when the error first appears
- `BlocListener` fires once per state transition — correct for one-shot side effects (snackbar, dialog, navigation)
- Mixing them causes duplicate snackbars or snackbars that never appear

## ❌ Bad

```dart
// Showing snackbar inside BlocBuilder — fires on EVERY rebuild
BlocBuilder<CartCubit, CartState>(
  builder: (context, state) {
    if (state is CartError) {
      // ❌ Called every time widget rebuilds, not just on error transition
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
    return CartBody(...);
  },
)

// Full-page ErrorState for a transient action error
BlocBuilder<CartCubit, CartState>(
  builder: (context, state) => switch (state) {
    CartError(:final message) => ErrorState(   // ❌ replaces cart list for a simple add-to-cart failure
        message: message,
        onRetry: ...,
      ),
    CartLoaded() => CartBody(...),
    _ => const SizedBox(),
  },
)
```

## ✅ Good

```dart
// Persistent error (page failed to load) → BlocBuilder + ErrorState
BlocBuilder<ProductCubit, ProductState>(
  builder: (context, state) => switch (state) {
    ProductLoading()               => const SkeletonList(),
    ProductLoaded(:final products) => ProductGrid(products: products),
    ProductError(:final message)   => ErrorState(    // ✅ persistent — whole page failed
        message: message,
        onRetry: () => context.read<ProductCubit>().loadProducts(),
      ),
    _ => const SizedBox(),
  },
)

// Transient error (action failed) → BlocListener + Snackbar
BlocListener<CartCubit, CartState>(
  listenWhen: (prev, curr) =>
    curr is CartLoaded && curr.actionError != null &&
    curr.actionError != (prev is CartLoaded ? prev.actionError : null),
  listener: (context, state) {
    if (state is CartLoaded && state.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(   // ✅ fires once per error
        SnackBar(content: Text(state.actionError!)),
      );
    }
  },
  child: BlocBuilder<CartCubit, CartState>(         // ✅ builder still renders cart normally
    builder: (context, state) => CartBody(state: state),
  ),
)
```

## Quick reference

| Error type | Example | Use |
|---|---|---|
| Page failed to load | Products list empty because API failed | `BlocBuilder` → `ErrorState` widget |
| Action failed, screen stays | Add to cart failed | `BlocListener` → `SnackBar` |
| Blocking error requiring acknowledgement | Payment failed | `BlocListener` → `showDialog` |
| Session expired | 401 anywhere | `BlocListener` (root) → `context.go('/login')` |
