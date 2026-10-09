---
name: sli-kit-from-spec
description: >
  Implement a design kit from the-forge-design (kits/<name>/<version>: tokens.json, kit/components.json,
  catalog, reference images) as Sli* components inside sli_common, with one golden per component state and a
  side-by-side review page for the user. Use when Forge hands over a design-system kit, when asked to "gen
  component từ kit/spec", to add a missing component to the kit, or to re-check Sli* against the design catalog.
  Not for building product screens (compose existing Sli* in the feature) or for inventing components that are
  not in the spec.
---

# Sli kit from spec

The kit is the source of truth for look and states. `sli_common` is its Flutter implementation. Read
`flutter-atomic-design` and `project-convention` first; their ownership rules still apply.

## Input

`<the-forge-design>/kits/<name>/<version>/` — path comes from Forge's handoff or the user, never guess it.

| File | Use |
|---|---|
| `kit.json` | name, version, status; refuse to implement a kit whose files do not match `kit.json.files` hashes |
| `tokens/tokens.json` | values; generate theme, never hand-copy hex values into components |
| `kit/components.json` | the only list of components to build; ids, variants, states, token roles, a11y, touch target |
| `catalog/index.html` + `reference/*.png` + `reference/measurements.json` | the visual and measured target per state ID |

## Steps

1. **Theme from tokens.** Regenerate `lib/src/foundation/` (`SliColors`, spacing/radii/typography tokens,
   `SliTheme`) from `tokens.json`. Brand values live in the generated theme the app passes in; components read
   tokens by role (`context.sliColors.primary`), never literal colours. Keep a neutral default theme only for
   tests and the example catalog.
2. **One component per spec entry.** `lib/src/components/sli_<id>.dart`, class `Sli<PascalId>`, variant enum
   from `variants`, state driven by real inputs (`onPressed == null` → disabled, `isLoading`, `errorText`…).
   Map each `tokens` role in the spec to the generated token. Honour `a11y.role` (Semantics) and
   `minTouchTarget`. Reuse a `shadcn_flutter` primitive behind the facade when it renders the spec faithfully;
   otherwise build it with Material widgets. Export from `lib/sli_common.dart`.
3. **Golden per state ID.** `test/kit/<id>_kit_test.dart` renders every `<id>.<variant>.<state>` on a 430-wide
   surface at devicePixelRatio 2 with the kit theme and writes `test/goldens/kit/<id>.<variant>.<state>.png`.
   Pressed/focused states use `WidgetStatesController` or a test-only `forceState` parameter, not timing.
4. **Example catalog.** `example/lib/kit_catalog.dart` lists every state ID in spec order with its label so the
   user can scroll it on a simulator next to `catalog/index.html`.
5. **Review page.** Run
   `python3 tool/kit/compare.py --kit <kit dir> --flutter lib/modules/sli_common/test/goldens/kit`
   and give the user `build/kit-compare/index.html`. The script only checks that both images exist and the
   frame ratio matches; colour, icon, typography and spacing are the user's call per row.
6. **Done** only when `flutter analyze` and `flutter test` pass in `sli_common`, the compare script exits 0, and
   the user marked every row "Đạt". Record the implementation in the kit's `kit.json.implementations`
   (platform `flutter`, sli_common commit) only after that.

## Rules

- Do not add, rename or drop components that are not in the spec; missing component → ask Forge/Designer for a
  kit revision.
- Do not edit kit files; a wrong spec is a Designer revision, not a local fix.
- Legacy widgets in `sli_common` may be removed when a kit component replaces them; update the app call sites
  in the same change and keep the base screens compiling.
- Report measured mismatches honestly; never regenerate reference images from Flutter output.
