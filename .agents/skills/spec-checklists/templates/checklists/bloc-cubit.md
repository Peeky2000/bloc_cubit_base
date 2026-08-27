# Cubit Checklist — {cubit-name}

## Prerequisites

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.8` in `fe.md`

## Required Skills

- [ ] `flutter-bloc-cubit`
- [ ] `flutter-di`
- [ ] `flutter-error-handling`
- [ ] `project-convention`

## 1. Type & location

- [ ] **Type:** Cubit (default) — `BaseCubit<{Feature}State>`
- [ ] **Name:** `{Feature}Cubit`
- [ ] **Location:** `lib/presentation/{feature}/cubit/{feature}_cubit.dart`
- [ ] **State file:** `{feature}_state.dart` — immutable `BaseAppState` + Equatable

## 2. State

- [ ] Uses `LoadingStatus` (`initial`, `loading`, `complete`, `error`)
- [ ] `copyWith` + `initial()` factory
- [ ] Field-level validation errors on state if spec requires

## 3. Dependencies & methods

- [ ] Constructor-injects **`{Feature}UseCase`** — no Repo or service locator
- [ ] `emit(loading)` before async; `complete` or `error` after
- [ ] Emits recoverable error/failure state; UI listener owns dialogs/navigation
- [ ] Methods match spec §6.9 user actions

## 4. DI

- [ ] Annotated `@injectable` (factory) and present in regenerated DI config

## 5. Tests (if requested)

- [ ] `test/presentation/{feature}/cubit/{feature}_cubit_test.dart`
