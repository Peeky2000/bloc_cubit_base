# Dio Error Interceptor

The interceptor is the **single point** where `DioException` is transformed into typed `AppException`. No other layer should inspect `DioException` directly.

File: `lib/core/network/error_interceptor.dart`

## Implementation

```dart
import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    throw _mapToAppException(err);
  }

  AppException _mapToAppException(DioException err) {
    // Network-level failures — no response
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
        return const NetworkException();
      default:
        break;
    }

    // HTTP response errors
    final statusCode = err.response?.statusCode;
    final message = _parseMessage(err.response);

    return switch (statusCode) {
      401 => const UnauthorizedException(),
      403 => ForbiddenException(message: message),
      404 => NotFoundException(message: message),
      _   => ServerException(statusCode: statusCode, message: message),
    };
  }

  String? _parseMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
               data['error'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
```

## Registering in NetworkModule (DI)

```dart
// lib/core/network/network_module.dart
@module
abstract class NetworkModule {
  @singleton
  Dio get dio {
    final dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.addAll([
      AuthInterceptor(),    // adds Bearer token
      ErrorInterceptor(),   // transforms DioException → AppException
      if (kDebugMode) LogInterceptor(responseBody: true),
    ]);

    return dio;
  }
}
```

## What the interceptor does NOT do

- Does NOT handle token refresh (that is `AuthInterceptor`'s job — see `references/unauthorized-flow.md`)
- Does NOT catch `CacheException` — that is thrown directly by `LocalDataSource`
- Does NOT log errors — `LogInterceptor` handles that separately
