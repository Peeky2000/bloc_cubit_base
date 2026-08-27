# Workflow: Implement spec from checklists

## Purpose

Take a spec directory that **already has full checklists** (from the "Generate checklists from Spec" workflow), read the checklist root (summarize) to see progress, and implement **all** checklists that are not yet marked done — one file at a time, in order.

**Order:** Work strictly in summarize order: first unchecked → second → … → last. Complete one checklist file fully (all tasks `[x]`, then update summarize) before starting the next.

---

## Step 1: Validate input

**Requirement:** The requester must provide the path to a **spec directory** that contains a complete checklist structure.

**Validation Rules:**

- The path must be a directory under `docs/specs/`, e.g. `docs/specs/001-add-abc`.
- That directory must contain:
  - `checklists/summarize.md` (the root file that lists all checklists with checkboxes).
  - Subfolders under `checklists/` as needed: `data-model/`, `api/`, `route/`, `component/`, `page/`.
- Each checklist link in `summarize.md` must point to an existing file (e.g. `checklists/component/welcome-hero.md` exists).

**Action:**

- If **no path** is provided:
  - Reply: **"Please provide the path to a spec directory with checklists (e.g. `docs/specs/001-add-abc`)."**
  - **Stop** — do not proceed.
- If the path is provided but **not valid** (directory missing, or `checklists/summarize.md` missing, or linked checklist files missing):
  - Reply: **"The path must be a spec directory that already has full checklists: `checklists/summarize.md` and all linked checklist files must exist."**
  - **Stop** — do not proceed.
- If valid → proceed to **Step 2**.

---

## Step 2: Read root checklist and build pending list

1. **Read** `{spec-dir}/checklists/summarize.md`.
2. **Parse** all checkbox lines in order (top to bottom):
   - Format: `- [ ] [name](type/filename.md)` or `- [x] [name](type/filename.md)`.
   - Extract: checkbox state, checklist type (from path: `entity`, `data-model`, `repository`, `api`, `route`, `validation`, `utility`, `component`, `bloc-cubit`, `page`), and link target path relative to `checklists/`.
3. **Build the pending list:** Collect only items where the checkbox is **unchecked** (`[ ]`). Keep summarize order.
4. **Read** `{spec-dir}/fe.md` once for overall feature/screen context.

If the pending list is **empty** (all items are `[x]`):

- Reply: **"All checklists for this spec are already marked done. Nothing to implement."**
- **Stop** — do not proceed.

Otherwise → proceed to **Step 3** with the full pending list.

---

## Step 3: Implement all pending checklists (one file at a time)

Process **every** unchecked checklist in the pending list, in order. For **each** file:

### 3.1 Load skills for this checklist file

Based on the **checklist type**, load the corresponding Flutter skills before implementing. See the full table in `rules/implement/index.md`.

Quick reference by type:

- **`entity`** → `flutter-model-entity`
- **`data-model`** → `flutter-model-entity`
- **`repository`** → `flutter-repository`, `flutter-di`, `flutter-error-handling`
- **`api`** → `flutter-datasource`, `flutter-di`, `flutter-error-handling`
- **`route`** → `flutter-router`
- **`validation`** → —
- **`utility`** → `app-memory`
- **`component`** → `flutter-atomic-design`, `flutter-translations`, `app-memory`
- **`bloc-cubit`** → `flutter-bloc-cubit`, `flutter-di`, `flutter-error-handling`
- **`page`** → `flutter-atomic-design`, `flutter-bloc-cubit`, `flutter-translations`

Additional skills based on checklist content:
- Mentions **forms** → also load `flutter-error-handling` (form validation error handling)
- Mentions **new component / utility / feature** → also load `app-memory`

**Skill path resolution:** Look for skills under `.agents/skills/` first; if not found, try `.cursor/skills/`.

### 3.2 Load design resources (component / page only)

**If checklist type is `component` or `page`:**

- Read `{spec-dir}/references/screen.html` (if exists) — source of truth for exact design values (colors, spacing, font sizes, border-radius, shadows); cross-check with this if checklist values seem incomplete.
- Read `{spec-dir}/references/screen.png` (if exists) — visual reference for layout and proportions.
- Use the extracted style values from the checklist's "Extracted styles" section as the primary source; reference `screen.html` to fill gaps.
- Translate all values to Flutter conventions: `Color(0xFF...)`, `EdgeInsets`, `TextStyle`, `BorderRadius.circular(...)` — no CSS units in code.

### 3.3 Execute the checklist

1. **Resolve path:** `{spec-dir}/{checklist-relative-path}` (e.g. `docs/specs/001-add-abc/checklists/component/welcome-hero.md`).
2. **Read** the checklist file. It contains multiple tasks with sub-checkboxes.
3. **Execute** each unchecked task in order (create files, write code, add tests, etc. as specified).
4. **MANDATORY:** After completing each task, immediately update the checklist file — change `[ ]` to `[x]` for that task line. Do not batch; mark each task done as soon as it is finished.
5. Follow project conventions and any skills loaded in 3.1.
6. **Finish when** every task in that checklist file is `[x]`.

### 3.4 Update root summarize and move to next file

1. **MANDATORY:** Once all tasks in the checklist file are `[x]`, open `{spec-dir}/checklists/summarize.md`.
2. Find the line for the checklist just completed (e.g. `- [ ] [welcome-hero](component/welcome-hero.md)`).
3. Change `- [ ]` to `- [x]` for that line. Save the file.
4. Move to the **next** unchecked file in the pending list. Go back to **3.1**.
5. **Repeat** until all files in the pending list are done.

**Rules:**

- Do **not** skip order. Always complete a checklist file fully before moving to the next.
- **MANDATORY:** Mark each task `[x]` in the checklist file immediately after completing it.
- **MANDATORY:** Mark the checklist file `[x]` in `checklists/summarize.md` immediately after all its tasks are done.
- Never finish a file without updating both the checklist file and the root summarize.

---

## Step 4: Code review (after all checklists are done)

Once **all** checklists are completed, go back and review all generated code.

### 4.1 Review against checklist

- Verify each implemented file matches the requirements in its corresponding checklist.
- If issues or gaps are found → **fix them** and **repeat** the review until no errors remain.

### 4.2 Review against project rules

- Apply rules in `.cursor/rules/` (code-style, project-conventions, library-search, etc.).
- Check Dart naming, canonical Clean Architecture paths, immutable Equatable state,
  correct `@injectable`/`@JsonKey` use, constructor injection, imports, and unused code.
- If violations are found → **fix them** and **repeat** the review until no errors remain.

**Rules:**

- Do not skip review. Ensure code satisfies both the checklist and project rules before reporting.

---

## Step 5: Report

- When all pending checklists are implemented, root summarize is updated, **and** review is complete (no errors remaining):
  - Report to the user: list of all implemented checklist files and the path to `checklists/summarize.md`.
  - Confirm all checklists are now marked `[x]`.
  - Summarize any changes or fixes made during review (if any).

---
