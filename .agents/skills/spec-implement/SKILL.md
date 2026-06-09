---
name: spec-implement
description: 'Implement spec from checklists — one checklist file at a time, load Flutter skills per type, until all are done. Use when: (1) spec directory already has full checklists, (2) need to implement every unchecked checklist in summarize order. Checklist types: entity, data-model, repository, api, route, validation, utility, component, bloc-cubit, page. Covers validating spec-dir, reading summarize to build pending list, loading correct Flutter skill per type, executing tasks, marking [x], code review when done, and reporting.'
---

# Spec Implement

## Overview

One mode:

- **Implement checklists** — read `checklists/summarize.md`, then implement every unchecked checklist in order: load Flutter skills per type → execute tasks → mark `[x]` → move to next. Code review after all done.

## Workflow Decision Tree

- **User provides a spec path and asks to implement** → [Implement checklists](references/workflows/workflow-spec-implement.md)

If unclear, ask: "Vui lòng cung cấp đường dẫn spec directory đã có đủ checklists (e.g. `docs/specs/001-add-abc`)."

---

## Implement Checklists — Quick Reference

**Full workflow** → [references/workflows/workflow-spec-implement.md](references/workflows/workflow-spec-implement.md)

| Step | Purpose |
|------|---------|
| 1 | Validate input — spec directory must contain `checklists/summarize.md` and all linked checklist files |
| 2 | Read summarize, parse checkboxes, build pending list (all 10 types); read `fe.md` for context |
| 3 | For each pending file: 3.1 load Flutter skills by type → 3.2 (component/page) load design refs → 3.3 execute tasks, mark `[x]` per task immediately → 3.4 mark `[x]` in summarize, move to next |
| 4 | Code review — against checklist requirements and `.cursor/rules/`; fix until no errors remain |
| 5 | Report: list of implemented files, path to summarize, summary of review fixes |

**Checklist types (in summarize order):**

| Type | Folder | Flutter skills |
|------|--------|---------------|
| `entity` | `entity/` | `flutter-model-entity` |
| `data-model` | `data-model/` | `flutter-model-entity` |
| `repository` | `repository/` | `flutter-repository`, `flutter-di`, `flutter-error-handling` |
| `api` | `api/` | `flutter-datasource`, `flutter-di`, `flutter-error-handling` |
| `route` | `route/` | `flutter-router` |
| `validation` | `validation/` | — |
| `utility` | `utility/` | `app-memory` |
| `component` | `component/` | `flutter-atomic-design`, `flutter-translations`, `app-memory` |
| `bloc-cubit` | `bloc-cubit/` | `flutter-bloc-cubit`, `flutter-di`, `flutter-error-handling` |
| `page` | `page/` | `flutter-atomic-design`, `flutter-bloc-cubit`, `flutter-translations` |

---

## Resources

- **Implement checklists workflow** → [references/workflows/workflow-spec-implement.md](references/workflows/workflow-spec-implement.md)
- **Critical rules** → [rules/implement/index.md](rules/implement/index.md)
