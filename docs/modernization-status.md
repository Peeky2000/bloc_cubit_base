# Modernization Status — 2026-08-27

This document distinguishes completed architecture work from remaining legacy
cleanup. “Implemented” means code and a relevant gate exist; it does not mean
all historical analyzer debt has disappeared.

## Implemented

- Typed local/development/staging/production configuration and centralized
  bootstrap.
- FVM/Derry scripts, CI skeleton, code generation, architecture boundary gate,
  and application tests.
- `get_it + injectable`, generated graph, runtime module, and constructor
  injection across the current feature dependency graph.
- Pure-domain boundary corrections and presentation-to-data import checks.
- Cubit default plus `BaseBloc` support; immutable Equatable base state.
- Redacted non-production Alice inspector, secure token storage migration,
  single-flight session refresh, and no network-layer UI navigation.
- Real `sli_common` Git submodule with public `Sli*` API, tokens, themes, Shadcn
  facade, package docs, example, and tests.
- Architecture index, ADRs, contributor guides, and AI agent/skill alignment.
- Personal provisioning profiles and hard-coded iOS provisioning identifiers
  removed; signing material is now ignored and must come from the local machine
  or CI secrets.

## Verified baseline

- Application tests: 11 passing.
- `sli_common` tests: 3 passing.
- Architecture boundary script: passing at the time of this migration.
- New `sli_common` sources/tests/example: analyzer clean.
- Application analyzer reduced from 162 findings to zero; the full application
  analyzer gate now passes.
- Full legacy `sli_common` analyzer still reports historical issues outside the
  new `lib/src`, test, and example scope.

## Remaining before a zero-debt template release

1. Remove BuildContext/navigation/dialog side effects from legacy feature Cubits
   and replace the compatibility global handler with explicit UI listeners.
2. Add tests for concurrent 401 refresh/failure and offline interception.
3. Migrate duplicated `lib/core/widget` components to `sli_common` using
   compatibility adapters and a behavior matrix.
4. Neutralize remaining DeliveryGo/mOrder sample branding, native identifiers,
   Firebase sample configuration, endpoints, and sample product slices.
5. Add a safe dry-run app rename/create script and validate a generated clone.
6. Burn down the remaining legacy `sli_common` analyzer baseline, then expand
   its scoped clean gate to the complete historical package.

These are tracked in
[`docs/plan/2026-08-26-base-modernization.md`](plan/2026-08-26-base-modernization.md).
