# Process part: page

Use this reference when processing the **page** part in the checklists workflow (Step 3).

## When needed

- **Needed** if section **6.9 Page** in `fe.md` describes a screen for this spec (top-level Flutter Page that owns the route).
- Typically **one** page checklist per main screen in the spec.

## Template

[`../../templates/checklists/page.md`](../../templates/checklists/page.md)

## Entity naming & list files

- **Path pattern:** `docs/specs/{id}-{name}/checklists/page/{entity-name}.md`
- **Entity name:** all lowercase, kebab-case, screen name (e.g. `user-list-page`, `order-detail-page`).
- Typically **one** page checklist per main screen in the spec.

## Path verification

- Pages live in `lib/presentation/{feature}/presentation/pages/`.
- Before filling **Location**: grep/glob to verify actual path. Use **actual path**, not blindly from spec.

## Analyze & brainstorm

- Screen composition: which Organisms/Molecules are assembled?
- BLoC/Cubit state drives: loading indicator, data list, error message, empty state.
- User actions in spec §6.9 that trigger navigation or BLoC methods.
- Screen states from spec §6.9: loading, error, empty, success.

## Fill content & verify

- Fill "Output" blocks: Page name, **Location** (verified path), widget composition, BLoC used, screen states.
- Page widget test cases: one checkbox per case (per BLoC state, per navigation action).
- Delete all `<!-- Note: ... -->` lines after filling.
- Verify the page checklist matches spec §6.9 and paths match the codebase.
