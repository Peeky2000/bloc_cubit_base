# Project Prerequisites

Update this file whenever the base is forked or a foundational package changes.

## Toolchain

- Flutter: pinned by `.fvmrc` (FVM is recommended, not required).
- Dart SDK: `^3.10.0`.
- Derry: `dart pub global activate derry`.
- Git submodules: required for `lib/modules/sli_common`.
- Platforms: Android and iOS.

Bootstrap a clone with `derry bootstrap`.

## Structure and dependency direction

```text
lib/presentation/  UI + Cubit/BLoC
        ↓
lib/domain/        entities, repository contracts, use cases
        ↑
lib/data/          models, data sources, repository implementations

lib/core/          application/infrastructure primitives
lib/di/            injectable composition root and generated graph
```

Required flow: `Cubit/BLoC → UseCase → Repository → DataSource`.
See [dependency rules](architecture/dependency-rules.md).

## Stack

| Concern | Implementation |
|---|---|
| State | `flutter_bloc`, `BaseCubit`/`BaseBloc`, `BaseAppState`, Equatable |
| DI | `get_it + injectable`, constructor injection, generated config |
| HTTP | Dio, `ApiHandler` / `ApiClient` |
| Models | `json_serializable` + `build_runner` |
| Local settings | `shared_preferences` through data sources |
| Secrets/tokens | `flutter_secure_storage` through `TokenProvider` |
| Navigation | `SLIRouting`, `AppPage` |
| Localization | Flutter gen-l10n, `lib/l10n/arb/` |
| Network inspection | redacted Alice integration, non-production only |
| Shared UI | `sli_common` Git submodule, Shadcn adapter |

Intentional defaults: no Freezed requirement, no HydratedBloc requirement, no
`go_router`, no Retrofit, and REST rather than GraphQL. These can be added to a
real product only after documenting the need and dependency boundaries.

## Runtime configuration

Entrypoints are `lib/main_{local,dev,staging,prod}.dart`. Configuration comes
from typed `AppConfig` and `--dart-define`, not asset-based `.env` files.

Common values:

- `API_BASE_URL`
- `ENABLE_NETWORK_INSPECTOR`

Never commit production credentials, API secrets, signing keys, provisioning
profiles, or environment files containing secrets.

## Quality commands

```bash
derry get
derry gen
derry analyze
derry test
derry quality
```

Architecture boundaries are also enforced by
`scripts/check_architecture.sh` and CI.

## AI workflow

Start from `/AGENTS.md` and `/ai-process.md`. Search existing artifacts with:

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
```
