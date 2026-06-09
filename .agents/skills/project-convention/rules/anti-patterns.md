# Anti-Patterns

Violations to catch in code review. Each entry shows what NOT to do and why.

---

## State Management

### ❌ Cubit calling Repository directly

```dart
// WRONG — skips UseCase
final _repo = Injector.getIt.get<AuthRepo>();
await _repo.appLogin(...);
```

```dart
// CORRECT
final _authUseCase = Injector.getIt.get<AuthUseCase>();
await _authUseCase.login(...);
```

### ❌ Cubit registered as singleton

```dart
// WRONG
getIt.registerLazySingleton<SignInCubit>(() => SignInCubit());
```

```dart
// CORRECT
getIt.registerFactory<SignInCubit>(() => SignInCubit());
```

### ❌ Presentation importing data models

```dart
// WRONG
import 'package:<app>/data/model/response/auth/login_response_model.dart';
```

Use domain entities / state fields exposed by Cubit instead.

### ❌ BLoC registered as singleton (legacy note)

```dart
// WRONG
@singleton  // ← BLoC/Cubit must NEVER be singleton
class ProductCubit extends Cubit<ProductState> { ... }
```

```dart
// CORRECT
@injectable  // factory — fresh instance per BlocProvider
class ProductCubit extends Cubit<ProductState> { ... }
```

### ❌ Not emitting loading before async call

```dart
// WRONG
Future<void> _onLoad(_, Emitter emit) async {
  final products = await _repository.getProducts();  // ← no loading state
  emit(ProductState.loaded(products));
}
```

```dart
// CORRECT
Future<void> _onLoad(_, Emitter emit) async {
  emit(const ProductState.loading());  // ← BEFORE the async call
  final products = await _repository.getProducts();
  emit(ProductState.loaded(products));
}
```

---

## Error Handling

### ❌ Bare catch or catching Exception

```dart
// WRONG
try {
  ...
} catch (e) {
  emit(ProductState.error(e.toString()));
}
```

```dart
// CORRECT — catch specific types
try {
  ...
} on ServerException catch (e) {
  emit(ProductState.error(e.message ?? 'Server error'));
} on NetworkException {
  emit(const ProductState.error('No internet connection'));
}
```

### ❌ API catching its own exceptions

```dart
// WRONG — API should throw, not catch
class AuthRemoteApi {
  Future<UserModel> getMe() async {
    try {
      return await _dio.get('/auth/me');
    } catch (e) {
      return UserModel.empty();  // ← swallowing error
    }
  }
}
```

```dart
// CORRECT — let it bubble up (interceptor wraps DioException → ServerException)
// Retrofit handles this automatically — just declare the method
@GET('/auth/me')
Future<UserModel> getMe();
```

---

## Data Layer

### ❌ Importing Drift in model files

```dart
// WRONG — Model must not depend on database layer
// lib/shared/models/transaction/transaction_model.dart
import 'package:drift/drift.dart';  // ❌ Drift belongs in core/database/
import 'package:base_app/core/database/tables/transactions.dart';  // ❌

@freezed
abstract class TransactionModel with _$TransactionModel {
  // ...
}
```

```dart
// CORRECT — Model is pure data class with Freezed + JSON only
// lib/shared/models/transaction/transaction_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required double amount,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}

// Row ↔ Model conversion lives in core/database/mappers/
```

### ❌ Business logic in API class

```dart
// WRONG
class ProductRemoteApi {
  Future<List<ProductModel>> getProducts() async {
    final all = await _dio.get('/products');
    return all.where((p) => p.isActive).toList();  // ← filtering = business logic
  }
}
```

```dart
// CORRECT — raw data only, filter in Repository
@GET('/products')
Future<List<ProductModel>> getProducts();
// Filter in Repository or BLoC
```

### ❌ Using abstract interfaces for Repository/API

```dart
// WRONG — old pattern, no abstract interfaces in this project
abstract class ProductRepository { ... }

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository { ... }
```

```dart
// CORRECT — concrete class, no Impl suffix
@LazySingleton()
class ProductRepository {
  ProductRepository(this._remoteApi, this._productDao);
  final ProductRemoteApi _remoteApi;
  final ProductDao _productDao;
}
```

---

## UI

### ❌ Hardcoded strings

```dart
// WRONG
Text('Sign In')
Text('Email is required')
```

```dart
// CORRECT
Text('login.title'.tr())
Text('login.email_required'.tr())
```

### ❌ Hardcoded colors or text styles

```dart
// WRONG
Text('Hello', style: TextStyle(fontSize: 16, color: Color(0xFF111827)))
Container(color: Color(0xFF2563EB))
```

```dart
// CORRECT
Text('Hello', style: AppTextStyles.bodyMedium)
Container(color: AppColors.primary)
```

### ❌ BLoC access in Organism or below

```dart
// WRONG — Organism reading BLoC
class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();  // ← Organism should not know BLoC
    ...
  }
}
```

```dart
// CORRECT — pass callbacks from Page
class LoginForm extends StatelessWidget {
  const LoginForm({required this.onSubmit, required this.isLoading});
  final void Function(String email, String password) onSubmit;
  final bool isLoading;
  ...
}

// Page wires it up
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) => LoginForm(
    onSubmit: (email, password) => context.read<AuthBloc>().add(
      AuthEvent.loginRequested(email: email, password: password),
    ),
    isLoading: state is AuthLoading,
  ),
)
```

---

## Cross-cutting

### ❌ Cross-feature imports

```dart
// WRONG
// In features/cart/...
import 'package:base_app/features/auth/bloc/auth_bloc.dart';
```

Move the shared piece to `shared/` or access it via a shared repository.

### ❌ Calling getIt inside build()

```dart
// WRONG
Widget build(BuildContext context) {
  final cubit = getIt<ProductCubit>();  // ← creates new instance on every rebuild
  ...
}
```

```dart
// CORRECT — inject at route level
GoRoute(
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProductCubit>(),
    child: const ProductListPage(),
  ),
)
```
