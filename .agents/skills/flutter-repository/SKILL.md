---
name: flutter-repository
description: >
  Repository layer for this base: abstract interface in domain, implementation in data.
  Trigger: "repository", "AuthRepo", "repo impl".
---

# Repository

## Locations

| | Path |
|---|------|
| Interface | `lib/domain/repositories/{name}_repo.dart` |
| Implementation | `lib/data/repositories/{name}_repo_impl.dart` |

## Pattern

```dart
// domain
abstract class AuthRepo {
  Future<Login?> appLogin({required String phone, required String password});
}

// data
@LazySingleton(as: AuthRepo)
class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this._remote, this._tokenProvider);
  final AuthRemoteDataSource _remote;
  final TokenProvider _tokenProvider;
}
```

## Rules

- Bind the implementation with `@LazySingleton(as: AuthRepo)`
- Constructor-inject data sources; never resolve `getIt` internally
- Orchestrate remote + local; **no** UI, **no** form validation
- Prefer returning types that implement domain entities (`Login`, etc.)
- UseCases call repos — Cubits call UseCases

- Catch only to transform an infrastructure failure into a documented domain
  failure or to implement repository-level fallback; never swallow an error.
