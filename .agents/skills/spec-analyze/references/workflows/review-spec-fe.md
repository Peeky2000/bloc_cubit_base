# Review Spec-FE

Use this workflow when reviewing a frontend spec document (`fe.md`) for completeness, template alignment, requirements clarity, and internal consistency.

## Required Inputs

| Input | Location |
|-------|----------|
| Spec directory | e.g. `docs/specs/001-add-abc/` |
| Spec doc | `{spec}/fe.md` |
| Spec template | `.agents/skills/spec-analyze/templates/spec-fe-template.md` |
| Design references (optional) | `{spec}/references/screen.html`, `{spec}/references/screen.png` |

---

## Flow Overview

1. **Validate** input (spec path, `fe.md` exists).
2. **Read** template and `fe.md` in full.
3. **Create** review file via script.
4. **List** document to review (`fe.md`).
5. **Review** each document (loop).
6. **Finalize** review file and report.

---

## Step 1 — Validate Input

- Requester must provide a **spec directory** path (e.g. `docs/specs/001-add-abc`).
- The path must contain `fe.md`.
- If missing or invalid: reply *"Please provide a valid spec directory path that contains fe.md (e.g. docs/specs/001-add-abc)."* and stop.
- If valid → proceed to Step 2.

---

## Step 2 — Read All Inputs

**Do not skip.** Read every file before writing any review content.

1. Read `.agents/skills/spec-analyze/templates/spec-fe-template.md` — required sections, table structures, naming rules.
2. Read `{spec}/fe.md` — full content.
3. If `{spec}/references/screen.html` or `screen.png` exists and is relevant (e.g. to check §3.1 design analysis), read or analyze as needed.

---

## Step 3 — Create Review File (run script)

**Do not create the file manually** — use the script so the name and placeholders are correct.

1. From **project root**, run:
   ```bash
   python .agents/skills/spec-analyze/scripts/create-review-file.py <spec-path>
   ```
   Example: `python .agents/skills/spec-analyze/scripts/create-review-file.py docs/specs/001-add-abc`

2. The script creates `{spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md`, fills **Spec path**, **Date**, **Spec name**, and writes the template with **TODO** sections.

3. Note the path printed by the script. Open the file and set **Review type** to `Spec-FE`.

---

## Step 4 — List Document to Review

- In the review file **"Documents to review"** table, replace the TODO row with one row:
  - Document path: `{spec}/fe.md`
  - Reviewed: `[ ]`
- Save the file before proceeding.

---

## Step 5 — Review (loop)

### Step 5.0 — Before the loop

1. **Confirm review file** is saved with the "Documents to review" table filled (one row, `Reviewed` = `[ ]`).
2. **Load templates** (once) — ensure `.agents/skills/spec-analyze/templates/spec-fe-template.md` is loaded.

Then start the loop.

---

For **each** document in the "Documents to review" list (one at a time):

### Step 5.1 — Review the document

- Apply [review-contents/spec-fe.md](../review-contents/spec-fe.md) — template alignment, requirements clarity, internal consistency, quality.
- Read the document in full.
- Apply **all criteria** from the reference in order.
- **Do not modify** any document during review — document issues only.
- For every issue found, record it in the Issues table (Step 5.2). Include enough detail for the author to act on it independently.

### Step 5.2 — List issues in the review file

- In the **"Issues"** table of the review file, add one row per issue found:
  - Columns: Document, Location (section / line), Description, Issue type, Details, Priority, Need Fix (leave blank — filled by requester)
- If no issues found for this document, add no rows.

### Step 5.3 — Mark document as reviewed

- In the **"Documents to review"** table, set **Reviewed** for this document to `[x]`.

### Step 5.4 — Next document

- If any document still has `[ ]` → go back to **Step 5.1** with the next document.
- If all are `[x]` → proceed to **Step 6**.

---

## Step 6 — Finalize Review File and Report

1. Update **Executive Summary** in the review file: what was reviewed, template alignment, requirements clarity, total issues found.

2. Fill **Acceptance** table using criteria from [review-contents/spec-fe.md](../review-contents/spec-fe.md) — mark each Met ✓/✗.

3. Report to the user:

```
## Spec-FE Review Summary

**Spec:** {spec path}
**Review file:** {spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md

### Template alignment
{Summary: all sections present / list of missing sections}

### Requirements clarity
{Can a reader understand the original requirements from fe.md alone? Yes / No — details of gaps}

### Consistency
{Summary: §6.4↔§6.2, §6.2↔§6.1, §6.3↔§6.4, §6.8↔§6.9, §6.8↔§6.1, §6.5↔§5.3, §6.10↔§5.2, §6.9↔§2.1}

### Issues found ({N} total)
- {description of issue 1}
- ...
```
