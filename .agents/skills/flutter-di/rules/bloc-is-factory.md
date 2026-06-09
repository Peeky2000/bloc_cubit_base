# Rule: BLoC and Cubit Must Be Factory, Not Singleton

**Why:** BLoC/Cubit holds the UI state of a specific screen. Registering it as a singleton
means every route shares the exact same state instance. Navigate to the product list, load data,
go back, navigate again — the Cubit is still the same object in the same `loaded` state. The
`initial()` state is never reached again, `loadProducts()` might not be called, and stale data
appears. Worse: two simultaneous routes (e.g. a bottom nav with two tabs both showing products)
will fight over the same state object.

---

## ❌ Bad

```dart
// Singleton Cubit — one instance shared across the entire app lifetime
@singleton        // ❌
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo) : super(const ProductState.initial());
  final ProductRepository _repo;
}

// Consequences:
// 1. Navigate to /products → loads → emits ProductLoaded([...])
// 2. Navigate back
// 3. Navigate to /products again
// 4. BlocBuilder sees ProductLoaded([...]) immediately — no loading spinner
// 5. Data may be stale (no fresh fetch because the Cubit was never recreated)
// 6. Pull-to-refresh in one tab re-emits state visible in every tab
```

```dart
// Also bad with @lazySingleton
@lazySingleton    // ❌ still a singleton — created on first use, never recreated
class AuthBloc extends Bloc<AuthEvent, AuthState> { ... }
```

---

## ✅ Good

```dart
// Factory — new instance every time getIt<ProductCubit>() is called
@injectable       // ✅ factory scope
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo) : super(const ProductState.initial());
  final ProductRepository _repo;
}

// Route builder creates a fresh Cubit, scoped to this screen's lifecycle
GoRoute(
  path: '/products',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProductCubit>()..loadProducts(),
    child: const ProductListPage(),
  ),
)
// When the user navigates away, BlocProvider disposes the Cubit
// When they navigate back, a brand new Cubit starts in ProductInitial()
```

---

## Scope reference

| Class | Annotation | Why |
|---|---|---|
| BLoC | `@injectable` | Fresh state per route — never shared |
| Cubit | `@injectable` | Fresh state per route — never shared |
| Repository | `@Singleton(as: Repo)` | Shared — owns cache and network strategy |
| DataSource | `@Singleton(as: DS)` | Shared — single Dio/Hive connection |
| Dio | `@singleton` in `@module` | One HTTP client with shared interceptors |
| SharedPreferences | `@singleton` in `@module` | One instance across app |
