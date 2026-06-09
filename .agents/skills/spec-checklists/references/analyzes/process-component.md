# Process part: component (Widget)

Use this reference when processing the **component** part in the checklists workflow (Step 3).

## When needed

- **Needed** when section **6.7 Widget** in `fe.md` lists entries that require **modifications**: Status = **"Create new"** or spec explicitly indicates changes to an existing widget.
- **Skip** when **Reuse with no modifications** — existing widget is used as-is, no checklist.

## Template

[`../../templates/checklists/component.md`](../../templates/checklists/component.md)

## Entity naming & list files

- **Path pattern:** `docs/specs/{id}-{name}/checklists/component/{entity-name}.md`
- **Entity name:** all lowercase, kebab-case, from the widget name (e.g. `user-avatar-atom`, `login-form-molecule`, `product-card-organism`).
- **Include only** rows where Status = "Create new" or modifications are indicated; skip Reuse with no modifications.

## Path verification

- Shared widgets live under `lib/core/widget/{layer}/`.
- Feature-specific widgets live under `lib/presentation/{feature}/presentation/widgets/`.
- **Mandatory:** Before filling **Location**, grep/glob to verify actual path. Spec location may be wrong — use **actual path**.

## Analyze & brainstorm

- Atomic layer classification: Atom / Molecule / Organism — refer to `flutter-atomic-design` skill.
- Constructor params, callbacks, and visual states from the spec.
- Test cases: render, props, callbacks, visual states (loading, error, empty, disabled).

## Fill content & verify

- Fill "Output" blocks: Widget name, Atomic layer, **Location** (verified path), constructor params, visual states.
- Widget test cases: one checkbox per case.
- Delete all `<!-- Note: ... -->` lines after filling.
- Verify only widgets that need modifications have checklists; paths match codebase.
