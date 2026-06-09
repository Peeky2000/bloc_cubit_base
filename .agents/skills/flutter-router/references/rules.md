# Router — Rules, Naming & Checklist

## RouteNames constants

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

## Naming conventions

| Pattern | Example |
|---|---|
| Route name | lowercase-kebab: `'product-detail'` |
| Path | `/products/:id` |
| Feature routes variable | `_authRoutes`, `_productRoutes` |
| Router class | `AppRouter` |
| Routes file | `auth_routes.dart`, `product_routes.dart` |

## Checklist

- [ ] `AppRouter` registered as `@singleton` in DI
- [ ] `GoRouterRefreshStream` listens to the auth BLoC stream
- [ ] `redirect` function handles the auth guard
- [ ] Each feature has its own routes file
- [ ] BLoC/Cubit provided inside route `builder`, not globally
- [ ] `context.go()` for tab switches, `context.push()` for detail screens
- [ ] All route names defined in `RouteNames` constants
- [ ] `extra` not used for deep-link routes
- [ ] Nested routes use relative paths (`:id`, not `/products/:id`)
