---
name: spec-analyze
description: 'Analyze design/requirements and generate frontend spec (fe.md). Use when: (1) user provides UI screenshot, Figma link, requirement description, documentation link, or Stitch Screen ID and asks to generate a spec, (2) creating docs/specs/{id}-{name}/fe.md from design, (3) user provides a doc-review file and asks to fix fe.md issues — apply only Need Fix items, (4) user asks to review an existing fe.md for completeness, clarity, and consistency. Covers input validation, gathering design/requirements, app-memory reuse check, template fill, output to docs/specs/, targeted spec fixes from review, and spec-fe review.'
---

# Spec Analyze

## Overview

Three modes:

- **Generate spec** — analyze design/requirements and produce `fe.md` following the standard template.
- **Fix spec-fe** — read a doc-review file and apply targeted fixes to `fe.md` for issues marked Need Fix = ✓.
- **Review spec-fe** — review an existing `fe.md` for completeness, requirements clarity, and internal consistency.

## Workflow Decision Tree

- **User provides screenshot / Figma / description / doc link / Stitch ID** → [Generate spec](references/workflows/new-spec.md)
- **User provides a doc-review file path or asks to fix spec issues** → [Fix spec-fe](references/workflows/fix-spec-fe.md)
- **User asks to review fe.md or "review spec"** → [Review spec-fe](references/workflows/review-spec-fe.md)

If unclear, ask: "Bạn muốn generate spec mới, fix fe.md từ review file, hay review fe.md hiện tại?"

---

## Generate Spec — Quick Reference

**Full workflow** → [references/workflows/new-spec.md](references/workflows/new-spec.md)

| Step | Purpose                                                                                                 |
| ---- | ------------------------------------------------------------------------------------------------------- |
| 1    | Validate input — require at least one: screenshot, Figma, description, doc link, Stitch ID              |
| 2    | Read docs/prerequisites.md; for each input type run the matching analysis flow (see Resources)          |
| 3    | Create spec folder early (naming script → create-spec-folder.py); save design references                |
| 4    | Load skills: design-to-code, ui-ux-pro-max, app-memory, flutter-model-entity, flutter-repository, flutter-datasource, flutter-bloc-cubit, flutter-router; deep analysis; fill §2 + §4 Questions |
| 5    | Fill §6.1–§6.10 (Entity→Model→Repo+UseCase→DataSource→Validation→Widget→Cubit→Screen→Route); paths per `project-convention/references/canonical-paths.md`; mem_search for reuse |
| 6    | Finalize §3/§5/§7/§8/§9; report path to fe.md                                                          |

---

## Fix Spec-FE — Quick Reference

**Full workflow** → [references/workflows/fix-spec-fe.md](references/workflows/fix-spec-fe.md)

| Step | Purpose                                                                                         |
| ---- | ----------------------------------------------------------------------------------------------- |
| 1    | Validate input — must be `docs/specs/{spec}/reviews/doc-*.md` with Review type: Spec-FE or Both |
| 2    | Extract issues where Need Fix = ✓; stop if none                                                 |
| 3    | Load fe.md + original design references (screen.html, screen.png) for context                   |
| 4    | For each Need Fix issue: understand → determine fix → apply to fe.md                            |
| 5    | Report: issues fixed, issues skipped                                                            |

---

## Review Spec-FE — Quick Reference

**Full workflow** → [references/workflows/review-spec-fe.md](references/workflows/review-spec-fe.md)

| Step | Purpose                                                                                        |
| ---- | ---------------------------------------------------------------------------------------------- |
| 1    | Validate input — spec directory must contain `fe.md`                                           |
| 2    | Read spec-fe-template.md + fe.md in full                                                       |
| 3    | Run script to create review file at `{spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md`                |
| 4    | List fe.md in "Documents to review" table                                                      |
| 5    | Review: apply template alignment, requirements clarity, internal consistency, quality criteria |
| 6    | Finalize review file (Executive Summary + Acceptance) and report                               |

---

## Resources

- **Generate spec workflow** → [references/workflows/new-spec.md](references/workflows/new-spec.md)
- **Fix spec-fe workflow** → [references/workflows/fix-spec-fe.md](references/workflows/fix-spec-fe.md)
- **Review spec-fe workflow** → [references/workflows/review-spec-fe.md](references/workflows/review-spec-fe.md)
- **Review criteria (by section)** → [references/review-contents/spec-fe.md](references/review-contents/spec-fe.md)
- **Analysis flows (by input type)**:
  - [references/analyzes/analyze-figma.md](references/analyzes/analyze-figma.md)
  - [references/analyzes/analyze-screenshot.md](references/analyzes/analyze-screenshot.md)
  - [references/analyzes/analyze-stitch.md](references/analyzes/analyze-stitch.md)
  - [references/analyzes/analyze-description.md](references/analyzes/analyze-description.md)
- **Spec naming guide** → [references/workflows/spec-naming-guide.md](references/workflows/spec-naming-guide.md)
- **Section fill/review rules** → [rules/fe-spec/index.md](rules/fe-spec/index.md)
- **Create spec folder (run first)** → `python .agents/skills/spec-analyze/scripts/create-spec-folder.py <slug>` (from project root)
- **Create review file** → `python .agents/skills/spec-analyze/scripts/create-review-file.py <spec-path>` (from project root)
- **Spec template** → `.agents/skills/spec-analyze/templates/spec-fe-template.md`
