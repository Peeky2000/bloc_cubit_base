# Rule: Never show raw exception messages to the user

## Why

- `e.toString()` exposes internal implementation details: stack traces, class names, Dio internals
- It leaks server error payloads that may contain sensitive data
- It produces unreadable messages: `"DioException [bad response]: ..."` is not a UX
- BLoC is already the right place to decide what message the user sees — use it

## ❌ Bad

```dart
// Showing raw exception toString in UI
} catch (e) {
  emit(ProductState.error(e.toString())); // "DioException [bad response]: ..."
}

// Passing the exception object to the widget
Text(exception.toString()) // ❌ in a widget

// Showing internal CacheException message
} on CacheException catch (e) {
  emit(ProfileState.error(e.message)); // "Failed to read from box 'user_profile'" — internal detail
}
```

## ✅ Good

```dart
// BLoC maps exceptions to user-friendly messages
} on NetworkException {
  emit(const ProductState.error('No internet connection'));
} on ServerException catch (e) {
  // ServerException.message comes from the API — safe to show when present
  emit(ProductState.error(e.message ?? 'Failed to load products'));
} on CacheException {
  // Generic fallback — don't expose internal storage detail
  emit(const ProfileState.error('Could not load saved data'));
} on UnauthorizedException {
  emit(const ProfileState.error('Session expired. Please log in again.'));
}
```

## Safe vs unsafe exception messages

| Exception | Message source | Show to user? |
|---|---|---|
| `ServerException.message` | API response body | ✅ Yes — API controls this string |
| `NetworkException.message` | Hardcoded in class | ✅ Yes — always "No internet connection" |
| `CacheException.message` | Internal Hive/Prefs detail | ❌ No — use generic fallback |
| `DioException.message` | Dio internals | ❌ Never — already transformed by interceptor |
| `e.toString()` on unknown | Stack trace / class name | ❌ Never |
