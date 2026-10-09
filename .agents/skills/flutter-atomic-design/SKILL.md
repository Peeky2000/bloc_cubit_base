---
name: flutter-atomic-design
description: >
  Decide where a UI widget lives and how to build it for reuse: feature view,
  app widget (lib/core/widget), or the shared sli_common package with Shadcn
  behind its facade. Use when creating or extracting a reusable widget or
  component, choosing sli_common versus the feature folder, composing Sli*
  components, or setting tokens, loading/disabled states, touch targets and
  semantics of a shared widget. Also load it next to flutter-testing when a
  test targets a shared widget or Sli* component. Trigger: widget dùng chung,
  component, design system, tách widget, reuse UI, shadcn, sli_common, Sli*.
  Not for moving hardcoded text into ARB (use flutter-translations), package
  or architecture brainstorming (use brainstorm), or jank in a widget tree
  (use flutter-performance).
---

# UI components

This base uses ownership and reuse boundaries, not a mandatory atoms/molecules
folder hierarchy.

| Scope | Location |
|---|---|
| Reusable across products | standalone `sli_common` repo / `lib/modules/sli_common` submodule |
| Reusable only in one app | `lib/core/widget/` or a neutral app widget folder |
| Feature-specific | `lib/presentation/<feature>/view/` |

## Decision order

1. Scan what already exists: app-memory, the public `sli_common` exports,
   `lib/widget/` and sibling features.
2. Reuse or compose what fits. If nothing fits, write a new widget in the app;
   do not force a component out of `sli_common`.
3. Extend `sli_common` only when the abstraction is genuinely cross-product.
4. Keep a widget in the feature when its semantics are product-specific.

## Rules

- App code imports stable `sli_common.dart` exports, not package internals.
- Direct `shadcn_flutter` imports belong inside the `sli_common` adapter layer.
- Shared widgets receive data/callbacks through constructors and do not own a
  feature Cubit/BLoC.
- Use semantic roles, design tokens, minimum touch targets, and loading/disabled
  behavior. User-facing text comes from app l10n.
- Padding, spacers and corner radius use `SliSpacing` / `SliRadii` without
  `.w/.h/.r` scaling. The convention rule `ui-tokens` fails on number literals.
  Component sizes (icon, image, field height) may stay numeric.
- A shared-package change requires its own tests/analyze and a submodule pointer
  update in the base.

See `docs/architecture/ui-toolkit.md` and `docs/guides/use-sli-common.md`.
