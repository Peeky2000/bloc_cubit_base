---
name: flutter-atomic-design
description: >
  UI component placement for this base: core widgets, app widgets, and sli_common module.
  Not a strict atoms folder tree. Trigger: "widget", "component", "reuse UI".
---

# UI Components (pragmatic)

This base does **not** use `shared/presentation/widgets/atoms/`. Use the map below.

## Where to put widgets

| Scope | Location | Examples |
|-------|----------|----------|
| App-wide reusable | `lib/core/widget/` | `dialog_util.dart`, `bottom_button.dart`, `common_drop_down.dart` |
| Feature-specific | `presentation/<feature>/view/` (private widgets) or subfolder | Screen-only layouts |
| App branding | `lib/widget/` | `delivery_go_bottom_button.dart` |
| Shared module | `lib/modules/sli_common/lib/` | Calendar, image loading, extensions |

## Rules

- **Search app-memory** before creating (`mem_search.py`)
- Reuse `core/widget` and `sli_common` first
- Cubit/Bloc only at **screen** level — not inside shared widgets
- Pass data via constructor — widgets stay dumb
- Strings via `context.l10n`

## Naming

- Screen: `*_screen.dart`, builder: `*ScreenBuilder()`
- No mandatory `App` prefix — follow neighbors in `core/widget/`

## References

- `references/layers.md` — conceptual; map Atom→`core/widget`, Molecule→composed widgets in screen
- `rules/no-bloc-below-page.md`, `rules/page-is-thin.md` — still apply
