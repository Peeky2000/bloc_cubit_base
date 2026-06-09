---
name: spec-checklists
description: "Analyze spec (fe.md) and generate technical checklists. Use when: (1) fe.md exists and checklists are needed (entity, model, repository, api, route, validation, utility, widget/component, bloc-cubit, page), (2) creating docs/specs/{id}-{name}/checklists/ and summarize, (3) user asks to review existing checklists for template alignment, consistency, and placeholder removal, (4) user provides a doc-review file and asks to fix checklist issues — apply only Need Fix items. Covers validating fe.md path, template mapping, processing each part, verifying codebase paths, creating summarize.md, reviewing checklists, and targeted checklist fixes from review."
---

# Spec Checklists

## Overview

Three modes:

- **Generate checklists** — analyze `fe.md` and produce checklists in order: entity → model → repository → use-case → api → route → validation → utility → component → bloc-cubit → page (base paths — see `project-convention/references/canonical-paths.md`).
- **Review checklists** — review existing checklist files for template alignment, consistency with `fe.md`, placeholder removal, and summarize accuracy.
- **Fix checklists** — read a doc-review file and apply targeted fixes to checklist files for issues marked Need Fix = ✓.

## Workflow Decision Tree

- **User provides a spec path / fe.md path and asks to generate checklists** → [Generate checklists](references/workflows/workflow-spec-checklists.md)
- **User asks to review checklists / "review checklist"** → [Review checklists](references/workflows/review-checklists.md)
- **User provides a doc-review file path or asks to fix checklist issues** → [Fix checklists](references/workflows/fix-checklists.md)

If unclear, ask: "Bạn muốn generate checklists mới, review checklists hiện tại, hay fix checklists từ review file?"

---

## Generate Checklists — Quick Reference

**Full workflow** → [references/workflows/workflow-spec-checklists.md](references/workflows/workflow-spec-checklists.md)

| Step | Purpose |
|------|----------|
| 1 | Validate input — path to `docs/specs/{id}-{name}/fe.md` |
| 2 | Build mapping table part → template; present it then proceed to Step 3 |
| 3 | Process each part in sequence (3.1 needed or not → 3.2 read template → 3.3 list files → 3.4 analyze/verify path → 3.5 generate → 3.6 verify) |
| 4 | Create `checklists/summarize.md` grouped by type in the correct order |
| 5 | Report: list of generated files, skipped parts, path to summarize.md |

## Critical rules (Generate)

- **Widget & Utility:** create checklist only when Status = "Create new" or spec explicitly indicates modifications; skip when Reuse with no modifications.
- **Entity, Model, Repository, BLoC/Cubit:** always create a checklist (including Reuse) — purpose: verify structure.
- **Path:** grep/glob to verify actual path in the project before filling Location.

---

## Review Checklists — Quick Reference

**Full workflow** → [references/workflows/review-checklists.md](references/workflows/review-checklists.md)

| Step | Purpose |
|------|----------|
| 1 | Validate input — spec path must contain `checklists/summarize.md` and all linked files |
| 2 | Read fe.md, summarize.md, all checklist files, and their type templates |
| 3 | Run script to create review file; set Review type to `Checklist` |
| 4 | List all checklist files in "Documents to review" table |
| 5 | Review each file (template alignment → consistency with fe.md → placeholders → summarize match) |
| 6 | Finalize review file (Executive Summary + Acceptance) and report |

---

## Fix Checklists — Quick Reference

**Full workflow** → [references/workflows/fix-checklists.md](references/workflows/fix-checklists.md)

| Step | Purpose |
|------|----------|
| 1 | Validate input — must be `docs/specs/{spec}/reviews/doc-*.md` with Review type: Checklist or Both |
| 2 | Extract issues where Need Fix = ✓; stop if none |
| 3 | Load fe.md + affected checklist files + matching templates for context |
| 4 | For each Need Fix issue: understand → determine fix → apply to checklist file |
| 5 | Report: issues fixed, issues skipped |

---

## Resources

- **Generate checklists workflow** → [references/workflows/workflow-spec-checklists.md](references/workflows/workflow-spec-checklists.md)
- **Review checklists workflow** → [references/workflows/review-checklists.md](references/workflows/review-checklists.md)
- **Fix checklists workflow** → [references/workflows/fix-checklists.md](references/workflows/fix-checklists.md)
- **Review criteria** → [references/review-contents/checklist.md](references/review-contents/checklist.md)
- **Rules by checklist type** → [rules/checklists/index.md](rules/checklists/index.md)
  - [rules/checklists/sections/entity.md](rules/checklists/sections/entity.md)
  - [rules/checklists/sections/data-model.md](rules/checklists/sections/data-model.md)
  - [rules/checklists/sections/repository.md](rules/checklists/sections/repository.md)
  - [rules/checklists/sections/api.md](rules/checklists/sections/api.md)
  - [rules/checklists/sections/route.md](rules/checklists/sections/route.md)
  - [rules/checklists/sections/validation.md](rules/checklists/sections/validation.md)
  - [rules/checklists/sections/utility.md](rules/checklists/sections/utility.md)
  - [rules/checklists/sections/component.md](rules/checklists/sections/component.md)
  - [rules/checklists/sections/bloc-cubit.md](rules/checklists/sections/bloc-cubit.md)
  - [rules/checklists/sections/page.md](rules/checklists/sections/page.md)
- **Process by part (Step 3)** — for each part, read the matching analyze reference:
  - [references/analyzes/process-entity.md](references/analyzes/process-entity.md)
  - [references/analyzes/process-data-model.md](references/analyzes/process-data-model.md)
  - [references/analyzes/process-repository.md](references/analyzes/process-repository.md)
  - [references/analyzes/process-api.md](references/analyzes/process-api.md)
  - [references/analyzes/process-route.md](references/analyzes/process-route.md)
  - [references/analyzes/process-validation.md](references/analyzes/process-validation.md)
  - [references/analyzes/process-utility.md](references/analyzes/process-utility.md)
  - [references/analyzes/process-component.md](references/analyzes/process-component.md)
  - [references/analyzes/process-bloc-cubit.md](references/analyzes/process-bloc-cubit.md)
  - [references/analyzes/process-page.md](references/analyzes/process-page.md)
- **Create checklists dir (run when starting)** → `./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh <spec-dir-or-fe.md>` (from project root).
- **Create checklist files (per part)** → `./.agents/skills/spec-checklists/scripts/create-checklist-files.sh <spec-dir-or-fe.md> <part> <entity1> [entity2 ...]`
- **Create review file** → `./.agents/skills/spec-checklists/scripts/create-review-file.sh <spec-path>` (from project root)
- **Checklist templates** → `.agents/skills/spec-checklists/templates/checklists/{entity,data-model,repository,api,route,validation,utility,component,bloc-cubit,page}.md`
- **Summarize template** → `.agents/skills/spec-checklists/templates/summarize-template.md`
