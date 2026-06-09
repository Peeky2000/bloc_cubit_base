# Rules — Checklist: page

## When to create

- **Create** when `fe.md` section **6.9 Page** describes a main screen for this spec (top-level Flutter Page that owns the route).
- Typically **one** page checklist per main screen in the spec.

## Fill rules

- **Entity name:** all lowercase, kebab-case, screen name (e.g. `user-list-page`, `order-detail-page`).
- **Location:** verify actual path via grep/glob before filling. Pages live in `lib/presentation/{feature}/presentation/pages/`. Use **actual path**.
- **Widget composition:** list every Organism/Molecule used by this page, with their role.
- **BLoC/Cubit wiring:** describe which BLoC/Cubit drives each screen state.
- **Screen states:** document all states from spec §6.9 — loading, error, empty, success / data-loaded.
- **No business logic in Page** — Page only reacts to BLoC/Cubit state changes.
- **Widget test cases:** one checkbox per case — render per BLoC state (loading, error, success), user interactions that trigger navigation or BLoC methods.
- **Placeholders:** delete all `<!-- Note: ... -->` lines and all `{placeholder}` tokens after filling.

## Review rules

- [ ] Page checklist exists for every main screen introduced in the spec.
- [ ] Widget composition lists all child Organisms/Molecules with their roles.
- [ ] BLoC/Cubit wiring is described — which state drives which UI element.
- [ ] Location is verified against the codebase (actual path used).
- [ ] All screen states (loading, error, empty, success) are documented.
- [ ] Widget test cases cover: loading state, success state, error state, navigation.
- [ ] No `<!-- Note: ... -->` or unfilled `{}` placeholders remain.
