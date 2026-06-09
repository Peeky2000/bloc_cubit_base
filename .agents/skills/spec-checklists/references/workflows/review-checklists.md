# Review Checklists

Use this workflow when reviewing checklist documents under a spec (`{spec}/checklists/`) for template alignment, consistency with `fe.md`, placeholder removal, and summarize accuracy.

## Required Inputs

| Input | Location |
|-------|----------|
| Spec directory | e.g. `docs/specs/001-add-abc/` |
| Spec doc | `{spec}/fe.md` |
| Checklist index | `{spec}/checklists/summarize.md` |
| Checklist files | `{spec}/checklists/{type}/{name}.md` |
| Checklist templates | `.agents/skills/spec-checklists/templates/checklists/{type}.md` (load by type as needed) |

---

## Flow Overview

1. **Validate** input (spec path, `checklists/summarize.md` and all linked files exist).
2. **Read** `fe.md`, `summarize.md`, all checklist files, and their type templates.
3. **Create** review file via script.
4. **List** all checklist documents to review (from summarize).
5. **Review** each document (loop).
6. **Finalize** review file and report.

---

## Step 1 — Validate Input

- Requester must provide a **spec directory** path (e.g. `docs/specs/001-add-abc`).
- The path must contain:
  - `checklists/summarize.md`
  - All checklist files linked from summarize (e.g. `checklists/component/foo.md`).
- If summarize.md is missing or any linked file does not exist → reply:
  > *"Please provide a valid spec directory with checklists: checklists/summarize.md and all linked checklist files must exist."*

  Then **stop**.
- If valid → proceed to Step 2.

---

## Step 2 — Read All Inputs

**Do not skip.** Read every file before writing any review content.

1. Read `{spec}/fe.md` — entities (§6.1), models (§6.2), repositories (§6.3), APIs (§6.4), validations (§6.5), utilities (§6.6), widgets (§6.7), BLoC/Cubits (§6.8), pages (§6.9), routes (§6.10).
2. Read `{spec}/checklists/summarize.md` — list of all checklists and their types.
3. Read **every checklist file** listed in summarize.
4. For each **type** present (entity, data-model, repository, api, route, validation, utility, component, bloc-cubit, page), read the corresponding internal template:
   `.agents/skills/spec-checklists/templates/checklists/{type}.md`

---

## Step 3 — Create Review File (run script)

**Do not create the file manually** — use the script so the name and placeholders are correct.

1. From **project root**, run:
   ```bash
   ./.agents/skills/spec-checklists/scripts/create-review-file.sh <spec-path>
   ```
   Example: `./.agents/skills/spec-checklists/scripts/create-review-file.sh docs/specs/001-add-abc`

2. The script creates `{spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md`, fills **Spec path**, **Date**, **Spec name**, and writes the template with **TODO** sections.

3. Note the path printed by the script. Open the file and set **Review type** to `Checklist`.

---

## Step 4 — List All Checklist Documents to Review

- From `checklists/summarize.md`, collect every linked checklist path.
- In the review file **"Documents to review"** table, replace the TODO row with one row per checklist:
  - Document path: `{spec}/checklists/{type}/{name}.md`
  - Reviewed: `[ ]`
- Save the file before proceeding.

---

## Step 5 — Review (loop)

### Step 5.0 — Before the loop

1. **Confirm review file** is saved with the "Documents to review" table filled (all rows, `Reviewed` = `[ ]`).
2. **Load templates** (once) — for each checklist type present, ensure the internal template is loaded:
   `.agents/skills/spec-checklists/templates/checklists/{type}.md`

Then start the loop.

---

For **each** document in the "Documents to review" list (one at a time):

### Step 5.1 — Review the document

- Apply [review-contents/checklist.md](../review-contents/checklist.md) — template alignment, consistency with fe.md, placeholder removal, summarize match.
- Determine the checklist **type** from its path (e.g. `checklists/component/` → type = `component`).
- Read the document in full.
- Also read the matching rule file from `rules/checklists/sections/{type}.md` — apply the Review rules checklist.
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

1. Update **Executive Summary** in the review file: what was reviewed, template alignment, consistency with fe.md, total issues found.

2. Fill **Acceptance** table using criteria from [review-contents/checklist.md](../review-contents/checklist.md) — mark each Met ✓/✗.

3. Report to the user:

```
## Checklist Review Summary

**Spec:** {spec path}
**Review file:** {spec}/reviews/doc-YYYY-MM-DD-HH-mm-ss.md

### Checklists reviewed
{Count and list of types: e.g. 3 component, 1 page, 2 api, …}

### Template alignment
{All match template / list mismatches}

### Consistency with fe.md
{All names, fields, props, paths match / list inconsistencies}

### Issues found ({N} total)
- {description of issue 1}
- ...
```
