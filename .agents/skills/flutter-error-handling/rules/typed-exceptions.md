# Rule: Define typed exceptions — never throw raw strings or generic Exception

## Why

- Typed exceptions let BLoC write `on NetworkException` instead of `catch (e)` — preventing swallowing of programming bugs
- A raw string or `Exception('...')` carries no type information — every caller must parse the message to know what went wrong
- The hierarchy (`AppException` subtypes) gives BLoC the precision to emit the right user-facing message

## ❌ Bad

```dart
// Raw string throw
throw 'Network error occurred';

// Generic Exception
throw Exception('Server returned 422');

// Untyped catch-all in BLoC — hides real bugs
try {
  await _repo.loadData();
} catch (e) {
  emit(DataState.error(e.toString())); // NPE becomes "Null check operator used on null"
}
```

## ✅ Good

```dart
// Typed throw in interceptor
return switch (statusCode) {
  401 => const UnauthorizedException(),
  _   => ServerException(statusCode: statusCode, message: message),
};

// Typed catch in BLoC — precise, intentional
try {
  await _repo.loadData();
} on NetworkException {
  emit(const DataState.error('No internet connection'));
} on ServerException catch (e) {
  emit(DataState.error(e.message ?? 'Failed to load'));
}
// NPE, CastError, etc. propagate → crash loudly in dev, Crashlytics in prod
```

## Exception class location

```
lib/core/errors/exceptions.dart   ← all AppException subtypes defined here
```

Never define feature-specific exceptions outside this file unless they genuinely have no overlap with existing types.
