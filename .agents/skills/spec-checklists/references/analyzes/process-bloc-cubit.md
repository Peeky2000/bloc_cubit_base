# Process part: bloc-cubit

Use this reference when processing the **bloc-cubit** part in the checklists workflow (Step 3).

## When needed

- **Needed** if section **6.8 BLoC / Cubit** in `fe.md` lists any Cubits or BLoCs.
- Create a checklist for **every** BLoC/Cubit in §6.8 — purpose: verify type decision, state variants, and method/event coverage.

## Template

[`../../templates/checklists/bloc-cubit.md`](../../templates/checklists/bloc-cubit.md)

## Entity naming & list files

- **Path pattern:** `docs/specs/{id}-{name}/checklists/bloc-cubit/{entity-name}.md`
- **Entity name:** all lowercase, kebab-case, derived from the cubit/bloc name (e.g. `user-list-cubit`, `auth-bloc`).
- **Include:** Every BLoC or Cubit listed in §6.8 subsections.

## Path verification

- BLoC/Cubit files live in `lib/presentation/{feature}/presentation/bloc/`.
- Before filling **Location**: grep/glob to verify actual path in the project.

## Analyze & brainstorm

- Is this a Cubit (simple state transitions) or BLoC (complex multi-step events)?
  - Default: Cubit. Use BLoC only if spec §6.8 explicitly states multi-step or concurrent events.
- What state variants does the screen need? (loading, success, error, empty, refreshing, loadingMore…)
- What data fields does `success` state carry? (Entity types from §6.1, never Models)
- Which user actions in §6.9 require a method/event here?
- What Repository methods are called? (abstract interface — verify they exist in §6.3)

## Fill content & verify

- Fill all "Output" blocks from the template with concrete info from spec §6.8.
- **Location** = verified path to the cubit/bloc file in the codebase.
- Unit test cases: initial state, [loading, success], [loading, error] per method/event.
- Delete all `<!-- Note: ... -->` lines after filling.
- Verify every BLoC/Cubit in §6.8 has a checklist and every user action in §6.9 has a corresponding method/event.
