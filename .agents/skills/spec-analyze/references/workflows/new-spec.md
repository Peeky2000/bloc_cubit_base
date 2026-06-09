# Workflow: Generate Frontend Spec — New Screen

## Purpose

Generate a complete frontend spec (`fe.md`) for a **new screen**, following the standard template. The spec folder and file are created **early** (Step 2) so every subsequent step writes directly to the output — rather than building up context first and writing at the end.

### Rules

1. **Output language:** Write the spec in English only. Translate if the requester uses another language.
2. **No application code:** Do not read `src/` when analyzing. Use only design inputs, `docs/prerequisites.md`, skills, app-memory scripts, and the spec template.
3. **Order:** Run steps in sequence. Do not skip or reorder.
4. **Write incrementally:** After each analysis step (6–12), fill the corresponding section(s) of `fe.md` before moving to the next step.

---

## Step 1: Verify Input

**Requirement:** The requester must provide **at least one** of:

| Input type | Description |
|---|---|
| **Screenshot** | Screenshot of the UI to be developed (attached or path) |
| **Figma link** | URL to Figma file / frame |
| **Requirement description** | Text description of the feature / screen / UI |
| **Documentation link** | URL to spec, PRD, or reference documentation |
| **Stitch Project** | Stitch Screen ID |

**Action:**

- If **none** of the above are provided:
  - Reply: *"Insufficient input to generate spec. Please provide at least one of: UI screenshot, Figma link, requirement description, or documentation link."*
  - **Stop** — do not execute further steps.
- If **at least one** input is provided → proceed to **Step 2**.

---

## Step 2: Process Input → Create Spec Folder

### 2.1 Quick-read requirements

Read `docs/prerequisites.md` to understand project context and tech stack.

For each input type provided, do a **lightweight first pass** — just enough to extract a name and keywords (deep analysis happens in Step 5):

| Input type | Quick-read action |
|---|---|
| **Figma link** | Use Figma MCP to read frame/page name and top-level layout |
| **Screenshot** | Identify screen title, main entity, and screen type |
| **Stitch Project** | Call `get_screen` (MCP), note `title` from response |
| **Description / Doc link** | Read first paragraph — extract feature name and intent |

### 2.2 Run naming script → get slug

From the quick read above, collect:
- **Description:** Short English phrase summarizing the screen (e.g. `"User list screen"`, `"Create user form"`).
- **Keywords:** Comma-separated (entity, screen type, theme if relevant). Use `--type new-screen` for new screens.

Read [spec-naming-guide.md](spec-naming-guide.md) for full guidance on naming, then run from project root:

```bash
python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py \
  --description "<your description>" \
  --keywords "<keyword1,keyword2>" \
  --type new-screen
```

Use the **first line of stdout** as the slug for Step 2.3. Optionally use the suggested title (stderr) for the **Feature / screen name** in `fe.md`.

### 2.3 Run create-spec-folder script

**Do not create the folder or `fe.md` manually** — use the script so the spec dir, `references/`, and `fe.md` (from template) are created with the correct structure.

From **project root**, run:

```bash
python .agents/skills/spec-analyze/scripts/create-spec-folder.py <slug>
```

The script creates:
- `docs/specs/{NNN}-{name}/`
- `docs/specs/{NNN}-{name}/references/`
- `docs/specs/{NNN}-{name}/fe.md` (copy of `.agents/skills/spec-analyze/templates/spec-fe-template.md`)

**Note the path** printed by the script (e.g. `docs/specs/001-user-list/fe.md`, `docs/specs/001-create-user/fe.md`). All subsequent steps write to this file.

---

## Step 3: Download References → Save to `references/`

For each input type provided, download and persist the design assets into `{spec-dir}/references/` before analysis:

| Input type | Action |
|---|---|
| **Screenshot** (path) | Copy to `{spec-dir}/references/screen.png` |
| **Screenshot** (attached) | Save attachment to `{spec-dir}/references/screen.png` |
| **Figma link** | Export / download the frame image → `{spec-dir}/references/screen.png` |
| **Stitch Project** | Fetch `screenshot.downloadUrl` → save `{spec-dir}/references/screen.png`; fetch `htmlCode.downloadUrl` (or decode `htmlCode.fileContentBase64`) → save `{spec-dir}/references/screen.html` |
| **Documentation link** | Fetch and save content → `{spec-dir}/references/doc.md` (or `.html`) |

For **Stitch**: follow the detailed fetch steps in [analyze-stitch.md](../analyzes/analyze-stitch.md).

---

## Step 4: Fill Input Metadata into `fe.md`

With the spec folder created and references saved, fill the **known fields** of `fe.md` now — before deep analysis:

