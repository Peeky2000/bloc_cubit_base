# ADR 0005: Keep SLIRouting

- Status: Accepted
- Date: 2026-08-26

## Decision

Keep the existing `SLIRouting`, `AppPage`, and `SLIPage` navigation stack during this
modernization.

## Consequences

Navigation migration is not coupled to architecture cleanup. State managers still must
not navigate directly; presentation consumes explicit effects and invokes routing.
