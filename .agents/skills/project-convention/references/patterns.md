# Code Patterns (this base)

Reference implementations aligned with existing code in this repository.

---

## 1. Entity (domain)

```dart
// lib/domain/entities/auth/login.dart
import 'package:<app>/domain/entities/auth/token_wrapper.dart';
import 'package:<app>/domain/entities/profile/account.dart';

abstract class Login {
  Account? get account;
  TokenWrapper? get token;
}
```

Rules:
- Abstract class or simple contract — **no** `fromJson`, **no** Flutter imports
- Location: `lib/domain/entities/{domain}/`

---

## 2. Model (data) — implements entity

```dart
// lib/data/model/response/auth/token_auth_response_model.dart
import 'package:<app>/domain/entities/auth/token_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_auth_response_model.g.dart';

@JsonSerializable()
class TokenAuthResponseModel implements TokenAuth {
  TokenAuthResponseModel({this.token, this.expires});

  @override
  @JsonKey(name: 'token')
  final String? token;

  @override
  @JsonKey(name: 'expires')
  final DateTime? expires;

  factory TokenAuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TokenAuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenAuthResponseModelToJson(this);
}
```

After create/edit:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. Remote DataSource

```dart
abstract class AuthRemoteDataSource {
  Future<LoginResponseModel?> appLogin({
    required String phone,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiHandler);
  final ApiHandler _apiHandler;

  @override
  Future<LoginResponseModel?> appLogin({...}) async {
    final result = await _apiHandler.post(
      UrlEndPoint.auth.login,
      body: {'phone': phone, 'password': password},
      parser: (json) => LoginResponseModel.fromJson(json),
    );
    return result.data;
  }
}
```

Rules:
- Use `UrlEndPoint` for paths
- Parse via `BaseResponseModel<T>` / `BaseListResponseModel<T>`
- Throw from `ApiClient` layer — do not swallow in data source unless transforming

---

## 4. Repository

```dart
// domain/repositories/auth_repo.dart
abstract class AuthRepo {
  Future<Login?> appLogin({required String phone, required String password});
  // ...
}

// data/repositories/auth_repo_impl.dart
class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this._authRemoteDataSource, this._tokenProvider);
  final AuthRemoteDataSource _authRemoteDataSource;
  final TokenProvider _tokenProvider;
  // delegate to remote/local
}
```

---

## 5. UseCase

```dart
class AuthUseCase {
  AuthUseCase(this._authRepo, this._userRepo);
  final AuthRepo _authRepo;
  final UserRepo _userRepo;

  Future<Login?> login({
    required String phone,
    required String password,
    bool isRememberLogin = false,
  }) async {
    final result = await _authRepo.appLogin(phone: phone, password: password);
    if (isRememberLogin) {
      await _authRepo.setTokenToLocal(tokenWrapper: result?.token);
      await _userRepo.setAccountToLocal(result?.account);
    }
    return result;
  }
}
```

Rules:
- Business orchestration belongs here (not in Cubit, not in Repo impl UI logic)
- Cubit calls **UseCase**, not `AuthRepo` directly

---

## 6. Cubit + State

```dart
class SignInCubit extends BaseCubit<SignInState> {
  SignInCubit() : super(SignInState.initial());

  final AuthUseCase _authUseCase = Injector.getIt.get<AuthUseCase>();

  Future<void> _signIn({required String username, required String pass}) async {
    try {
      emit(state.copyWith(loading: LoadingStatus.loading));
      final loginInfo = await _authUseCase.login(
        phone: usernameFormat,
        password: pass,
        isRememberLogin: state.isRememberLogin,
      );
      emit(state.copyWith(loading: LoadingStatus.complete));
      // navigation via SLIRouting
    } catch (e) {
      emit(state.copyWith(loading: LoadingStatus.error));
      handleErrorResponse(e, onRetry: () => _signIn(...));
    }
  }
}
```

```dart
part of 'sign_in_cubit.dart';

class SignInState extends BaseAppState with EquatableMixin {
  // fields + copyWith + initial factory
}
```

Rules:
- Extend `BaseCubit<State>` and `BaseAppState`
- Use `LoadingStatus` enum for async lifecycle
- Form validation in Cubit; map messages via `context.l10n` when needed
- Errors: `handleErrorResponse` from `presentation/global_handler.dart`

---

## 7. Routing

```dart
// core/common/route.dart
class AppPage {
  static const String SIGN_IN = '/sign_in';
  static final List<SLIPage> pages = [
    SLIPage(name: SIGN_IN, page: signInScreenBuilder()),
  ];
}

// In Cubit or screen
SLIRouting.toNamed(AppPage.HOME);
SLIRouting.offAllNamed(AppPage.SIGN_IN, arguments: {'key': value});
```

---

## 8. Localization

```dart
import 'package:<app>/l10n/l10n.dart';

// In widget with context
Text(context.l10n.passIsRequired)

// Cubit with AppController context (existing pattern)
_context?.l10n.emailPhoneIsRequired
```

Add strings to `lib/l10n/arb/app_en.arb` and `app_vi.arb`, then run `flutter gen-l10n` (or `flutter pub get` if `generate: true`).

---

## 9. Error handling chain

```
ApiClient / interceptors  →  throw ServerException, NetworkIssueException, …
DataSource                →  propagate
Repository                →  propagate (minimal transform)
UseCase                   →  propagate
Cubit                     →  catch → emit error state + handleErrorResponse
UI                        →  dialog via DialogUtil (global_handler)
```

Exception types: `lib/core/error/exception.dart`  
Mapping: `lib/core/error/error_to_string_mapper.dart`
