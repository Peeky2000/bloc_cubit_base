# Flutter Bloc/Cubit Base

Personal production-oriented Flutter base built on Clean Architecture, typed
environments, Cubit/BLoC, generated dependency injection, secure networking,
and a reusable UI toolkit.

## Architecture at a glance

```text
Screen → Cubit/BLoC → UseCase → Repository interface → RepositoryImpl
       → Remote/Local DataSource → Dio / platform service
```

- Cubit is the default for straightforward feature state; classic BLoC is
  supported for event-heavy or concurrent workflows.
- States use `BaseAppState + Equatable + copyWith`. Freezed and HydratedBloc are
  intentionally not base requirements.
- REST through `ApiHandler` is the default. GraphQL is an optional capability.
- DI uses `get_it + injectable`; feature classes use constructor injection.
- Routing remains `SLIRouting / AppPage`.
- `sli_common` is a Git submodule and owns reusable UI, design tokens, and the
  Shadcn adapter. Product code imports the toolkit API, not Shadcn directly.

Detailed rules: [architecture index](docs/architecture/README.md) ·
[ADRs](docs/adr/README.md) · [AI workflow](ai-process.md).

## Quick start

Requirements are documented in [docs/prerequisites.md](docs/prerequisites.md).

```bash
git clone --recurse-submodules <repository-url>
cd bloc_cubit_base
dart pub global activate derry
derry bootstrap
derry run dev
```

For an existing clone:

```bash
git submodule sync --recursive
git submodule update --init --recursive
derry get
derry gen
```

The scripts use FVM when available and fall back to the Flutter executable on
`PATH`. The pinned Flutter version is in `.fvmrc`.

## Environments

Entrypoints only choose a typed environment; `bootstrap()` performs startup in
one deterministic place.

| Environment | Entrypoint | Inspector |
|---|---|---|
| local | `lib/main_local.dart` | enabled |
| development | `lib/main_dev.dart` | enabled |
| staging | `lib/main_staging.dart` | enabled |
| production | `lib/main_prod.dart` | disabled |

Runtime values use `--dart-define`:

```bash
./scripts/flutterw.sh run -t lib/main_dev.dart \
  --dart-define=API_BASE_URL=https://dev.example.com \
  --dart-define=ENABLE_NETWORK_INSPECTOR=true
```

Production rejects non-HTTPS URLs and a network inspector enabled by mistake.
See [environment and bootstrap](docs/architecture/environment-bootstrap.md).

## Daily commands

```bash
derry gen       # build_runner + formatting
derry analyze   # analyzer + architecture boundary checks
derry test      # app tests
derry quality   # formatting, analyzer, boundaries, tests
```

Generated DI lives in `lib/di/injection.config.dart`. Do not edit it manually.
Annotate classes, inject dependencies through constructors, then run `derry gen`.
Runtime/platform dependencies remain explicit in `lib/di/register_module.dart`.

## UI toolkit

`lib/modules/sli_common` points to the standalone `sli_common` repository. Use
its stable `Sli*` APIs for reusable components and tokens. Shadcn is an
implementation detail behind that facade, so an application can theme or swap
it without coupling every screen to a third-party API.

See [using sli_common](docs/guides/use-sli-common.md) and
[UI toolkit architecture](docs/architecture/ui-toolkit.md).

## Creating features and apps

- [Create an app from this base](docs/guides/create-app-from-base.md)
- [Add a Clean Architecture feature](docs/guides/add-feature.md)
- [Choose Cubit or BLoC](docs/guides/choose-cubit-or-bloc.md)
- [Add an environment](docs/guides/add-environment.md)
- [Current modernization status](docs/modernization-status.md)

AI agents must start with [AGENTS.md](AGENTS.md). Package and application
identifiers are template values and must be changed when this base is forked.
