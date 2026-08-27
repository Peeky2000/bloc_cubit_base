# Code Patterns

## Entity and model

Domain types contain no JSON or Flutter imports. A data model uses
`@JsonSerializable()` and implements/maps to the domain contract.

## Injectable repository graph

```dart
abstract class ProductRepo {
  Future<List<Product>> getProducts();
}

@LazySingleton(as: ProductRepo)
class ProductRepoImpl implements ProductRepo {
  ProductRepoImpl(this._remoteDataSource);
  final ProductRemoteDataSource _remoteDataSource;
}

@lazySingleton
class ProductUseCase {
  ProductUseCase(this._repo);
  final ProductRepo _repo;
}
```

## Cubit

```dart
@injectable
class ProductCubit extends BaseCubit<ProductState> {
  ProductCubit(this._useCase) : super(ProductState.initial());

  final ProductUseCase _useCase;

  Future<void> load() async {
    emit(state.copyWith(loading: LoadingStatus.loading, error: null));
    try {
      final products = await _useCase.getProducts();
      emit(state.copyWith(
        loading: LoadingStatus.complete,
        products: products,
      ));
    } catch (error) {
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
    }
  }
}
```

UI listens to error/effect state and maps it to localized presentation. The
Cubit does not keep BuildContext, navigate, or resolve `getIt`.

## Classic BLoC

Use `BaseBloc<Event, State>` and typed events when event transformers or
concurrency semantics are necessary. Dependencies, state, and error rules are
identical to Cubit.

## Routing and localization

Register `SLIPage` entries in `lib/core/common/route.dart`. Resolve a feature
state owner once in the screen builder. Translate only in widgets/listeners via
`context.l10n`; domain and state logic carry typed values.

## Error chain

`ApiClient throws → DataSource propagates → Repository maps → UseCase expresses
domain meaning → Cubit/BLoC emits → UI renders or performs one-shot effect`.
