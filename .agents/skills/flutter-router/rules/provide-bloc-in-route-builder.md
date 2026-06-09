# Rule: Provide BLoC/Cubit Inside Route Builder, Not Globally

**Why:** `BlocProvider` both creates and disposes a BLoC/Cubit. When provided inside a route's
`builder`, the lifecycle is tied to the screen — the BLoC is created fresh when the user
navigates in and disposed when they navigate away. When provided at the app root or in
a shell widget that outlives routes, the BLoC is never disposed and never starts fresh:
the same stale state persists across all navigations to that screen.

---

## ❌ Bad

```dart
// At app root — BLoC lives forever, state shared across all routes
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProductCubit>()), // ❌ app-lifetime scope
        BlocProvider(create: (_) => getIt<CartCubit>()),    // ❌ unless truly needed app-wide
        BlocProvider(create: (_) => getIt<ProfileCubit>()), // ❌
      ],
      child: MaterialApp.router(routerConfig: getIt<AppRouter>().router),
    );
  }
}

// In the shell scaffold — BLoC shared across all tabs
class MainScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductCubit>(), // ❌ shared by every tab in the shell
      child: Scaffold(
        body: child,
        bottomNavigationBar: ...,
      ),
    );
  }
}

// Consequence:
// 1. Navigate to /products → loads → ProductLoaded([...])
// 2. Navigate to /cart (different tab)
// 3. Navigate back to /products
// 4. Cubit is the same object — still in ProductLoaded, no fresh fetch
// 5. User sees stale data until they manually refresh
```

---

## ✅ Good

```dart
// Each route creates its own scoped BLoC — fresh on every navigation
GoRoute(
  path: '/products',
  name: RouteNames.products,
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProductCubit>()..loadProducts(), // ✅ fresh each time
    child: const ProductListPage(),
  ),
)

GoRoute(
  path: ':id', // nested inside /products
  name: RouteNames.productDetail,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return BlocProvider(
      create: (_) => getIt<ProductDetailCubit>()..load(id), // ✅ new instance, correct ID
      child: ProductDetailPage(productId: id),
    );
  },
)
```

---

## Exception: BLoCs that are genuinely global

A BLoC belongs at the app root only when its state is needed outside of any single screen —
typically to drive routing decisions or to feed widgets in the app shell.

```dart
// ✅ AuthBloc at root — the router's redirect depends on it
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
    ),
    // ✅ CartBadgeCubit at root — the nav bar badge reads it from any tab
    BlocProvider(create: (_) => getIt<CartBadgeCubit>()..load()),
  ],
  child: MaterialApp.router(routerConfig: getIt<AppRouter>().router),
)
```

The test: if removing it from the root would break the auth guard or the nav bar,
it belongs at the root. Otherwise, scope it to its route.
