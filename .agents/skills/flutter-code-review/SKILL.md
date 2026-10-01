---
name: flutter-code-review
description: >
  Review Flutter/Dart source or a diff for correctness, architecture, state
  transitions, lifecycle, accessibility, security and regression risk. Use for
  PR review, source audit, migration review, "review source", "soát code", or
  when asked whether Flutter code is production ready; report evidence and
  exact locations.
---

# Flutter code review

Use `project-convention` for this repo's invariants. This skill owns the review
workflow and finding quality, not the implementation rules of each layer.

## Workflow

1. Establish the requested review scope and baseline revision. Inspect the diff,
   callers, tests and relevant docs. Use app-memory/catalog when a reusable API
   is involved.
2. Trace behavior through UI → state owner → use case → repository → data
   source. For changed async code, inspect cancellation, stale callbacks,
   concurrent requests, retry and disposal paths.
3. Check user visible states: empty/loading/success/error, back/navigation,
   locale, light/dark, accessibility and small screens. Do not report a style
   preference as a correctness failure.
4. Check secrets, tokens, logs, network inspection, storage and production
   config only where the change touches them. Use `mobile-security-privacy` for
   a dedicated threat review.
5. Run focused tests and `derry quality` when feasible. State exactly what was
   executed and what remains unverified.

## Finding standard

Lead with findings ordered by impact. Each finding needs:

- priority (`P0` security/data loss, `P1` broken core flow, `P2` contained bug,
  `P3` maintainability);
- exact file and line, trigger/condition, concrete consequence, and smallest
  credible correction;
- evidence from code, a reproducer or test. Distinguish a proven bug from a
  hypothesis that requires measurement or runtime verification.

If no findings remain, say so and list residual test gaps briefly. Do not
invent findings to fill a checklist. A review request does not authorize code
edits; implement only if the user also asks for a fix.

## Repository-specific checks

- Cubit is default; BLoC needs useful event/concurrency semantics. State uses
  immutable `BaseAppState + Equatable + copyWith` and typed UI effects.
- Feature logic receives dependencies through constructors; only composition
  roots resolve `getIt`.
- Screens do not call Dio/data sources; domain does not import Flutter/data/UI.
- App UI uses stable `sli_common` APIs and does not spread direct Shadcn imports.
- Generated DI, ARB, app-memory, migration notes and catalog stay in sync.
