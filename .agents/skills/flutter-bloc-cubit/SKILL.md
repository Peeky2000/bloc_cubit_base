---
name: flutter-bloc-cubit
description: >
  State management for this base using BaseCubit or BaseBloc, immutable
  BaseAppState, LoadingStatus, Equatable, copyWith, and constructor-injected
  UseCases. Trigger: cubit, bloc, state, event, emit, BlocProvider.
---

# Cubit and BLoC

## Choose deliberately

- Use Cubit by default for method-driven screen state and linear workflows.
- Use classic BLoC when named events, debouncing/restartability, event
  transformers, or multiple event producers make behavior clearer.
- Both follow the same dependency and state rules.

## State contract

- Extend `BaseAppState` for feature state.
- Keep every field `final`; extend Equatable and declare complete `props`.
- Implement typed `copyWith` and an `initial()` factory or const initial value.
- Model async lifecycle with `LoadingStatus` while preserving feature data.
- Put recoverable errors in state. One-shot navigation/dialog effects stay at
  the presentation boundary and must not be executed by data/domain layers.

## State owner rules

- Receive a UseCase through the constructor; never resolve a locator internally.
- Call UseCases only, not repositories or data sources.
- Emit loading before awaited work and complete/error afterward.
- Do not retain `BuildContext`, access widgets, translate strings, or navigate
  from reusable business logic.
- Validate business/input shape in testable Dart code; UI translates typed
  validation results.

## DI and UI

Annotate feature Cubits/BLoCs with `@injectable`. Resolve them once in a route or
screen builder and provide with `BlocProvider`. Never resolve from `build()`.

Test state transitions with `bloc_test`, including success, failure, retry, and
concurrency behavior for classic BLoC.

See `docs/architecture/state-management.md` and
`docs/guides/choose-cubit-or-bloc.md`.
