# Fix Checklists

Use this workflow to apply fixes to checklist files based on issues flagged in a doc-review file.

Only issues marked **Need Fix = ✓** in the review file will be addressed. All other issues are skipped.

---

## Required Input

| Input | Description |
|-------|-------------|
| Review file path | Path to a doc review file, e.g. `docs/specs/003-login-light-mode/reviews/doc-2026-03-04-15-42-12.md` |

---

## Flow Overview

1. **Validate** — confirm the file is a valid Checklist doc review.
2. **Read review file** — extract issues where Need Fix = ✓.
3. **Load spec inputs** — read `fe.md` and the affected checklist files for context.
4. **Fix each issue** — apply targeted edits to the corresponding checklist file(s).
5. **Report** — summarize what was fixed.

---

## Step 1 — Validate Input

### 1.1 Check path format

- The provided path must match the pattern: `docs/specs/{spec-name}/reviews/doc-*.md`
- If it does not → reply:
  > *"The provided file does not appear to be a spec doc-review file. Please provide a path like `docs/specs/{spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md`."*

  Then **stop**.

### 1.2 Read the review file

- Read the full content of the file.
- Verify it contains:
  - A title starting with `# Doc Review`
  - `**Review type:**` field set to `Checklist` or `Both`
- If either check fails → reply:
  > *"This file is not a Checklist doc review. Fix Checklists only applies to review files with Review type: Checklist or Both."*

  Then **stop**.

---

## Step 2 — Extract Issues to Fix

- Read the **Issues** table in the review file.
- Collect all rows where the **Need Fix** column = `✓`.
- If **no rows** have Need Fix = ✓ → reply:
  > *"No issues are marked Need Fix (✓) in this review. Nothing to fix."*

  Then **stop**.
- Note the spec directory from the path: `docs/specs/{spec-name}/`.
- Group the collected issues by **Document** (checklist file path) — each unique checklist file will be processed separately.

---

## Step 3 — Load Spec Inputs

**Do not skip.** Read all available inputs before making any edits.

1. Read `{spec}/fe.md` — full content, to understand the source of truth for names, fields, paths, props, and API definitions.
2. For each **checklist file** referenced in the collected issues, read its current content.
3. For each checklist **type** involved (entity, data-model, repository, api, route, validation, utility, component, bloc-cubit, page), read the corresponding template from `.agents/skills/spec-checklists/templates/checklists/{type}.md` — to understand correct structure.

---

## Step 4 — Fix Each Issue (Loop)

For **each** issue where Need Fix = ✓ (one at a time, grouped by checklist file):

### 4.1 Understand the issue

- Read the **Location**, **Description**, **Issue type**, and **Details** columns of that row.
- Navigate to the referenced section in the checklist file.
- Re-read that section in full alongside the relevant section of `fe.md`.

### 4.2 Determine the fix

Based on Issue type:

| Issue type | Fix approach |
|------------|--------------|
| `Template mismatch` | Restructure the section to match the checklist template for this type. |
| `Missing section` | Add the missing section or table block from the template, filled with values from `fe.md`. |
| `Inconsistency with fe.md` | Align the checklist value (name, field, prop, path, API) with the exact value in `fe.md`. |
| `Placeholder left` | Replace `{}`, `{ComponentName}`, `<!-- Note: ... -->`, or TODO with real values from `fe.md` or spec context. |
| `Wrong path` | Correct the file path to match project conventions; verify with grep/glob if codebase exists. |
| `Summarize mismatch` | Update `checklists/summarize.md` — fix the link, type grouping, or file path for this checklist. |

### 4.3 Apply the fix

- Edit the checklist file directly — make only the targeted change described by the issue.
- Do not rewrite unrelated sections.
- After editing, re-read the affected section to confirm the fix resolves the issue.

### 4.4 Next issue

- Move to the next row with Need Fix = ✓.
- Repeat from 4.1 until all such issues are processed.

---

## Step 5 — Report

Reply to the user with:

```
## Fix Checklists Summary

**Spec:** {spec directory}
**Review file:** {review file path}

### Issues fixed ({N} total)
- `{checklist file}` §{section} — {brief description of fix}
- ...

### Issues skipped (Need Fix not marked)
{Count} issues were not marked Need Fix and were left untouched.
```
