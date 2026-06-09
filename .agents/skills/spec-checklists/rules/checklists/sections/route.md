# Rules — Checklist: route

## When to create

- **Create** when `fe.md` section **6.10 Route** indicates a **new route** is being added to go_router.
- Typically **one** route checklist per spec.
- **Skip** when no new route is introduced (e.g. spec only modifies existing screen internals without adding a new path).

## Fill rules

- **Entity name:** all lowercase, kebab-case, derived from the route/screen name (e.g. `user-list`, `order-detail`).
- **Location:** verify actual path to the go_router config file via grep/glob. Routes are typically in `lib/app/router/` or `lib/presentation/{feature}/router/`.
- **Route details:** include path pattern, route name constant, params (type and required/optional), and which Page is mounted.
- **Navigation flow:** describe where the user navigates from (entry points) and where they can go (exit points).
- **Auth guard:** specify if any redirect condition applies (e.g. unauthenticated → `/login`).
- **Placeholders:** delete all `<!-- Note: ... -->` lines and all `{placeholder}` tokens after filling.

## Review rules

- [ ] A route checklist exists when a new route is introduced by spec §6.10.
- [ ] Route path pattern and name constant are fully specified.
- [ ] All path params are listed with correct Dart types.
- [ ] Mounted Page is identified and its file path is verified.
- [ ] Navigation flow (entry and exit points) is described.
- [ ] Location is verified against the actual go_router config file.
- [ ] No `<!-- Note: ... -->` or unfilled `{}` placeholders remain.
