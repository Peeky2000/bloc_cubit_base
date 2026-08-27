---
name: project-convention
description: >
  Master reference for architecture, naming, lint, import boundaries, generated
  DI, Cubit/BLoC, code patterns, UI ownership, and anti-patterns. Load when
  generating, reviewing, or implementing code in this repository.
---

# Project Convention

## Stack

| Area | Standard |
|---|---|
| Architecture | Clean Architecture: presentation → domain ← data |
| State | Cubit default, BLoC supported; Equatable immutable state |
| DI | `get_it + injectable`, constructor injection |
| HTTP | Dio through `ApiHandler`; REST default |
| Models | `json_serializable` |
| Route | `SLIRouting` + `AppPage` |
| i18n | Flutter gen-l10n / ARB |
| UI toolkit | `sli_common` public API, Shadcn behind its facade |

## Dependency flow

```text
Screen → Cubit/BLoC → UseCase → Repository interface
                              ↑
DataSource ← RepositoryImpl ──┘
```

- Domain imports only Dart and domain-owned types.
- Presentation may import domain/core/DI composition APIs, never data.
- Data may import domain and infrastructure core, never presentation.
- Cubit/BLoC, UseCase, repository, and data source receive constructor
  dependencies and never resolve a service locator internally.

## Feature order

Entity → Model → DataSource → Repository interface/impl → UseCase → Cubit/BLoC
→ Screen → Route → ARB → DI generation → tests/docs.

Only create layers the requirement actually needs.

## Source map

| Topic | Reference |
|---|---|
| Architecture source of truth | `docs/architecture/README.md` |
| Canonical paths | `references/canonical-paths.md` |
| Project structure | `references/project-structure.md` |
| Naming | `rules/naming.md` |
| Lint | `rules/lint.md` |
| Import boundaries | `rules/import-boundaries.md` |
| DI scopes | `rules/di-scopes.md` |
| Patterns | `references/patterns.md` |
| Packages | `references/packages.md` |
| Anti-patterns | `rules/anti-patterns.md` |

## Mandatory workflow

1. Read the relevant architecture doc/ADR and sibling implementation.
2. Search app-memory before adding an artifact.
3. Implement with exact dependency direction and constructor injection.
4. Run `derry gen` if code generation inputs changed.
5. Run `derry quality`; distinguish baseline debt from regressions honestly.
6. Update docs/skills/app-memory when a convention or reusable artifact changes.
