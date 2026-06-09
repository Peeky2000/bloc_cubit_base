# Process part: route

Use this reference when processing the **route** part in the checklists workflow (Step 3).

## When needed

- **Needed** if section **6.10 Route** in `fe.md` indicates a new route (new screen added to go_router navigation).
- Skip when the spec only modifies an existing screen without adding a new route.

## Template

[`../../templates/checklists/route.md`](../../templates/checklists/route.md)

## Entity naming & list files

- **Path pattern:** `docs/specs/{id}-{name}/checklists/route/{entity-name}.md`
- **Entity name:** all lowercase, kebab-case, derived from the route/screen name (e.g. `user-list`, `order-detail`).
- Typically **one** checklist per spec when a new route is added.

## Path verification

- Routes are declared in the app's router config (e.g. `lib/app/router/app_router.dart` or `lib/presentation/{feature}/router/`). Verify actual file path before filling **Location**.

## Analyze & brainstorm

- Route path pattern, parent shell (if nested), params (if any), and which Page is mounted.
- Navigation flow: where does the user come from and where can they go?
- Auth guard or redirect requirement?

## Fill content & verify

- Fill "Output" blocks with route path, `GoRoute` location, params, and parent shell.
- Delete all `<!-- Note: ... -->` lines after filling.
- Verify the route checklist matches spec §6.10 navigation section and actual router file.
