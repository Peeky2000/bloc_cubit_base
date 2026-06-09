# Fix Spec-FE

Use this workflow to apply fixes to a `fe.md` based on issues flagged in a doc-review file.

Only issues marked **Need Fix = ✓** in the review file will be addressed. All other issues are skipped.

---

## Required Input

| Input | Description |
|-------|-------------|
| Review file path | Path to a doc review file, e.g. `docs/specs/003-login-light-mode/reviews/doc-2026-03-04-15-42-12.md` |

---

## Flow Overview

1. **Validate** — confirm the file is a valid Spec-FE doc review.
2. **Read review file** — extract issues where Need Fix = ✓.
3. **Load spec inputs** — read fe.md and original design references for context.
4. **Fix each issue** — apply targeted edits to fe.md.
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
  - `**Review type:**` field set to `Spec-FE` or `Both`
- If either check fails → reply:
  > *"This file is not a Spec-FE doc review. Fix Spec-FE only applies to review files with Review type: Spec-FE or Both."*
  
  Then **stop**.

---

## Step 2 — Extract Issues to Fix

- Read the **Issues** table in the review file.
- Collect all rows where the **Need Fix** column = `✓`.
- If **no rows** have Need Fix = ✓ → reply:
  > *"No issues are marked Need Fix (✓) in this review. Nothing to fix."*
  
  Then **stop**.
- Note the spec directory from the path: `docs/specs/{spec-name}/`.

---

## Step 3 — Load Spec Inputs

**Do not skip.** Read all available inputs before making any edits.

1. Read `{spec}/fe.md` — current full content.
2. Read `{spec}/references/screen.html` — if it exists (original design reference).
3. Read `{spec}/references/screen.png` — if it exists (visual design reference).
4. Read `.agents/skills/spec-analyze/templates/spec-fe-template.md` — to verify section structure when fixing template-related issues.

Use these inputs to understand the original intent of the spec before applying any fix.

---

## Step 4 — Fix Each Issue (Loop)

For **each** issue where Need Fix = ✓ (one at a time):

### 4.1 Understand the issue

- Read the **Location**, **Description**, **Issue type**, and **Details** columns of that row.
- Navigate to the referenced section in `fe.md`.
- Re-read that section in full.

### 4.2 Determine the fix

Based on Issue type:

| Issue type | Fix approach |
|------------|--------------|
| `Template mismatch` | Restructure the section to match the spec-fe template. |
| `Missing section` | Add the missing section or sub-section with appropriate content. |
| `Requirements unclear` | Rewrite the section so it is self-contained and understandable without external design context. Use design references (screen.html / screen.png) for factual details. |
| `Inconsistency` | Reconcile the two conflicting sections (e.g. align §6.3 with §7.2, or §6.4 with §3.1). |
| `Placeholder left` | Replace placeholder with real content derived from the spec context or design reference. |
| `Wrong path` | Correct the file path to match project conventions; verify with glob/grep if codebase exists. |

### 4.3 Apply the fix

- Edit `fe.md` directly — make the targeted change described by the issue.
- Do not rewrite unrelated sections.

### 4.4 Verify the fix

After editing, re-read the affected section and confirm **both** checks pass before moving on:

**Check 1 — Input correctness:** Every factual value in the fixed section (field names, colors, paths, labels, API shapes, component names) must be traceable to a loaded input:
- Design references (`screen.html`, `screen.png`) for visual/structural details.
- `fe.md` (other sections) for cross-section alignment.
- Project conventions for paths and naming.
- No invented, assumed, or approximated values are acceptable.

**Check 2 — Rule conformance:** The fixed section must satisfy the Fill rules for its section type. Load the matching rule file and verify:

| Section | Rule file |
|---------|-----------|
| §6.1 (Entity) | [6.1-entity.md](../rules/fe-spec/sections/6.1-entity.md) |
| §6.2 (Model) | [6.2-model.md](../rules/fe-spec/sections/6.2-model.md) |
| §6.3 (Repository) | [6.3-repository.md](../rules/fe-spec/sections/6.3-repository.md) |
| §6.4 (API) | [6.4-api.md](../rules/fe-spec/sections/6.4-api.md) |
| §6.5 (Validation) | [6.5-validation.md](../rules/fe-spec/sections/6.5-validation.md) |
| §6.6 (Utility) | [6.6-utility.md](../rules/fe-spec/sections/6.6-utility.md) |
| §6.7 (Widget) | [6.7-widget.md](../rules/fe-spec/sections/6.7-widget.md) |
| §6.8 (BLoC/Cubit) | [6.8-bloc-cubit.md](../rules/fe-spec/sections/6.8-bloc-cubit.md) |
| §6.9 (Page) | [6.9-page.md](../rules/fe-spec/sections/6.9-page.md) |
| §6.10 (Route) | [6.10-route.md](../rules/fe-spec/sections/6.10-route.md) |

If a check fails → go back to **4.2** and re-determine the fix before applying again.

### 4.5 Next issue

- Move to the next row with Need Fix = ✓.
- Repeat from 4.1 until all such issues are processed.

---

## Step 5 — Report

Reply to the user with:

```
## Fix Spec-FE Summary

**Spec:** {spec directory}
**Review file:** {review file path}
**fe.md:** {spec}/fe.md

### Issues fixed ({N} total)
- §{section} — {brief description of fix}
- ...

### Issues skipped (Need Fix not marked)
{Count} issues were not marked Need Fix and were left untouched.
```
