# Project Structure

## Directory Layout

```
lib/
├── core/                         # Infrastructure shared across app
│   ├── app/                      # AppConfig, AppController, AppCubit
│   ├── base_component/           # BaseCubit, BaseAppState
│   ├── common/                   # Constants, enums, route names (AppPage)
│   ├── routing/                  # SLIRouting, SLIPage, transitions
│   ├── error/                    # Exceptions, ErrorMapper
│   ├── widget/                   # Reusable UI (dialogs, buttons, fields)
│   ├── helper/                   # NetworkChecker, utilities
│   └── extension/
│
├── data/
│   ├── datasource/
│   │   ├── remote/               # ApiClient, *RemoteDataSource
│   │   └── local/                # SharedPreferences, TokenProvider, etc.
│   ├── model/
│   │   ├── request/
│   │   └── response/             # @JsonSerializable, often implements Entity
│   └── repositories/             # *RepoImpl implements domain repo
│
├── domain/
│   ├── entities/                 # Abstract classes / contracts (no JSON)
│   ├── repositories/             # Abstract repo interfaces (AuthRepo, …)
│   └── use_case/                 # Business orchestration (AuthUseCase, …)
│
├── presentation/
│   └── <feature>/
│       ├── cubit/                # *Cubit + *State (part file)
│       └── view/                 # *Screen builders + UI
│
├── di/
│   └── injection.dart            # Injector — manual get_it registration
│
├── l10n/                         # Flutter gen-l10n (arb + server messages)
├── widget/                       # App-level widgets (outside core/)
├── generated/                    # flutter_gen assets
└── modules/sli_common/           # Internal shared UI/helpers package
```

## Data Flow

```
Screen (presentation/.../view)
  → Cubit (presentation/.../cubit)
  → UseCase (domain/use_case)
  → Repository interface (domain/repositories)
  → Repository impl (data/repositories)
  → Remote / Local DataSource (data/datasource)
  → ApiHandler / SharedPreferences / Firebase (when used)
```

## Layer Rules

| Layer | Allowed imports | Forbidden |
|-------|----------------|-----------|
| `presentation/*` | `domain`, `core`, `di`, `l10n`, `widget` | `data` (models, datasources, repo impl) |
| `domain` | `domain` only (+ SDK) | `data`, `presentation`, `core` (keep domain pure) |
| `data` | `domain` (entities, repo interfaces), `core` | `presentation` |
| `core` | Dart SDK, pub packages | `presentation`, `data`, `domain` |

## Feature folder convention

Each screen/feature under `presentation/<feature_name>/`:

```
presentation/sign_in/
├── cubit/
│   ├── sign_in_cubit.dart
│   └── sign_in_state.dart      # part of cubit
└── view/
    └── sign_in_screen.dart
```

Register route in `lib/core/common/route.dart` (`AppPage` + `SLIPage` list).

## When to add shared code

- Reusable UI → `core/widget/` or `lib/widget/`; broader reuse → `modules/sli_common/`.
- New API domain → extend `data/datasource/remote/url_end_point.dart` + new remote DS.
- Do **not** create `lib/features/` or `lib/shared/` — those paths are not used in this base.
