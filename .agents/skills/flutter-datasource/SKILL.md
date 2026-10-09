---
name: flutter-datasource
description: >
  Write or change a data source in this base: remote calls through
  ApiHandler/Dio and UrlEndPoint, local storage (SharedPreferences only for
  non-secret settings and caches, TokenProvider/flutter_secure_storage for
  tokens), parsing into data models, and the @LazySingleton(as: ...) binding.
  Use when adding an endpoint or API call, choosing where to persist a value,
  or saving a token after login. Trigger: datasource, data source, endpoint,
  API client, ApiHandler, Dio, SharedPreferences, gọi API, thêm API, lưu local,
  lưu xuống máy. Not for the repository that combines remote and local
  sources, offline fallback or repo responsibilities (use flutter-repository),
  and not for a security audit of token storage (use mobile-security-privacy).
---

# Data Sources

## Locations

```text
lib/data/datasource/remote/  ApiClient, endpoints, interceptors, remote sources
lib/data/datasource/local/   settings, caches, TokenProvider
```

## Rules

- Define an abstract data-source contract and bind the implementation with
  `@LazySingleton(as: XxxDataSource)`.
- Inject `ApiHandler` or the storage abstraction through the constructor.
- Keep URLs in `UrlEndPoint`; use parser callbacks to create data models.
- Transport/storage code returns raw data-layer models and propagates failures.
  It never navigates, shows dialogs, translates text, or applies product rules.
- Store tokens and secrets through `flutter_secure_storage`/`TokenProvider`.
  SharedPreferences is only for non-sensitive settings or caches.
- Data that lives and dies together (token and cached account) has one owner;
  sign-out and expiry clear everything a user owns through that owner.
- Before adding any persisted value, read
  [references/storage-patterns.md](references/storage-patterns.md) for the
  store choice table, lifecycle rules and the files to copy.
- Network logs and inspectors must pass through `NetworkRedactor`, and the
  inspector must be disabled in production.
- Do not resolve `getIt` inside a data source and do not catch-and-swallow errors.

Run data-source tests for parsing and error propagation, plus security tests for
redaction or token migration when those paths change.
