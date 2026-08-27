# Packages

Read exact constraints from `pubspec.yaml`; this file documents intent.

| Package | Purpose |
|---|---|
| `bloc`, `flutter_bloc` | Cubit and classic BLoC |
| `equatable` | immutable value/state equality |
| `get_it`, `injectable` | generated object graph and composition root |
| `dio` | HTTP through `ApiHandler` |
| `json_annotation`, `json_serializable` | data models |
| `shared_preferences` | non-sensitive settings/cache |
| `flutter_secure_storage` | credentials through `TokenProvider` |
| `alice` | redacted non-production network inspection |
| `sli_common` | shared tokens/components; Shadcn facade |
| `firebase_core`, `firebase_auth` | current authentication integration |

## Dev tooling

`build_runner`, `injectable_generator`, `flutter_gen_runner`, `bloc_test`,
`mocktail`, and `flutter_lints` support generation, tests, and quality gates.

## Intentional non-defaults

- Freezed and HydratedBloc are optional; state remains Equatable + copyWith.
- REST is standard; GraphQL is an optional module.
- Use `SLIRouting`, not go_router, unless an ADR replaces it.
- Use `ApiHandler`, not Retrofit, unless an ADR replaces it.
- Do not restore asset `.env` configuration; use typed dart-defines.
