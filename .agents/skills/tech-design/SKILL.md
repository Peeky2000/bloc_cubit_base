---
name: tech-design
description: >
  Turn an approved product document (spec, AC, PRD, Figma notes) into a
  technical design `tech.md`: exact files, class and field names, state shape,
  API contract, storage, patterns, tests and performance targets, aligned with
  this base and with past decisions. Use before writing feature code: when a
  PO/PM document arrives and the user asks to build it ("làm luôn",
  "triển khai", "implement"), or asks for "thiết kế kỹ thuật", "tech design",
  "triển khai kỹ thuật thế nào". Does not redesign the product. Not for a
  frontend spec fe.md (use spec-analyze) or a task breakdown after tech.md is
  approved (use plan-writer).
---

# Technical design

The input document owns the product: screens, rules, wording, flows. This
skill owns only the engineering: how to build exactly that with this base.
Never change, add or drop business behavior. When the document is ambiguous
in a way that changes behavior, list the question under "Câu hỏi nghiệp vụ"
and do not guess.

## Workflow

1. **Read the source** and give every requirement an id (`R1`, `R2`, ... or
   the document's own AC ids). Keep the original wording.
2. **Read the decision log first.** Run
   `python3 tool/decisions/decisions.py search "<topic>"` for each technical
   topic the feature touches (pagination, form, cache, upload, auth, list,
   image, realtime, permission...). Reuse every accepted decision. If the
   design must differ, propose a new decision that supersedes the old one;
   never silently diverge.
3. **Search reusable code**: app-memory
   (`python3 .agents/skills/app-memory/scripts/mem_search.py "<topic>"`),
   `sli_common` catalog, sibling features. Prefer reuse over new code.
4. **Write `docs/specs/<id>-<feature>/tech.md`** from
   [templates/tech-template.md](templates/tech-template.md). Fill every
   section; write "Không áp dụng" with a reason instead of deleting one.
   Names follow `project-convention/rules/naming.md` and paths follow
   `project-convention/references/canonical-paths.md`; the scaffold command in
   the design must produce exactly those paths.
5. **Trace**: every requirement maps to at least one design element and one
   test, and every design element maps back to a requirement or a decision.
   Anything without a requirement is scope creep: remove it.
6. **Record new decisions** with
   `python3 tool/decisions/decisions.py new "<title>" --scope feature`
   (or `--scope project` for cross-feature rules, which becomes an ADR) and
   link them in the design. Status starts as `proposed`.
7. **Ask the PM to review** `tech.md` and the proposed decisions. Code starts
   only after `Trạng thái: Approved`. On approval, set each linked decision to
   `accepted` and rebuild the index with
   `python3 tool/decisions/decisions.py index`.

## Rules that keep the app consistent

- One way per concern. If the decision log says "pagination uses
  `page`/`perPage` with `BaseListResponseModel` and `LoadingStatus.loadMore`",
  every list does that.
- Name fields after the domain words in the source document, translated
  consistently. Record new terms in the glossary section of the decision log
  so later features reuse the same word.
- Prefer existing patterns: storage in
  `flutter-datasource/references/storage-patterns.md`, SDK wrapping in
  `flutter-repository/references/async-flow-patterns.md`, effects in
  ADR-0009.
- Performance targets come from `docs/performance/ac-to-scenario.md`, marked
  proposed until the PM approves.
- Cubit unless the design states the event or concurrency need for BLoC.

## Output to the PM

A short Vietnamese summary: requirement count, new files count, decisions
reused, decisions proposed, open business questions, and the path of
`tech.md` to review.
