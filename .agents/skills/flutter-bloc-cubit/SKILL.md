---
name: flutter-bloc-cubit
description: >
  Cubit state management for this base: BaseCubit, BaseAppState, LoadingStatus,
  Equatable states. Cubits call UseCases. Trigger: "cubit", "bloc", "state", "emit".
---

# BLoC / Cubit

## Default: Cubit

This base uses **Cubit** (extends `BaseCubit`) for screens. Use classic BLoC only if you need complex concurrent events.

## File layout

```
presentation/<feature>/cubit/
├── <feature>_cubit.dart
└── <feature>_state.dart    # part of cubit file
```

## State

- Extend `BaseAppState` (has `loading: LoadingStatus`, `error`)
- Mix in `EquatableMixin` for `props`
- Implement `copyWith` + `initial()` factory
- Use `LoadingStatus.loading | complete | error | initial`

## Cubit

- Extend `BaseCubit<YourState>`
- Resolve `UseCase` via `Injector.getIt` (see `SignInCubit`)
- `emit(state.copyWith(loading: LoadingStatus.loading))` before async
- Catch errors → `handleErrorResponse(e, onRetry: ...)`
- **Validate forms in Cubit** (regex from `core/common/constant.dart`, messages from `l10n`)

## Flow

```
Cubit → UseCase → Repo → DataSource
```

Never: `Cubit → Repo` or `Cubit → RemoteDataSource`

## DI

`Injector.setupPresentation()` → `registerFactory<YourCubit>(() => YourCubit())`

## References

- `references/cubit.md`, `references/state.md` — align with BaseCubit pattern
- `rules/validate-in-bloc.md`, `rules/emit-loading-before-async.md` — apply
- Ignore `rules/sealed-state.md` freezed requirement — use BaseAppState pattern instead
