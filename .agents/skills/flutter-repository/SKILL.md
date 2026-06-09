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
class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this._remote, this._tokenProvider);
  final AuthRemoteDataSource _remote;
  final TokenProvider _tokenProvider;
}
```

## Rules

- Register: `registerLazySingleton<AuthRepo>(() => AuthRepoImpl(getIt(), getIt()))`
- Orchestrate remote + local; **no** UI, **no** form validation
- Prefer returning types that implement domain entities (`Login`, etc.)
- UseCases call repos — Cubits call UseCases

## References

- `references/interface-and-impl.md` — use domain/data paths above
- `rules/no-catch-unless-transform.md` — still apply
