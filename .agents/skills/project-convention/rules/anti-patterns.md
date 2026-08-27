# Anti-Patterns

## Hidden dependency resolution

Wrong: a Cubit, UseCase, repository, or data source calls `getIt()` or
`Injector.getIt`. Correct: declare every dependency in its constructor and let
injectable generate the graph.

## Layer shortcuts

- UI calling Dio, a data source, or repository directly.
- Cubit/BLoC calling a repository instead of a UseCase.
- Presentation importing data models or implementations.
- Domain importing Flutter, core infrastructure, data, presentation, or DI.
- Data/network interceptors navigating or showing dialogs.

## State mistakes

- Mutable state fields, incomplete Equatable props, or in-place list mutation.
- A feature Cubit/BLoC registered as a singleton.
- Awaiting work without first emitting loading or without a terminal state.
- Keeping BuildContext, localized strings, controllers, or navigation calls in
  state/business logic.
- Resolving a Cubit from `build()`, creating a fresh instance every rebuild.

## Data and security mistakes

- Swallowing transport errors and returning fake empty success values.
- Product filtering/rules in a transport-only data source.
- Credentials in SharedPreferences, source code, asset `.env`, logs, or Alice.
- Raw Dio/CURL logging, production inspectors, or refresh-token stampedes.
- Returning data models across the domain/presentation boundary.

## UI ownership mistakes

- Duplicating a reusable component already present in `sli_common`.
- Importing `shadcn_flutter` directly throughout product screens instead of the
  stable `Sli*` facade.
- Putting product-specific behavior into the shared toolkit.
- Hardcoded user-facing strings, colors, typography, or undersized touch targets.

## Generated code and docs

- Editing `injection.config.dart` or `*.g.dart` manually.
- Changing an architecture convention without updating its doc/ADR/skills.
- Reporting a quality gate as passing when analyzer debt remains.
