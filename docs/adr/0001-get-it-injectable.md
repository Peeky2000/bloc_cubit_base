# ADR 0001: Use GetIt with Injectable

- Status: Accepted
- Date: 2026-08-26

## Decision

Use GetIt as the container and Injectable to generate owned-class registrations.
Runtime environment selection and external SDK providers remain explicit at the
composition root. All feature dependencies use constructor injection.

## Consequences

Registration drift and large manual setup methods are removed. Generated code becomes
part of the build pipeline, so code generation and graph-resolution tests are required.
