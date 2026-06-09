# Review Content — Checklist File

Apply this reference during Step 5.1 of [review-checklists.md](../workflows/review-checklists.md) when reviewing a checklist file.

Template to reference: `.agents/skills/spec-checklists/templates/checklists/{type}.md` — load the template matching the file's type from its path (e.g. `checklists/component/` → `component.md`).

Also load the matching rule file: `rules/checklists/sections/{type}.md` — apply its Review rules checklist.

---

## 1. Template Alignment

Load the internal template for this checklist's type, then verify:

| Check |
|-------|
| All required **sections** from the template exist in the checklist file |
| No template section is empty — every section has values from the spec, not the original placeholder text |
| `<!-- Note: Description: ... Output: ... -->` comment blocks from the template have been removed or replaced with real content |
| Section headings match the template (not renamed without reason) |
| Required tables (e.g. Props, Styling, Extracted styles, Unit test cases) are present and filled |

**Issue type:** `Template mismatch` or `Missing section`

---

## 2. Consistency with fe.md

Cross-reference the checklist content against `fe.md`:

| Check | fe.md section |
|-------|---------------|
| Component/entity **name** matches exactly | §6.4, §6.3, §6.5, §6.6 |
| **Field names** and **prop names** match (case-sensitive) | §6.3, §6.4 |
| **API names**, paths, and HTTP methods match | §7.2 |
| **File location** (path) follows project conventions; verify with grep/glob if codebase exists | §6.4, §6.5, §6.6 |
| Component **props** listed in checklist match props defined in fe.md | §6.4, §6.5 |
| Validator **rules** match the rules defined in fe.md | §5.3, §6.7 |

**Issue type:** `Inconsistency with fe.md` or `Wrong path`

---

## 3. Placeholder Removal

| Check |
|-------|
| No remaining `<!-- Note: Description: ... Output: ... -->` or similar template instructions |
| No `{}`, `{ComponentName}`, `{FieldName}`, `{api-name}`, `{model-name}` placeholders left unfilled |
| All "TODO" markers removed or replaced with real values |
| Table cells are not empty where the template expected a value |

**Issue type:** `Placeholder left`

---

## 4. Summarize Match

| Check |
|-------|
| This checklist file is listed in `checklists/summarize.md` |
| Listed under the **correct type** section in summarize |
| The link in summarize points to the **correct file path** |

**Issue type:** `Summarize mismatch`

---

## Acceptance criteria

Fill the **Acceptance** table in the review file:

| Criterion | Met |
|-----------|-----|
| All required template sections present | ✓ / ✗ |
| All names, fields, props, paths match fe.md | ✓ / ✗ |
| No leftover placeholders or template comments | ✓ / ✗ |
| Listed in summarize under the correct type | ✓ / ✗ |
