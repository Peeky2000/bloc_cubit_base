---
name: flutter-code-review
description: >
  Review Flutter/Dart source or a diff for correctness, architecture, state
  transitions, lifecycle, accessibility, security and regression risk. Use for
  PR review, source audit, migration review, "review source", "soát code", or
  when asked whether Flutter code is production ready; report evidence and
  exact locations. For a general review of a diff that touches auth, tokens,
  PII, logs or deep links, also load mobile-security-privacy. Not for a
  security-only check such as "PR này có lộ token/API key không" (use
  mobile-security-privacy alone).
---

# Flutter code review

Use `project-convention` for this repo's invariants. This skill owns the review
workflow and finding quality, not the implementation rules of each layer.

## Workflow

1. **Plan the files deterministically.** Run
   `dart run tool/review/plan.dart` for workspace changes, or
   `dart run tool/review/plan.dart --from=<base> --to=<head>` for a branch.
   It lists every reviewable file, every excluded file with its reason, and
   the rule group (checks and skills) for each file. Make a checklist from
   `reviewable_files`; never pick files by hand.
2. Review group by group. Load only the skills of that group and apply its
   checks to each file's diff (`git diff <base>...<head> -- <path>`; read
   untracked files whole). Inspect callers, tests and docs as needed. Use
   app-memory/catalog when a reusable API is involved.
3. Trace behavior through UI → state owner → use case → repository → data
   source. For changed async code, inspect cancellation, stale callbacks,
   concurrent requests, retry and disposal paths.
4. Check user visible states: empty/loading/success/error, back/navigation,
   locale, light/dark, accessibility and small screens. Do not report a style
   preference as a correctness failure.
5. Check secrets, tokens, logs, network inspection, storage and production
   config only where the change touches them. Use `mobile-security-privacy` for
   a dedicated threat review.
6. **Try to refute each finding before reporting it.** Re-read the cited
   lines, look for the guard or test that would make it a non-issue, and drop
   it if one exists. When the platform supports subagents, give each
   high-priority finding to a fresh verifier that did not write it.
7. Run focused tests and `derry quality` when feasible. State exactly what was
   executed and what remains unverified.
8. **Report coverage:** reviewed files / reviewable files, and every skipped
   file with a concrete reason. A review with unexplained gaps is incomplete.

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

## Rules

Rule groups live in `tool/review/rules.json`, ordered from most to least
specific. Add or tighten a rule there when a convention changes, and add a
case to `test/tool/review/review_plan_test.dart`. The deterministic file
selection and rule matching approach is adapted from
[alibaba/open-code-review](https://github.com/alibaba/open-code-review)
(Apache-2.0); no OCR code or CLI is used.
