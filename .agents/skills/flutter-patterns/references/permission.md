# Runtime permissions

Decision: [D-0008](../../../../docs/decisions/D-0008-xin-quyen-runtime-qua-domain-port.md)
(proposed). Reference code: `test/patterns/permission_pattern_test.dart`.

## When to use

A feature needs camera, photos, location, notifications or another runtime
permission. Pickers that ask on their own (system photo picker on Android 13+
and iOS 14+ needs no permission) do not need this flow; prefer them.

## Decision

A domain port `PermissionRepo` returns one `PermissionAccess` per call
(adapter on `permission_handler`, added as a direct dependency; today it is
only transitive through `sli_common`); `PermissionUseCase` maps access to a
closed `PermissionDecision`; the feature Cubit emits typed effects for
rationale, settings and proceed, and re-checks on resume.

`sli_common`'s `PermissionUtil` stays for legacy screens. It shows toasts and
dialogs from inside the call and takes a `BuildContext`, so a Cubit cannot use
or test it; new features use this port.

## Files to create

| Layer | Path | Content |
|---|---|---|
| Port (shared) | `lib/domain/repositories/permission_repo.dart` | `AppPermission`, `PermissionAccess`, `status`, `request`, `openSettings` |
| UseCase (shared) | `lib/domain/use_case/permission_use_case.dart` | `PermissionDecision`, `check(p)`, `request(p)`, `openSettings()` |
| Adapter (shared) | `lib/data/repositories/permission_handler_repo.dart` | sketch in the test file; one in-flight request per permission |
| Cubit | `lib/presentation/scan_receipt/cubit/scan_receipt_cubit.dart` | `onTapScan`, `confirmRationale`, `openSettings`, `onAppResumed` |
| State/effect | `.../scan_receipt_state.dart`, `scan_receipt_effect.dart` | see below |
| Native | `AndroidManifest.xml` `<uses-permission>`; `Info.plist` `NS…UsageDescription`; iOS Podfile `PERMISSION_…=1` macros | declare only what is used |
| l10n | ARB | rationale and settings text per permission |

## Access → decision

| `PermissionAccess` | after `check` | after `request` |
|---|---|---|
| `granted`, `limited` | `proceed` | `proceed` |
| `denied` | `showRationale` | `declined` |
| `permanentlyDenied` | `openSettings` | `openSettings` |
| `restricted` | `unavailable` | `unavailable` |

## Flow

1. Ask only when the user taps the feature, never at launch.
2. `check` (no dialog). `showRationale` → the Screen shows an in-app
   explanation; "Continue" → `confirmRationale()` → system dialog. The
   rationale comes first because a refusal of the system dialog may be
   permanent.
3. `declined` → feature disabled with an inline notice; no repeated dialog.
4. `openSettings` → dialog with "Open settings"; set `awaitingSettings`.
5. `onAppResumed` (Screen: `AppLifecycleListener(onResume: ...)`) re-checks:
   coming back granted from Settings proceeds; a permission revoked in
   Settings is noticed.
6. A double tap asks once (`_busy` guard; the adapter also shares one
   in-flight request).

## State and effects

```dart
final PermissionDecision? camera;   // null before the first check
final bool awaitingSettings;
final UiEffect<ScanReceiptEffect>? effect;
// ScanReceiptShowRationaleEffect(permission)
// ScanReceiptShowSettingsEffect(permission)
// ScanReceiptOpenCameraEffect()
```

## Platform notes for the adapter

- Android ≤ 12 photos use `Permission.storage`; Android 13+ uses
  `Permission.photos` (needs `sdkInt` from `device_info_plus`, as
  `PermissionUtil` does).
- iOS returns `permanentlyDenied` after the first refusal; Android only after
  "don't ask again".
- iOS `limited` photos and `provisional` notifications map to `limited`.
- Location: ask `locationWhenInUse`; background location needs its own
  decision and store review text.

## Security and privacy

Request the smallest permission (when-in-use, not always; photo picker, not
library access). Declare only used permissions; unused declarations fail
store review. Do not read data before the user sees why it is needed.

## Test checklist

- [ ] Use case maps every access for `check` and `request`.
- [ ] Granted: proceeds without a dialog.
- [ ] First time: rationale, then request, then proceed.
- [ ] Refusal: `declined`, no new effect.
- [ ] Permanently denied: settings effect → resume re-check → proceed.
- [ ] Revoked in Settings is noticed on resume.
- [ ] Restricted: `unavailable`, no dialog.
- [ ] Double tap asks once; resume before any check does nothing.
- [ ] Answer after `close()` ignored.

Reference code: `test/patterns/permission_pattern_test.dart`
