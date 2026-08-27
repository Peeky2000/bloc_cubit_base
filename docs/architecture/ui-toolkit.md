# UI Toolkit

`sli_common` is the personal reusable UI toolkit and is mounted as the Git submodule
`lib/modules/sli_common`.

## Placement

| Scope | Location |
|---|---|
| Cross-application component, utility, or design token | `sli_common` |
| Application-branded composition | `lib/core/widget` or `lib/widget` |
| Feature-only widget | `lib/presentation/<feature>/view` |

Shadcn Flutter is an implementation detail behind stable `Sli*` wrappers. Application
code should not spread direct Shadcn imports; a documented escape hatch is acceptable
for one-off experiments. Public components define variants, loading/disabled/error
states, semantics, light/dark behavior, and migration compatibility.

Legacy components move gradually through adapters and deprecation notices. Never copy
the same component into both repositories.
