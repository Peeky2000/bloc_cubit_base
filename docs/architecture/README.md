# Architecture

`bloc_cubit_base` is a reusable Flutter application base built around Clean
Architecture. This directory is the source of truth for structural decisions; code,
tests, automation, and `.agents` instructions must agree with it.

## Core decisions

- [Dependency rules](dependency-rules.md)
- [Dependency injection](dependency-injection.md)
- [State management](state-management.md)
- [Environment and bootstrap](environment-bootstrap.md)
- [Networking](networking.md)
- [UI toolkit](ui-toolkit.md)
- [Optional capabilities](optional-capabilities.md)

## Dependency flow

```text
presentation -> domain <- data
      |            ^        |
      +---------- core -----+
```

Feature flow is `UI -> Cubit/BLoC -> UseCase -> Repository -> DataSource`.
Composition happens only in `lib/di`. Runtime infrastructure may depend on `core`
contracts, but domain code never imports data or presentation code.

## Decision records

See [`docs/adr`](../adr/README.md). A behavior-changing architecture decision requires
an ADR before implementation.
