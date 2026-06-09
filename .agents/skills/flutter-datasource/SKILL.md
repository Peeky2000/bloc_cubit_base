---
name: flutter-datasource
description: >
  Remote and local data sources for this base using ApiHandler (Dio) and
  SharedPreferences wrappers. Trigger: "datasource", "api client", "remote",
  "local storage", "dio".
---

# Data Sources

## Locations

```
lib/data/datasource/
├── remote/
│   ├── api_client.dart          # ApiHandler impl (Dio + interceptors)
│   ├── url_end_point.dart       # path constants
│   └── *_remote_data_source.dart
└── local/
    ├── auth_local_data_source.dart
    ├── token_provider.dart
    └── ...
```

## Remote pattern

1. Abstract class `XxxRemoteDataSource`
2. Impl takes `ApiHandler`
3. Call `_apiHandler.post/get/put` with `parser: (json) => Model.fromJson(json)`
4. Return `result.data` from `BaseResponseModel<T>`

## Local pattern

- Wrap `SharedPreferences` (see `AuthLocalDataSource`, `TokenProvider`)
- No business rules — read/write only

## Rules

- **No** Retrofit `@RestApi`
- **Throw** on failure — let `ApiClient` / interceptors map Dio errors
- Endpoints in `UrlEndPoint` — do not hardcode strings in multiple files
- Register in `Injector.setupData()`

## References

- `references/remote-datasource.md`, `references/local-datasource.md` — adapt paths to `data/datasource/`
- `rules/no-business-logic.md`, `rules/throw-dont-catch.md` — still apply
