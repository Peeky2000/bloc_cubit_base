# ADR 0003: Keep Equatable Application State

- Status: Accepted
- Date: 2026-08-26

## Decision

Keep immutable `BaseAppState`, Equatable, and manual `copyWith`. Do not migrate default
state classes to Freezed or HydratedBloc.

## Consequences

State remains explicit and generator-light. Review and tests must enforce immutable
fields, complete `props`, and unambiguous `copyWith` nullable-field behavior.
