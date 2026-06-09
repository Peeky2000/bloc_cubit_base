# Workflow: Generate checklists from Spec

## Purpose

Generate detailed technical checklists (Entity, Model, Repository, API, Route, Validation, Utility, Widget, BLoC/Cubit, Page) based on an existing frontend specification file (`fe.md`). This ensures implementation follows Flutter Clean Architecture patterns and project standards.

---

## Critical Rules

1. **Widget & Utility: create only when modifications are needed**
   - Create checklist when `Status` = **"Create new"** or when the spec indicates **modifications** to an existing entity.
   - Skip only when **Reuse with no modifications** — existing entity is used as-is, no changes required.

2. **Entity, Model, Repository, BLoC/Cubit: always create**
   - When spec lists these → create checklist for **every** entry (including Reuse). Purpose: verify structure.

3. **Paths must match actual codebase**
   - Location in spec may be wrong. Before filling Location: grep/glob to verify actual path in project. Use actual path, not blindly from spec.

---

## Step 1: Validate Input

**Requirement:** The requester must provide the path to a valid frontend spec file.

- File must be at `docs/specs/{id}-{name}/fe.md` (e.g. `docs/specs/001-home-new-user/fe.md`).
- If **no path** or file **does not exist** → reply: _"Please provide a valid path to a frontend spec file (e.g., `docs/specs/001-home-new-user/fe.md`)."_ and **Stop**.
- If valid → proceed to **Step 2**.

---

## Step 2: Template Mapping Table

Before processing any part, produce the mapping table and present it to the user, then proceed to Step 3 without waiting for confirmation.

| Part         | fe.md section          | Template to load                         |
| ------------ | ---------------------- | ---------------------------------------- |
| `entity`     | §6.1 Entity            | `templates/checklists/entity.md`         |
| `data-model` | §6.2 Model             | `templates/checklists/data-model.md`     |
| `repository` | §6.3 Repository        | `templates/checklists/repository.md`     |
| `api`        | §6.4 API               | `templates/checklists/api.md`            |
| `route`      | §6.10 Route            | `templates/checklists/route.md`          |
| `validation` | §6.5 Validation        | `templates/checklists/validation.md`     |
| `utility`    | §6.6 Utility           | `templates/checklists/utility.md`        |
| `component`  | §6.7 Widget            | `templates/checklists/component.md`      |
| `bloc-cubit` | §6.8 BLoC / Cubit      | `templates/checklists/bloc-cubit.md`     |
| `page`       | §6.9 Page              | `templates/checklists/page.md`           |

---

## Step 2.5: Create checklists directory structure (run script)

**Do not create folders or summarize.md manually** — run from project root:

```bash
./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh <spec-dir-or-fe.md>
```

Example: `./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh docs/specs/001-add-abc`

The script creates:

- `checklists/{entity,data-model,repository,api,route,validation,utility,component,bloc-cubit,page}/` subdirectories
- `checklists/summarize.md` — placeholder with comment markers (filled in Step 4)

Note the path printed by the script. Proceed to Step 3.

---

## Step 3: Process Each Part Sequentially

Process parts in this **fixed order:** **entity → data-model → repository → api → route → validation → utility → component → bloc-cubit → page**.

**Agent reads the spec; agent lists entity names; script creates files from template; agent fills content.** No automatic parsing of fe.md inside scripts.

For **each** part:

1. **Read the part-specific reference** — [process-entity.md](../analyzes/process-entity.md) | [process-data-model.md](../analyzes/process-data-model.md) | [process-repository.md](../analyzes/process-repository.md) | [process-api.md](../analyzes/process-api.md) | [process-route.md](../analyzes/process-route.md) | [process-validation.md](../analyzes/process-validation.md) | [process-utility.md](../analyzes/process-utility.md) | [process-component.md](../analyzes/process-component.md) | [process-bloc-cubit.md](../analyzes/process-bloc-cubit.md) | [process-page.md](../analyzes/process-page.md). Each defines: **when needed**, **entity naming** (kebab-case), **path verification**, **analyze & brainstorm**, **generate & verify**.

2. **3.1 Check if the part is needed** — Use the "When needed" section of the matching reference. If not needed → log `[SKIP] {part} — not required by spec`, move to next part. If needed → continue.

3. **3.2 List entity names from the spec** — By reading fe.md (sections §6.1–§6.10), **you** list the checklist entities for this part. Use kebab-case names. Examples:
   - entity: `user`, `order-item`
   - data-model: `user`, `order-item`
   - repository: `user-repository`, `order-repository`
   - api: `auth-remote-datasource`, `order-remote-datasource`
   - component: `user-avatar-atom`, `login-form-molecule`
   - bloc-cubit: `user-list-cubit`, `auth-bloc`

4. **3.25 Search app-memory for existing entities** — For parts `component`, `utility`, `validation`, `entity`, and `data-model`: run `mem_search.py` for each entity name before creating checklist files. This resolves the **actual location** in the codebase and identifies Reuse vs Create.

   ```bash
   python3 .agents/skills/app-memory/scripts/mem_search.py "<entity-name>" --type widget
   python3 .agents/skills/app-memory/scripts/mem_search.py "<entity-name>" --type utility
   python3 .agents/skills/app-memory/scripts/mem_search.py "<entity-name>" --type validator
   python3 .agents/skills/app-memory/scripts/mem_search.py "<entity-name>" --type entity
   python3 .agents/skills/app-memory/scripts/mem_search.py "<entity-name>" --type model
   ```

   - **Found** → use `location` from result as the verified path; cross-check with spec status (Reuse / Create new / Modify).
   - **Not found** → fall back to grep/glob to verify path; treat as new if absent in codebase.
   - Record results — they feed directly into 3.4 (path verification is already done).

5. **3.3 Run script to create checklist files** — Do **not** create files manually. Run (from project root):

   ```bash
   ./.agents/skills/spec-checklists/scripts/create-checklist-files.sh <spec-dir-or-fe.md> <part> <entity1> [entity2 ...]
   ```

   Example: `./.agents/skills/spec-checklists/scripts/create-checklist-files.sh docs/specs/007-user-list repository user-repository order-repository`

   The script creates `checklists/{part}/{entity}.md` from the template for each entity. Placeholder in the template (e.g. `{repository-name}`) is replaced with the entity name.

6. **3.4 Read each generated file and fill content** — Open each `checklists/{part}/{entity}.md`, then: path verification (use memory results from 3.25 when available, otherwise grep/glob), analyze & brainstorm (see reference), fill all "Output" blocks, add test checkboxes, **delete all** `<!-- Note: ... -->` lines.

7. **3.5 Verify against the spec** — Every entity that should have a checklist has one; paths match codebase; no `<!-- Note: ... -->` left. If issues → fix. If good → log `[DONE] {part}` and move to next part.

---

## Step 4: Fill summarize.md

The file was created with placeholder comment markers in Step 2.5. Open `checklists/summarize.md` and fill it:

- **Sections** in fixed order: entity → data-model → repository → api → route → validation → utility → component → bloc-cubit → page.
- Under each section, replace the `<!-- Add: ... -->` comment with one checkbox per generated checklist: `- [ ] [entity-name]({type}/{entity-name}.md)`.
- **Skip** (leave no entries under) sections for parts that were skipped entirely.

Reference template if needed: [templates/summarize-template.md](../../templates/summarize-template.md)

---

## Step 5: Final Report

Report to the user:

- List of all generated checklist files (grouped by part).
- List of skipped parts with reasons.
- Path to `checklists/summarize.md`.
