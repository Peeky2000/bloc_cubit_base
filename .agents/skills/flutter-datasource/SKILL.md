---
name: flutter-datasource
description: >
  Remote and local data sources using ApiHandler/Dio, SharedPreferences for
  non-secret settings, secure TokenProvider storage, and injectable bindings.
  Trigger: datasource, API client, remote, local storage, Dio, token.
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
- Network logs and inspectors must pass through `NetworkRedactor`, and the
  inspector must be disabled in production.
- Do not resolve `getIt` inside a data source and do not catch-and-swallow errors.

Run data-source tests for parsing and error propagation, plus security tests for
redaction or token migration when those paths change.
