---
name: flutter-atomic-design
description: >
  Pragmatic UI reuse and placement across feature views, app widgets, and the
  sli_common Git submodule with Shadcn behind a stable facade.
  Trigger: widget, component, design system, reuse UI, shadcn, sli_common.
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

1. Search app-memory and the public `sli_common` exports.
2. Compose an existing `Sli*` component with app tokens/theme.
3. Extend `sli_common` only when the abstraction is genuinely cross-product.
4. Keep a widget in the feature when its semantics are product-specific.

## Rules

- App code imports stable `sli_common.dart` exports, not package internals.
- Direct `shadcn_flutter` imports belong inside the `sli_common` adapter layer.
- Shared widgets receive data/callbacks through constructors and do not own a
  feature Cubit/BLoC.
- Use semantic roles, design tokens, minimum touch targets, and loading/disabled
  behavior. User-facing text comes from app l10n.
- A shared-package change requires its own tests/analyze and a submodule pointer
  update in the base.

See `docs/architecture/ui-toolkit.md` and `docs/guides/use-sli-common.md`.
