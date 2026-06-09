# Feature Routes — GoRoute, Nested Routes, Params

## Basic feature routes file

Each feature owns its routes in `core/router/routes/<feature>_routes.dart`.
BLoC/Cubit is always provided inside the `builder` — never globally.

```dart
// core/router/routes/auth_routes.dart
final _authRoutes = [
  GoRoute(
    path: '/auth',
    redirect: (_, __) => '/auth/login', // redirect bare /auth to /auth/login
  ),
  GoRoute(
    path: '/auth/login',
    name: RouteNames.login,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const LoginPage(),
    ),
  ),
  GoRoute(
    path: '/auth/register',
    name: RouteNames.register,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<RegisterCubit>(),
      child: const RegisterPage(),
    ),
  ),
];
```

---

## Nested routes

Child routes use a **relative path** (`:id`, not `/products/:id`).
The resolved path is parent + child: `/products` + `:id` = `/products/:id`.

```dart
// core/router/routes/product_routes.dart
final _productRoutes = [
  GoRoute(
    path: '/products',
    name: RouteNames.products,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ProductCubit>()..loadProducts(),
      child: const ProductListPage(),
    ),
    routes: [
      GoRoute(
        path: ':id',                      // relative — resolves to /products/:id
        name: RouteNames.productDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => getIt<ProductDetailCubit>()..load(id),
            child: ProductDetailPage(productId: id),
          );
        },
      ),
    ],
  ),
];
```

---

## Passing params

### Path params — for required identifiers

```dart
// Navigate
context.push('/products/abc123');
context.pushNamed(RouteNames.productDetail, pathParameters: {'id': 'abc123'});

// Receive
final id = state.pathParameters['id']!;
```

### Query params — for optional filters

```dart
// Navigate
context.pushNamed(
  RouteNames.products,
  queryParameters: {'category': 'electronics', 'sort': 'price'},
);

// Receive
final category = state.uri.queryParameters['category'];
final sort = state.uri.queryParameters['sort'];
```

### extra — in-app only, not deep-link safe

```dart
// Navigate — only acceptable for non-deep-linkable screens
context.push('/checkout/confirm', extra: cartSummary);

// Receive
final summary = state.extra as CartSummary?;
```

See `rules/no-extra-for-deep-links.md` for when `extra` is and isn't appropriate.