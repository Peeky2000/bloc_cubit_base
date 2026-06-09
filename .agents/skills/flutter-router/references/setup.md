# Router Setup — AppRouter + Auth Guard

## Folder structure

```
core/router/
├── app_router.dart
├── go_router_refresh_stream.dart
├── route_names.dart
└── routes/
    ├── auth_routes.dart
    └── main_routes.dart
```

---

## GoRouterRefreshStream

Bridges a BLoC stream to a `ChangeNotifier` so go_router re-evaluates
the `redirect` function on every auth state change.

```dart
// core/router/go_router_refresh_stream.dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

---

## AppRouter

```dart
// core/router/app_router.dart
@singleton
class AppRouter {
  AppRouter(this._authBloc);
  final AuthBloc _authBloc;

  late final router = GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: _redirect,
    routes: [
      ..._authRoutes,   // from auth_routes.dart
      ..._mainRoutes,   // from main_routes.dart (ShellRoute)
    ],
  );

  // Called on every navigation event and on every auth state change
  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _authBloc.state is AuthAuthenticated;
    final isOnAuthScreen = state.matchedLocation.startsWith('/auth');

    if (!isAuthenticated && !isOnAuthScreen) return '/auth/login';
    if (isAuthenticated && isOnAuthScreen) return '/home';
    return null; // no redirect needed
  }
}
```

---

## App widget

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC is truly global — the router depends on it
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: getIt<AppRouter>().router,
        theme: AppTheme.light,
      ),
    );
  }
}
```

---

## RouteNames constants

All route names in one place — prevents typos and makes refactoring safe:

```dart
// core/router/route_names.dart
abstract class RouteNames {
  static const login = 'login';
  static const register = 'register';
  static const home = 'home';
  static const products = 'products';
  static const productDetail = 'product-detail';
  static const cart = 'cart';
  static const checkout = 'checkout';
  static const profile = 'profile';
}
```

---

## Naming conventions

| Element | Example |
|---|---|
| Router class | `AppRouter` |
| Route name constant | `RouteNames.productDetail` |
| Route name value | lowercase-kebab: `'product-detail'` |
| Path | `/products/:id` |
| Feature routes variable | `_authRoutes`, `_productRoutes` |
| Feature routes file | `auth_routes.dart`, `product_routes.dart` |