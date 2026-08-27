# AI Process — Flutter Base

This repository treats architecture documentation and executable gates as one
contract. Read [prerequisites](docs/prerequisites.md), the
[architecture index](docs/architecture/README.md), and `project-convention`
before planning or implementation.

## Delivery flow

```text
Brainstorm / Spec → user decision gate → implementation plan → implementation
→ review → tests and architecture gates → status/docs update
```

| Artifact | Path |
|---|---|
| Brainstorm | `docs/brainstorm/YYYY-MM-DD-{topic}.md` |
| Frontend spec | `docs/specs/{NNN}-{name}/fe.md` |
| Checklists | `docs/specs/{NNN}-{name}/checklists/` |
| Plan | `docs/plan/YYYY-MM-DD-{topic}.md` |
| Review | `docs/reviews/YYYY-MM-DD-hh-mm-ss-{topic}.md` |
| Architecture decision | `docs/adr/NNNN-{decision}.md` |

Every implementation plan must contain exact paths, ownership, objective verify
conditions, risks, out-of-scope items, and a Definition of Done.

## Feature implementation order

```text
Entity → Model → DataSource → Repository interface/impl → UseCase
→ Cubit or BLoC → Screen → Route → ARB → DI code generation → tests/docs
```

The order is dependency-aware, not permission to add layers a feature does not
need. UI-only changes should remain UI-only.

## Technology decisions

| Concern | Standard |
|---|---|
| State | Cubit default, BLoC supported; `BaseAppState + Equatable + copyWith` |
| DI | `get_it + injectable`, constructor injection |
| HTTP | Dio through `ApiHandler`; REST default |
| Route | `SLIRouting`, `AppPage` |
| i18n | Flutter gen-l10n and ARB |
| Shared UI | `sli_common` public `Sli*` API; Shadcn behind the facade |
| Environments | typed `AppEnvironment` + centralized `bootstrap()` |

## Implementation rules

1. Search app-memory and sibling code before creating artifacts.
2. Keep domain pure; models and transport details remain in data.
3. Inject dependencies through constructors. Resolve `getIt` only where an
   object graph is composed, never inside Cubits, UseCases, repositories, or
   data sources.
4. API/data layers propagate typed failures and never navigate or show UI.
5. Keep one-shot UI actions at the presentation boundary; widgets translate and
   render user-facing messages.
6. Add or update tests for behavior changed by the task.
7. Update architecture, guide, skill, or ADR docs whenever a convention changes.

## Quality gates

```bash
derry gen
derry quality
```

If the repository already has analyzer debt, a change must introduce no compile
errors and no new warnings. Record the baseline and remaining debt explicitly;
never claim a clean gate when it is not clean.

## Forking the base

Follow [create-app-from-base](docs/guides/create-app-from-base.md). At minimum,
change Dart/native identifiers, environment URLs, Firebase files, branding,
signing configuration, and example product features. Preserve the architecture
gates, docs, and `sli_common` submodule unless the new project intentionally
chooses alternatives and records an ADR.
