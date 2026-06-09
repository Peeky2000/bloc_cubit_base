# Rule: Don't Use extra for Deep-Linkable Routes

**Why:** `extra` is an in-memory object — it is never serialised into the URL.
When a user opens a deep link (from a push notification, a shared URL, or a browser),
go_router reconstructs the route from the URL alone. At that point, `extra` is `null`.
Any screen that depends on `state.extra` will crash or show an empty state.
Path and query params are part of the URL and survive deep links, app restarts,
and OS-level navigation correctly.

---

## ❌ Bad

```dart
// Passing a full object via extra
void onProductTap(Product product) {
  context.push('/products/${product.id}', extra: product); // ❌
}

// Route depends on extra — breaks silently on deep link
GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final product = state.extra as Product?; // ❌ null when opened via deep link
    if (product == null) {
      // Forced to handle the null case — but now the screen loads with no data
      return const ErrorPage(message: 'Product not found');
    }
    return ProductDetailPage(product: product); // ❌ works in-app, fails on deep link
  },
)

// Also bad: using extra to avoid a fetch
void onOrderTap(Order order) {
  context.push('/orders/${order.id}', extra: order); // ❌
  // Push notification deep link opens /orders/abc123 — extra is null — screen shows nothing
}
```

---

## ✅ Good

```dart
// Only pass the ID — the screen fetches the rest itself
void onProductTap(String productId) {
  context.push('/products/$productId'); // ✅ ID is in the URL
}

// Route owns its data loading — works from deep link and in-app navigation equally
GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!; // ✅ always present — it's in the URL
    return BlocProvider(
      create: (_) => getIt<ProductDetailCubit>()..load(id),
      child: ProductDetailPage(productId: id),
    );
  },
)

// Query params for optional filters — also URL-safe
void onSearchResult(String query, String? category) {
  context.pushNamed(
    RouteNames.products,
    queryParameters: {
      'q': query,
      if (category != null) 'category': category,
    },
  );
}

GoRoute(
  path: '/products',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'];
    final category = state.uri.queryParameters['category'];
    return BlocProvider(
      create: (_) => getIt<ProductCubit>()..search(query: query, category: category),
      child: const ProductListPage(),
    );
  },
)
```

---

## When extra is acceptable

`extra` is safe only for transient, in-app-only flows where deep linking is architecturally
impossible — multi-step wizards, temporary confirmation screens, or data that is meaningless
outside of an active session:

```dart
// ✅ Checkout confirm — never deep-linked, always reached via /cart
context.push('/checkout/confirm', extra: cartSummary);

// ✅ Onboarding step 2 — only ever reached from step 1, never from a URL
context.push('/onboarding/interests', extra: selectedCategories);
```

**Test:** could a push notification or shared link ever point to this screen?
If yes — use path or query params. If no — `extra` is acceptable.
