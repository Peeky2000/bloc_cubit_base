# Unauthorized Flow (401 / Session Expiry)

When a 401 is received, the app must: silently try to refresh the token once → if refresh succeeds, retry the original request → if refresh fails, log out and navigate to login.

## Two-interceptor setup

```
Request
  └── AuthInterceptor        ← injects Bearer token on every request
        └── ErrorInterceptor ← transforms DioException → AppException

401 Response
  └── AuthInterceptor.onError
        ├── try refresh token
        │     ├── success → retry original request transparently
        │     └── failure → throw UnauthorizedException
        └── UnauthorizedException bubbles up to BLoC
```

## AuthInterceptor

```dart
// lib/core/network/auth_interceptor.dart
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final TokenStorage _tokenStorage;
  final Dio _tokenDio; // separate Dio instance — no interceptors, avoids infinite loop

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio tokenDio,
  })  : _tokenStorage = tokenStorage,
        _tokenDio = tokenDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err); // let ErrorInterceptor handle it
      return;
    }

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) throw const UnauthorizedException();

      // Refresh using separate Dio — no interceptors
      final response = await _tokenDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String?;

      await _tokenStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _tokenStorage.saveRefreshToken(newRefreshToken);
      }

      // Retry original request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _tokenDio.fetch(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _tokenStorage.clear();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
        ),
      );
    }
  }
}
```

## Handling UnauthorizedException in BLoC

```dart
// In any BLoC that calls authenticated endpoints
} on UnauthorizedException {
  emit(const ProfileState.error('Session expired. Please log in again.'));
}
```

## Global auth redirect (optional)

If you want automatic navigation to login on any 401, use a root-level `BlocListener` on `AuthBloc`:

```dart
// In the root App widget, wrapping GoRouter
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthUnauthenticated) {
      context.go('/login');
    }
  },
  child: MaterialApp.router(...),
)

// AuthBloc listens for UnauthorizedException from a stream or event
// and emits AuthUnauthenticated when token refresh fails
```

## TokenStorage

```dart
// lib/core/storage/token_storage.dart
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> clear();
}

// Implementation uses flutter_secure_storage (see flutter-datasource skill)
class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  Future<void> saveAccessToken(String t) => _storage.write(key: _accessKey, value: t);
  Future<void> saveRefreshToken(String t) => _storage.write(key: _refreshKey, value: t);
  Future<void> clear() => _storage.deleteAll();
}
```