- **Section 1 (Overview):**
  - `Feature / screen name` — from slug title or quick read
  - `Short description` — one-line summary
  - `Created at` — today's date
  - `Route (if known)` — fill if clear, else `TBD`
  - `Requirement source` — check applicable boxes (Figma / Screenshot / Documentation / Description)

- **Section 1.1 (Input):**
  - `Figma link` — paste if provided
  - `Screenshot` — path or description
  - `Stitch Screen ID` — if provided
  - `Reference documentation` — link if provided
  - `Design notes` — brief notes from quick read (layout impression, states visible)

- **Section 10 (Attachments):** Paste all links and file paths provided by the requester.

---

## Step 5: Deep Analysis → Fill Analysis + Questions

Now perform a thorough analysis. Load the following skills before analyzing:

- **`design-to-code`** — screen type, widget breakdown, data flow.
- **`ui-ux-pro-max`** — style, layout, typography, color, accessibility, interaction, responsive, loading/error UI.
- **`app-memory`** — `search_memory.py` to check existing widgets, validators, utilities.
- **`flutter-model-entity`** — Entity vs Model distinction and `@freezed` patterns.
- **`flutter-repository`** — Repository interface, impl, and return-entity rule.
- **`flutter-datasource`** — RemoteDataSource / LocalDataSource patterns.
- **`flutter-bloc-cubit`** — Cubit vs BLoC decision, sealed State, emit patterns.
- **`flutter-router`** — go_router GoRoute, ShellRoute, path params.

For each input type provided, run the corresponding deep analysis flow:

| Input type | Reference flow |
|---|---|
| **Figma link** | [analyze-figma.md](../analyzes/analyze-figma.md) |
| **Screenshot** | [analyze-screenshot.md](../analyzes/analyze-screenshot.md) |
| **Stitch Project** | [analyze-stitch.md](../analyzes/analyze-stitch.md) (re-use the response fetched in Step 3) |
| **Description / Documentation link** | [analyze-description.md](../analyzes/analyze-description.md) |

Combine all findings into a unified picture of the screen.

### 5.1 Fill Section 2 (Analysis)

Write analysis results into `fe.md`:

- **2.0 UI Mock** — ASCII wireframes of the full screen. Rules:
  - Draw one block per screen state (normal, loading, error, empty).
  - Draw separate blocks for each dialog/modal/overlay.
  - Annotate every UI block with its widget name and atomic layer (`[atom]`, `[molecule]`, `[organism]`).
  - Include a **widget hierarchy tree** at the end of §2.0 showing the full parent-child nesting from `PageWidget` down to atoms.
  - Use `┌─┐ └─┘` for solid borders, `╔═╗ ╚═╝` for dashed areas, `░` for shimmer, `●` active, `○` inactive, `◌` spinner.
- **2.1 Layout blocks** — every major UI block: name, structure, layout type, spacing, widget refs.
- **2.2 Table (columns)** — fill only if screen has a data table.
- **2.3 Form (fields)** — fill only if screen has a form.
- **2.4 Other elements** — buttons, cards, badges, modals, alerts, etc.
- **2.5 Logic analysis** — business logic flows: trigger → logic steps → validator → utility → API → outcome. One row per flow. Omit if purely static UI.

### 5.2 Questions for requester (if any)

If there is **missing or ambiguous** information that blocks completing the spec:

1. List all questions clearly.
2. Fill them into **Section 4 (Questions for requester)** of `fe.md` (one QA block per question).
3. **STOP** — reply to the requester with the questions. Wait for answers before continuing.
4. Once answers are received, fill in the `answers` field of each QA block and proceed to **Step 6**.

If no questions → proceed directly to Step 6.

---

> **Rules:** Before filling any section in `6. Detail analysis`, read the rule file for that section in [rules/fe-spec/index.md](../rules/fe-spec/index.md). Each file has `Fill rules` (what to include) and `Review rules` (what to verify).

---

## Step 6: Analyze Entity + Model

From the analysis in Step 5, identify all domain data structures and their API mappings.

