# Base Modernization Review — 2026-08-27

## Verdict

The modernization foundation is ready for continued feature work. The app now
has deterministic bootstrap, typed environments, generated DI, enforced layer
boundaries, Cubit-first/BLoC-capable state primitives, protected network
inspection, and a real independently versioned `sli_common` toolkit.

This review does not call the repository a product-neutral template yet. Legacy
sample features, branding, native identifiers, and the historical
`sli_common` surface remain intentionally tracked as follow-up migrations.

## Verified gates

| Gate | Result |
|---|---|
| `./scripts/generate.sh` | Pass; reproducible generated output |
| `./scripts/format.sh --check` | Pass; 169 Dart files unchanged |
| `flutter analyze` | Pass; zero findings |
| `./scripts/check_architecture.sh` | Pass |
| Application tests | Pass; 11 tests |
| `sli_common` scoped analysis | Pass; `lib/src`, `test`, and `example/lib` |
| `sli_common` tests | Pass; 3 tests |
| `git diff --check` | Pass |
| Tracked signing/private-key scan | Pass; no matching sensitive artifacts |
| Fresh recursive clone | Pass; submodule checkout, bootstrap, and analyze |

## Architecture review

- Dependency direction is enforced as domain → data implementation →
  presentation, with no presentation-to-data shortcut.
- `get_it` remains the runtime container while `injectable` owns compile-time
  registrations. Business classes use constructor injection.
- Cubit is the normal choice. `BaseBloc` is available for event-driven or
  concurrency-heavy flows without forcing every feature into BLoC.
- `BaseAppState + Equatable + copyWith` remains the state contract. Freezed,
  HydratedBloc, GraphQL, FCM, and deep links remain optional capabilities.
- REST/Dio is the default transport. Network inspection is forbidden in
  production and sensitive fields are redacted before capture.
- Shadcn is isolated behind stable `Sli*` components so applications do not
  couple directly to a third-party design API.

## Security and delivery review

- Removed three tracked `.mobileprovision` files.
- Removed hard-coded provisioning profile names and UUIDs from the Xcode
  project. Signing must be supplied by Xcode automatic signing or CI.
- Firebase flavor files remain because deleting them would break the current
  sample flavors. They are client configuration rather than signing secrets,
  but must be replaced by the app-creation workflow.

## Follow-up priorities

1. Make feature Cubits context-free and replace the compatibility global
   handler with explicit UI listeners/effects.
2. Add concurrent 401 refresh, refresh-failure, and offline interceptor tests.
3. Migrate duplicated app widgets to `sli_common` through adapters and a
   behavior matrix.
4. Add safe app creation/rename with dry-run, then neutralize sample branding,
   native identifiers, Firebase configs, and product slices.
5. Modernize the historical `sli_common` library incrementally until its full
   analyzer can replace the current clean public-surface gate.

The ordered source of truth remains
[`docs/plan/2026-08-26-base-modernization.md`](../plan/2026-08-26-base-modernization.md).
