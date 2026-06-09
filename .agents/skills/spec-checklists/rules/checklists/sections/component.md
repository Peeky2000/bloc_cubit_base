# Rules — Checklist: component (Widget)

## When to create

- **Create** only when Status = **"Create new"** or the spec explicitly indicates **modifications** to an existing widget.
- **Skip** when Status = "Reuse with no modifications" — existing widget is used as-is.

## Fill rules

- **Entity name:** all lowercase, kebab-case derived from the widget name (e.g. `user-avatar-atom`, `login-form-molecule`).
- **Atomic layer:** must be `Atom`, `Molecule`, or `Organism` — justified by `flutter-atomic-design` skill rules.
- **Location:** **mandatory** — grep/glob to verify actual path before filling. Shared widgets live under `lib/core/widget/{layer}/`, feature-specific under `lib/presentation/{feature}/presentation/widgets/`. Spec location may be wrong — use **actual path**.
- **Constructor params:** list every param with name, Dart type, required/optional.
- **Visual states:** document default, loading, error, empty, disabled states as applicable.
- **No direct BLoC in Atoms/Molecules** — data is passed via constructor. Only Organisms may use `BlocBuilder`.
- **Widget test cases:** one checkbox per case — render, params, callbacks, visual states.
- **Placeholders:** delete all `<!-- Note: ... -->` lines and all `{placeholder}` tokens after filling.

## Review rules

- [ ] Checklist exists only for widgets with Status = "Create new" or indicated modifications.
- [ ] No checklist for Reuse-with-no-modifications widgets.
- [ ] Atomic layer classification is stated and justified.
- [ ] All constructor params are listed with correct Dart types and required/optional flags.
- [ ] Location is verified via grep/glob (actual path, not spec guess).
- [ ] All visual states (loading, error, empty, disabled) are documented.
- [ ] Widget test cases cover: render, params, callbacks, states.
- [ ] No `<!-- Note: ... -->` or unfilled `{}` placeholders remain.