Read fill rules: [rules/fe-spec/sections/6.1-entity.md](../rules/fe-spec/sections/6.1-entity.md) and [rules/fe-spec/sections/6.2-model.md](../rules/fe-spec/sections/6.2-model.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.1 Entity** | Summary table: entity name, used in (BLoC/Widget), location |
| **6.1.1, 6.1.2, …** | One subsection per entity: represents, used for, name, location, Dart fields |
| **6.2 Model** | Summary table: model name, mapped from entity, location |
| **6.2.1, 6.2.2, …** | One subsection per model: maps to entity, name, location, fields with JSON keys |

---

## Step 7: Analyze Repository

From the entities in §6.1 and APIs identified in Step 5, define the repository contracts.

Read fill rules: [rules/fe-spec/sections/6.3-repository.md](../rules/fe-spec/sections/6.3-repository.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.3 Repository** | Summary table: repository name, interface location, impl location |
| **6.3.1, …** | One subsection per repository: method signatures, return types (Entities), description |

---

## Step 8: Analyze API

Identify all Retrofit endpoints this screen calls. Do not include APIs used on other screens.

Read fill rules: [rules/fe-spec/sections/6.4-api.md](../rules/fe-spec/sections/6.4-api.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.4 API** | State management line, summary table |
| **6.4.1, 6.4.2, …** | One subsection per endpoint: URL, param, query, body, response (→ §6.2 Model) |

---

## Step 9: Analyze Validation

From form fields in `2.3` and logic flows in `2.5`, identify all Flutter validators needed.

For **each validator**, run app-memory search before listing:

```bash
python3 .agents/skills/app-memory/scripts/search_memory.py "<validator name or keyword>" --type validator
```

- Found → **Status: Reuse**.
- Not found → **Status: Create new**.

Read fill rules: [rules/fe-spec/sections/6.5-validation.md](../rules/fe-spec/sections/6.5-validation.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **5.3 Validation / edge conditions** | Field-level table (required, type, min/max, error message) + error handling table |
| **6.5 Validation** | Validator table with Status + easy_localization i18n key. **Omit if no validators.** |

---

## Step 10: Analyze Utility

From logic flows in `2.5`, identify all utility functions needed (formatters, mappers, helpers).

For **each utility**, run app-memory search before listing:

```bash
python3 .agents/skills/app-memory/scripts/search_memory.py "<utility name or keyword>" --type utility
```

- Found → **Status: Reuse**.
- Not found → **Status: Create new**.

Read fill rules: [rules/fe-spec/sections/6.6-utility.md](../rules/fe-spec/sections/6.6-utility.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.6 Utility** | Utility table with Status column. **Omit if none.** |

---

## Step 11: Analyze Widget

Using design-to-code skill + analysis from Step 5, identify all Flutter widgets needed (Atomic Design).

For **each widget**, run app-memory search before listing:

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<widget name or keyword>" --type widget
```

- Found → **Status: Reuse**; use `location` from output.
- Not found → **Status: Create new**; specify expected location.

Read fill rules: [rules/fe-spec/sections/6.7-widget.md](../rules/fe-spec/sections/6.7-widget.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.7 Widget** (summary table) | Widget name, Type, Status, Design ref, Note, Location — one row per widget |
| **6.7.1 … 6.7.N** (subsections) | For each `Create new` widget: Description, Props (Dart class), Mock (ASCII art with state variants), Sub-components, File structure |

**Mock rules for subsections:**
- Draw at minimum the default/normal state.
- Add extra state blocks for every meaningful variant: loading (`░` shimmer or `◌` spinner), error (red border), disabled (muted), selected vs unselected, empty placeholder.
- Annotate each mock with color tokens, layout type, and spacing where relevant.

---

## Step 12: Analyze BLoC / Cubit

Decide on Cubit vs BLoC and define the state management contract for this screen.

Read fill rules: [rules/fe-spec/sections/6.8-bloc-cubit.md](../rules/fe-spec/sections/6.8-bloc-cubit.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.8 BLoC/Cubit** | Type, name, state class, location, states table, methods/events table |

---

## Step 13: Analyze Page + Route

Define the screen structure and go_router navigation.

Read fill rules: [rules/fe-spec/sections/6.9-page.md](../rules/fe-spec/sections/6.9-page.md) and [rules/fe-spec/sections/6.10-route.md](../rules/fe-spec/sections/6.10-route.md)

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **6.9 Page** | Location, main sections, screen states (loading/empty/error/success), user actions |
| **6.10 Route** | Type, pattern, parent route/shell, path, route key, params, GoRoute location |

---

## Step 14: Finalize

From requirements, user stories, and all analysis from Steps 5–13:

1. Define all user stories (who, what, why).
2. Map each to step-by-step business flows (happy path first, then edge cases).
3. Derive acceptance criteria from requirements and flows.

**Fill into `fe.md`:**

| Section | Content |
|---|---|
| **3 In scope / Out of scope** | Confirm scope based on full analysis |
| **5.1 User stories / Use cases** | Bulleted list of user stories |
| **5.2 Main business flows** | Step-by-step user journeys |
| **7 UI/UX guidelines** | Style, accessibility, responsive, loading/error UI (from ui-ux-pro-max) |
| **8 Open questions / constraints** | Technical constraints, i18n, performance, unresolved points |
| **9 Acceptance criteria** | Checkbox list derived from requirements and flows |

---

## Done

The `fe.md` is now fully populated. Reply to the requester with:

- The path to the created spec: `docs/specs/{NNN}-{name}/fe.md`
- A brief summary of what was found (screen type, key widgets, APIs, BLoC/Cubit choice, any open questions remaining).
