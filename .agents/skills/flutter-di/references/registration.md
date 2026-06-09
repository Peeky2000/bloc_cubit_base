# Annotating Classes for DI

## BLoC / Cubit — @injectable (factory)

New instance every time `getIt<ProductCubit>()` is called.
Each route gets isolated state. See `rules/bloc-is-factory.md` for the full reasoning.

```dart
@injectable
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo) : super(const ProductState.initial());

  final ProductRepository _repo; // concrete class — no abstract interface
}

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState.initial()) {
    on<AuthLoginPressed>(_onLogin);
    on<AuthLogoutPressed>(_onLogout);
  }

  final AuthRepository _repo; // concrete class
}
```

---

## Repository — @LazySingleton() (concrete)

One shared instance for the lifetime of the app.
Constructor receives concrete API / DAO classes directly.

```dart
@LazySingleton()
class ProductRepository {
  ProductRepository(this._remoteApi, this._productDao);

  final ProductRemoteApi _remoteApi; // concrete Retrofit API
  final ProductDao _productDao;      // concrete Drift DAO
}
```

---

## Remote API — @injectable + @factoryMethod (Retrofit)

Retrofit generates the implementation. Use `@factoryMethod` on the factory constructor.

```dart
@injectable
@RestApi()
abstract class ProductRemoteApi {
  @factoryMethod
  factory ProductRemoteApi(Dio dio) = _ProductRemoteApi;

  @GET('/products')
  Future<List<ProductModel>> getProducts();
}
```

---

## Local API — @injectable (concrete)

```dart
@injectable
class AuthLocalApi {
  AuthLocalApi(this._storage);
  final FlutterSecureStorage _storage; // registered in StorageModule

  Future<String?> getToken() => _storage.read(key: 'access_token');
  Future<void> saveToken(String token) => _storage.write(key: 'access_token', value: token);
}
```

---

## Using getIt in a route builder

Always provide BLoC/Cubit inside the route `builder`, not at the app root:

```dart
GoRoute(
  path: '/products',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProductCubit>()..loadProducts(), // fresh instance per nav
    child: const ProductListPage(),
  ),
)

GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return BlocProvider(
      create: (_) => getIt<ProductDetailCubit>()..load(id),
      child: ProductDetailPage(productId: id),
    );
  },
)
```

---

## Using getIt outside the widget tree

For interceptors, background services, or any non-widget code:

```dart
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final authRepo = getIt<AuthRepository>();
      try {
        await authRepo.refreshToken();
        // retry the original request...
      } catch (_) {
        getIt<AuthBloc>().add(const AuthEvent.logoutPressed());
      }
    }
    handler.next(err);
  }
}
```

---

## Naming conventions

| Element | Example |
|---|---|
| Entry point file | `injection.dart` |
| Generated file | `injection.config.dart` |
| Module class | `NetworkModule`, `StorageModule` |
| Global instance | `getIt` — keep this exact name |