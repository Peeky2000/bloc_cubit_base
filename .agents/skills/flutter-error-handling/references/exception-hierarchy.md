# Exception Hierarchy

All exceptions live in `lib/core/errors/exceptions.dart`.

## Class definitions

```dart
// lib/core/errors/exceptions.dart

/// Base class — never throw this directly, use a subtype
abstract class AppException implements Exception {
  final String? message;
  const AppException({this.message});
}

/// API returned a 4xx or 5xx response
class ServerException extends AppException {
  final int? statusCode;
  const ServerException({this.statusCode, super.message});
}

/// No internet connection, DNS failure, or request timeout
class NetworkException extends AppException {
  const NetworkException() : super(message: 'No internet connection');
}

/// Hive / SharedPreferences read or write failure
class CacheException extends AppException {
  const CacheException({required String message}) : super(message: message);
}

/// HTTP 401 — token expired or invalid; triggers auth redirect
class UnauthorizedException extends AppException {
  const UnauthorizedException() : super(message: 'Session expired');
}

/// HTTP 403 — valid token but insufficient permissions
class ForbiddenException extends AppException {
  final String? resource;
  const ForbiddenException({this.resource, super.message});
}

/// Resource not found (404) when meaningful to distinguish
class NotFoundException extends AppException {
  const NotFoundException({super.message});
}
```

## When each exception is thrown

| Exception | Thrown by | Trigger |
|---|---|---|
| `ServerException` | `DioInterceptor` | 4xx / 5xx (except 401, 403, 404) |
| `NetworkException` | `DioInterceptor` | connectionError, receiveTimeout, sendTimeout |
| `UnauthorizedException` | `DioInterceptor` | HTTP 401 |
| `ForbiddenException` | `DioInterceptor` | HTTP 403 |
| `NotFoundException` | `DioInterceptor` | HTTP 404 (only when meaningful) |
| `CacheException` | `LocalDataSource` | Hive box not open, corrupt data, write failure |

## What NOT to throw

```dart
// ❌ Raw string
throw 'Login failed';

// ❌ Generic Exception
throw Exception('Network error');

// ❌ Base class directly
throw AppException(message: 'Something went wrong');

// ✅ Always a concrete subtype
throw ServerException(statusCode: 422, message: 'Email already in use');
throw const NetworkException();
throw CacheException(message: 'Failed to open products box');
```
