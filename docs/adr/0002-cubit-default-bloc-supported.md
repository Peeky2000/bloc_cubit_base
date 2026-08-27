# ADR 0002: Use Cubit by Default and Support BLoC

- Status: Accepted
- Date: 2026-08-26

## Decision

Use Cubit for most screens. Use classic BLoC for meaningful event concurrency,
debouncing, multiple producers, or auditable event flows. Both depend on use cases and
are factory-scoped.

## Consequences

The common path stays compact without removing BLoC capabilities. Guides and templates
must explain the selection rule and test both patterns.
