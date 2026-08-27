# ADR 0006: Build the UI Toolkit Now and Defer Product Capabilities

- Status: Accepted
- Date: 2026-08-26

## Decision

Integrate `sli_common` as a real submodule and add a Shadcn-backed reusable component
layer in the current modernization. Defer GraphQL, deep links, FCM, and advanced
VIPER/AI integration.

## Consequences

UI reuse and design consistency become part of the base foundation. Product-specific
capabilities remain outside the critical migration path.
