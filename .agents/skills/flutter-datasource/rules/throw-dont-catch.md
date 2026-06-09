# Rule: Throw, Don't Catch

**Why:** BLoC is the designated error handler — it catches exceptions and emits
the appropriate error state to the UI. If an API class swallows an exception
(catches and doesn't rethrow), BLoC never knows something went wrong and the
UI stays in a stale or loading state forever.

---

## Bad

```dart
@injectable
class AuthLocalApi {
  AuthLocalApi(this._secureStorage);
  final FlutterSecureStorage _secureStorage;

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } catch (e) {
      // Exception swallowed — BLoC emits nothing, UI freezes on loading
      debugPrint('Storage error: $e');
      return null;
    }
  }
}
```

---

## Good

```dart
@injectable
class AuthLocalApi {
  AuthLocalApi(this._secureStorage);
  final FlutterSecureStorage _secureStorage;

  // No try/catch — exception bubbles up through Repository to BLoC
  Future<String?> getAccessToken() =>
      _secureStorage.read(key: 'access_token'); // let it throw
}

// BLoC is the right place to react to errors
Future<void> _onLogin(AuthLoginPressed event, Emitter<AuthState> emit) async {
  emit(const AuthState.loading());
  try {
    final user = await _repo.login(event.email, event.password);
    emit(AuthState.authenticated(user));
  } on ServerException catch (e) {
    emit(AuthState.error(e.message ?? 'Login failed')); // caught here
  } on NetworkException {
    emit(const AuthState.error('No internet connection'));
  }
}
```

---

## Exception: transform-only catch

The only acceptable catch in an API class is when you need to change the exception *type*
without swallowing it. Always rethrow or throw a new typed exception.

```dart
Future<User> getProfile() async {
  try {
    final response = await _dio.get('/profile');
    return User.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 403) {
      throw ForbiddenException(); // transform type — still throws
    }
    rethrow; // everything else bubbles up unchanged
  }
}
```
