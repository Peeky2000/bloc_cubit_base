---
name: sli-kit-from-spec
description: >
  Build Sli* components in sli_common from a design kit (kits/<name>/<version>: tokens.json, kit/components.json,
  catalog, reference images), following this base's rules, with one Linux-recorded golden per component state and a
  KIT-RECEIPT.json. Used by The Forge when it generates a kit for an app made from this base, and by a developer
  working without Forge. Use when asked to "gen component từ kit/spec", to add a component that the kit lists, or to
  move to a new kit version. Not for product screens (compose existing Sli* in the feature) and not for inventing
  components the kit does not list.
---

# Sli kit from spec

The kit is the source of truth for look and states. `sli_common` is its Flutter implementation. Read
`flutter-atomic-design` and `project-convention` first; their rules apply to every kit component.

Two ways in, same steps:

| Caller | Who reviews | Where approval is recorded |
|---|---|---|
| The Forge, through `forge-base.json` | The user, on Forge's review page | Forge, then copied into `KIT-RECEIPT.json` |
| A developer without Forge | The developer or their reviewer, on the PR | `KIT-RECEIPT.json` only |

## Input

`<the-forge-design>/kits/<name>/<version>/`. The path comes from Forge's handoff or the user; never guess it.

| File | Use |
|---|---|
| `kit.json` | name, version, status, file hashes. Refuse a kit whose files do not match `kit.json.files`. With Forge, refuse a kit whose `status` is not `design-approved` |
| `tokens/tokens.json` | values; generate the kit theme, never hand-copy hex values into components |
| `kit/components.json` | the only list of components to build: ids, variants, states, token roles, a11y, touch target |
| `catalog/index.html`, `reference/*.png`, `reference/measurements.json` | the visual target per state ID |

## Where things go

Paths come from `forge-base.json` `components`. Dart folders must be valid identifiers, so the kit name and version
are snake-cased for code and kept as-is for goldens:

| Thing | Path for `trial-kit@1.0.0` |
|---|---|
| Code | `lib/modules/sli_common/lib/src/kit/trial_kit/v1_0_0/` |
| Goldens | `lib/modules/sli_common/test/goldens/kit/trial-kit/1.0.0/` |
| Golden test | `lib/modules/sli_common/test/kit/trial_kit_golden_test.dart` |
| Receipt | `lib/modules/sli_common/lib/src/kit/trial_kit/v1_0_0/KIT-RECEIPT.json` |

A new kit version gets a new folder. Never edit an older version's folder to match a newer kit.

## Steps

1. **Branch.** In `sli_common`, branch `kit/<name>-<version>` from `dev`.
2. **Theme from tokens.** Generate the kit's tokens and theme in the kit folder from `tokens.json`. Components read
   tokens by role, never literal colours, spacing or radius.
3. **One component per spec entry.** Class `Sli<PascalId>` (or the prefix the kit already uses), variant enum from
   `variants`, state driven by real inputs (`onPressed == null` → disabled, `isLoading`, `errorText`…). Honour
   `a11y.role` (Semantics) and `minTouchTarget`. Reuse a `shadcn_flutter` primitive behind the facade when it renders
   the spec faithfully; otherwise build with Material widgets. Export from `lib/sli_common.dart`.
4. **Golden per state ID.** The golden test renders every `<id>.<variant>.<state>` on the catalog frame (358 logical
   px wide, white, 16 px padding, device pixel ratio 2) and matches
   `../goldens/kit/<name>/<version>/<id>.<variant>.<state>.png`. Pressed/focused states use a test-only
   `forcePressed`/focus node, not timing.
5. **Gate.** `./scripts/quality_sli_common.sh` from the base root must pass. On macOS the golden images are not
   compared; that is expected.
6. **Record goldens on Linux.** Push the branch, then run `lib/modules/sli_common/scripts/update_goldens.sh`. It runs
   the "Update goldens" workflow on GitHub and pulls the commit with the images. Never run `--update-goldens`
   locally, and never re-record to make a failing comparison pass.
7. **Receipt.** Write `KIT-RECEIPT.json`: kit, version, `kitHash`, source path, `rulesVersion` from `forge-base.json`,
   `goldenDir`, `goldenPlatform: linux`, and approvals (null until someone approves).
8. **Review.** With Forge: hand the branch and golden folder back; Forge builds the review page next to the kit's
   reference images and records the user's decision. Without Forge: open a PR into `dev` with the golden images and
   the kit's catalog link; the reviewer compares state by state.
9. **Done** when the gate passes, goldens come from Linux, every state is approved, the receipt names the approver,
   and the branch is merged into `sli_common` `dev`. Then bump the submodule in the app.

## Rules

- Do not add, rename or drop components that are not in the spec; a missing component is a kit revision from the
  Designer, not a local fix.
- Do not edit kit files.
- Report measured mismatches honestly; never regenerate reference images from Flutter output.
- Legacy widgets in `sli_common` may be removed when a kit component replaces them; update the app call sites in the
  same change and keep the base screens compiling.
- When `forge-base.json` `rulesVersion` changes, earlier kits keep the version in their receipt; fix them at the next
  kit version, not silently.
