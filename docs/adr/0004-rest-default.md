# ADR 0004: Use REST by Default

- Status: Accepted
- Date: 2026-08-26

## Decision

REST/Dio is the default network stack. GraphQL is an optional removable module added
only when a real product requires it.

## Consequences

The base avoids unused schema/codegen dependencies while retaining a documented
extension point.
