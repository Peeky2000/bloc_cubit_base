# ShellRoute — Bottom Navigation Bar

`ShellRoute` wraps a set of routes with a shared shell widget (the scaffold + nav bar).
The `child` parameter is the currently active route's page — it changes on every tab switch.

---

## Routes

```dart
// core/router/routes/main_routes.dart
final _mainRoutes = [
  ShellRoute(
    builder: (context, state, child) => MainScaffold(child: child),
    routes: [
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<HomeCubit>()..load(),
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/products',
        name: RouteNames.products,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ProductCubit>()..loadProducts(),
          child: const ProductListPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
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
      GoRoute(
        path: '/cart',
        name: RouteNames.cart,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CartCubit>()..load(),
          child: const CartPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ProfileCubit>()..load(),
          child: const ProfilePage(),
        ),
      ),
    ],
  ),
];
```

---

## MainScaffold

`_currentIndex` reads the current location to highlight the correct tab.
`_onTap` uses `context.go()` — tabs replace the stack, not push onto it.

```dart
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/products')) return 1;
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/products');
      case 2: context.go('/cart');
      case 3: context.go('/profile');
    }
  }
}
```

---

## How nested routes interact with ShellRoute

Routes nested inside a ShellRoute's `routes` list still show the shell (nav bar).
Routes defined *outside* the ShellRoute (e.g. `/checkout`, `/auth/login`) show
fullscreen — no nav bar.

```
ShellRoute (MainScaffold with nav bar)
├── /home              → nav bar visible
├── /products          → nav bar visible
│   └── /products/:id  → nav bar visible (nested inside ShellRoute)
├── /cart              → nav bar visible
└── /profile           → nav bar visible

/auth/login            → no nav bar (outside ShellRoute)
/checkout              → no nav bar (outside ShellRoute)
```