# Project Structure

```text
lib/
├── core/                  app shell, base state, errors, routing, infrastructure
├── data/
│   ├── datasource/        remote transport and local persistence
│   ├── model/             json_serializable request/response models
│   └── repositories/      implementations of domain contracts
├── domain/
│   ├── entities/          pure domain values/contracts
│   ├── repositories/      repository interfaces
│   └── use_case/          business orchestration
├── presentation/<feature>/
│   ├── cubit/ or bloc/    state owner
│   └── view/              screen and feature widgets
├── di/                    injectable entry, modules, generated graph
├── l10n/                  ARB and generated localizations
└── modules/sli_common/    Git submodule for the shared UI toolkit
```

## Import boundaries

| Layer | Allowed | Forbidden |
|---|---|---|
| presentation | domain, core presentation primitives, l10n, composition API | data implementation/models |
| domain | Dart SDK and domain types | Flutter, core, data, presentation, DI |
| data | domain contracts, infrastructure core, packages | presentation |
| core | keep each sub-area directional; infrastructure must not know screens | product feature internals |

Data flow is `Screen → Cubit/BLoC → UseCase → Repository → DataSource`.
Repository implementations adapt data models to domain contracts.

Do not introduce `lib/features/` or `lib/shared/` without an explicit
repository-wide architecture migration and ADR.
