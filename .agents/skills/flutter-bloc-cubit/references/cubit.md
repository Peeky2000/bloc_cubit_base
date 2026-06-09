# Cubit — Standard Pattern

## Folder structure

```
features/product/presentation/
└── bloc/
    ├── product_cubit.dart
    ├── product_cubit.freezed.dart    ← generated
    └── product_state.dart
```

---

## Basic Cubit

```dart
// features/product/presentation/bloc/product_cubit.dart
part 'product_state.dart';
part 'product_cubit.freezed.dart';

@injectable
class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repo) : super(const ProductState.initial());

  final ProductRepository _repo;

  Future<void> loadProducts() async {
    emit(const ProductState.loading());
    try {
      final products = await _repo.getProducts();
      emit(ProductState.loaded(products));
    } on ServerException catch (e) {
      emit(ProductState.error(e.message ?? 'Failed to load products'));
    } on NetworkException {
      emit(const ProductState.error('No internet connection'));
    }
  }

  Future<void> refresh() => loadProducts();

  // Local filter — no network call, no loading state needed
  void filterByCategory(String categoryId) {
    final current = state;
    if (current is! ProductLoaded) return;
    final filtered = current.products
        .where((p) => p.categoryId == categoryId)
        .toList();
    emit(ProductState.loaded(filtered));
  }
}
```

---

## Pagination

```dart
Future<void> loadMore() async {
  final current = state;
  if (current is! ProductLoaded || !current.hasMore) return;

  emit(ProductState.loadingMore(current.products)); // keeps existing items visible
  try {
    final next = await _repo.getProducts(page: current.currentPage + 1);
    emit(ProductState.loaded(
      products: [...current.products, ...next.items],
      hasMore: next.hasMore,
      currentPage: current.currentPage + 1,
    ));
  } on ServerException {
    // Keep existing data on page-load failure — don't lose what's already shown
    emit(ProductState.loaded(
      products: current.products,
      hasMore: current.hasMore,
      currentPage: current.currentPage,
    ));
  }
}
```

---

## Providing in the widget tree

Provide Cubit inside the route builder — never at the app root:

```dart
GoRoute(
  path: '/products',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProductCubit>()..loadProducts(), // fresh instance per route
    child: const ProductPage(),
  ),
)
```

---

## Naming conventions

| Element | Example |
|---|---|
| Cubit class | `ProductCubit` |
| Cubit file | `product_cubit.dart` |
| Method — load | `loadProducts()` |
| Method — local operation | `filterByCategory(String id)` |
| Method — action | `deleteProduct(String id)` |
