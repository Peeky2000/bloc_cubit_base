---
name: project-convention
description: >
  Master reference for this Flutter project's conventions: architecture, naming,
  lint, import boundaries, DI scopes, code patterns, and anti-patterns.
  Load this skill when generating, reviewing, or implementing any code.
---

# Project Convention

## Overview

Flutter **Clean Architecture** (presentation → domain → data) with **UseCase** layer and **Cubit** state management.

| Area | Stack in this base |
|------|-------------------|
| State | `flutter_bloc` / `bloc`, `BaseCubit`, `BaseAppState`, `LoadingStatus` |
| DI | `get_it` — manual registration in `lib/di/injection.dart` (`Injector`) |
| HTTP | `dio` via `ApiHandler` / `ApiClient` (not Retrofit) |
| JSON models | `json_serializable` + `json_annotation` (`.g.dart`) |
| Domain | Abstract **entities** + abstract **repositories** |
| Navigation | `SLIRouting` + `AppPage` (`core/routing/`, `core/common/route.dart`) |
| i18n | Flutter **gen-l10n** — `lib/l10n/arb/*.arb`, `context.l10n` |
| Assets | `flutter_gen` → `lib/generated/` |

Package imports: `package:<name>/...` where `<name>` is `pubspec.yaml` → `name:` (rename when forking this base).

---

## Quick Reference

| Topic | File |
|-------|------|
| Canonical paths (specs/plans) | [references/canonical-paths.md](references/canonical-paths.md) |
| Project structure & layer rules | [references/project-structure.md](references/project-structure.md) |
| Naming conventions | [rules/naming.md](rules/naming.md) |
| Lint & analysis rules | [rules/lint.md](rules/lint.md) |
| Import boundaries | [rules/import-boundaries.md](rules/import-boundaries.md) |
| DI scopes | [rules/di-scopes.md](rules/di-scopes.md) |
| Code patterns | [references/patterns.md](references/patterns.md) |
| Packages | [references/packages.md](references/packages.md) |
| Anti-patterns | [rules/anti-patterns.md](rules/anti-patterns.md) |

---

## Architecture Diagram

```
UI (Screen in presentation/.../view)
  │  user action → Cubit method
  ▼
Cubit (extends BaseCubit<State>)     ← registerFactory in setupPresentation
  │  validate form fields here
  │  emit loading → call UseCase
  ▼
UseCase (domain/use_case)            ← registerLazySingleton in setupDomain
  │  business rules, orchestration
  ▼
Repository (domain interface)        ← AuthRepo, UserRepo, …
  ▼
RepositoryImpl (data/repositories)     ← registerLazySingleton in setupDomain
  ▼
RemoteDataSource / LocalDataSource   ← registerLazySingleton in setupData
  ▼
ApiHandler (Dio) / SharedPreferences / Firebase
```

---

## New Feature — Layer Order

1. Entity (`domain/entities/`)
2. Response/request models (`data/model/`) — `implements` entity where applicable
3. Remote/local data sources (`data/datasource/`)
4. Repository interface (`domain/repositories/`) + impl (`data/repositories/`)
5. UseCase (`domain/use_case/`)
6. Cubit + State (`presentation/<feature>/cubit/`)
7. Screen (`presentation/<feature>/view/`)
8. DI (`lib/di/injection.dart` — all three `setup*` methods as needed)
9. Route (`core/common/route.dart`)
10. ARB keys (`lib/l10n/arb/`) if new copy is needed

---

## AI Workflow Artifacts

| Artifact | Path |
|----------|------|
| Brainstorm | `docs/brainstorm/YYYY-MM-DD-{topic}.md` |
| Frontend spec | `docs/specs/{NNN}-{name}/fe.md` |
| Implementation plan | `docs/plan/YYYY-MM-DD-{topic}.md` |
| Code review | `docs/reviews/YYYY-MM-DD-hh-mm-ss-{topic}.md` |
| Project context for specs | `docs/prerequisites.md` |

See root `ai-process.md` for the full pipeline.

---

## Resources

- **AI process** → `ai-process.md`
- **Prerequisites** → `docs/prerequisites.md`
