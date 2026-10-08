# Runtime permissions

Decision: [D-0008](../../../../docs/decisions/D-0008-xin-quyen-runtime-qua-domain-port.md)
(proposed). Reference code: `test/patterns/permission_pattern_test.dart`.

## When to use

A feature needs camera, location, notifications or another runtime
permission. First check whether a system UI makes the permission
unnecessary, and prefer it:

- Pick photos/videos: system photo picker (`image_picker`, D-0004). No
  permission on Android 13+ (back-ported to 4.4+ via Play services) or iOS
  14+ (`PHPicker`). Never declare `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` or
  storage for this: Google Play allows them only when a picker cannot serve
  the app's core function. Full library access needs its own decision.
- Take one photo: `image_picker` camera opens the system camera app. Do not
  declare `CAMERA` on Android for that: a declared but ungranted `CAMERA`
  makes `ACTION_IMAGE_CAPTURE` throw. Use this flow for in-app camera
  (scanning, `camera` package).

## Decision

A domain port `PermissionRepo` returns one `PermissionAccess` per call
(adapter on `permission_handler`, made a direct dependency);
`PermissionUseCase` maps access to a closed `PermissionDecision`; the feature
Cubit emits typed effects for rationale, settings and proceed, and re-checks
on resume.

Package: `permission_handler: ^12.0.3` (publisher baseflow.com), the version
`sli_common` already resolves, so adding it changes no native build.
`^13.0.2` (Android plugin 14.1.0) fixes `status` on Android but needs
`compileSdk 37` (Flutter 3.44 defaults to 36) and AGP 9; move to it with
`sli_common`. The adapter is written for both.

`sli_common`'s `PermissionUtil` stays for legacy screens: it needs a
`BuildContext`, shows toasts and dialogs itself and asks without a
rationale, so a Cubit cannot use or test it.

## Files to create

| Layer | Path | Content |
|---|---|---|
| Port (shared) | `lib/domain/repositories/permission_repo.dart` | `AppPermission{camera, location, notifications}`, `PermissionAccess`, `status`, `request`, `openSettings` |
| UseCase (shared) | `lib/domain/use_case/permission_use_case.dart` | `PermissionDecision`, `check(p)`, `request(p)`, `openSettings()` |
| Adapter (shared) | `lib/data/repositories/permission_handler_repo.dart` | sketch in the test file (analyzed with 12.0.3 and 13.0.2) |
| Cubit | `lib/presentation/scan_receipt/cubit/scan_receipt_cubit.dart` | `onTapScan`, `confirmRationale`, `openSettings`, `onAppResumed` |
| State/effect | `.../scan_receipt_state.dart`, `scan_receipt_effect.dart` | see below |
| l10n | ARB | rationale and settings text per permission |

## Native setup (declare only what is used)

| `AppPermission` | Android `<uses-permission>` | iOS `Info.plist` | Podfile macro |
|---|---|---|---|
| `camera` | `android.permission.CAMERA` | `NSCameraUsageDescription` | `PERMISSION_CAMERA=1` |
| `location` | `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` | `NSLocationWhenInUseUsageDescription` | `PERMISSION_LOCATION_WHENINUSE=1` |
| `notifications` | `POST_NOTIFICATIONS` (Android 13+) | none (`UNUserNotificationCenter`) | `PERMISSION_NOTIFICATIONS=1` |

iOS uses CocoaPods here (`enable-swift-package-manager: false`). In
`ios/Podfile` `post_install`, enable only the macros above. A permission
without its macro is compiled out: `status` says `denied`, `request`
`permanentlyDenied`, no dialog ever shows.

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
  '$(inherited)',
  'PERMISSION_CAMERA=1',  # one line per permission actually used
]
```

Usage strings are full, specific sentences from the l10n owner ("The app
uses the camera to scan your receipt."). Without the key iOS crashes on
access and App Store upload fails (ITMS-90683). Android: `compileSdk` ≥ 35
for 12.x (37 for 13.x); `android.useAndroidX=true` is already set.

## Access → decision

| `PermissionAccess` | after `check` | after `request` |
|---|---|---|
| `granted`, `limited` | `proceed` | `proceed` |
| `denied` | `showRationale` | `declined` |
| `permanentlyDenied` | `openSettings` | `openSettings` |
| `restricted` | `unavailable` | `unavailable` |

## Flow

1. Ask only when the user taps the feature, never at launch (notifications
   too: ask at a moment like "notify me when it ships").
2. `check` (no dialog). `showRationale` → in-app explanation with one
   "Continue" button → `confirmRationale()` → system dialog. Android
   guidance allows a cancel on the rationale; Apple HIG prefers a single
   button.
3. `declined` → feature disabled with an inline notice; no repeated dialog.
4. `openSettings` → dialog with "Open settings"; set `awaitingSettings`.
5. `onAppResumed` (Screen: `AppLifecycleListener(onResume: ...)`) re-checks:
   back from Settings and granted proceeds; a revoke in Settings is noticed
   (Android kills the process on revoke, so a cold start also re-checks).
6. A double tap asks once (`_busy` guard; the adapter shares one request per
   permission and queues different ones).

## State and effects

```dart
final PermissionDecision? camera;   // null before the first check
final bool awaitingSettings;
final UiEffect<ScanReceiptEffect>? effect;
// ScanReceiptShowRationaleEffect(permission)
// ScanReceiptShowSettingsEffect(permission)
// ScanReceiptOpenCameraEffect()
```

## Platform behaviour the adapter absorbs

- Android `status` cannot see "don't ask again": 12.x may report
  `permanentlyDenied` falsely after the user reset to "Ask every time", so
  the adapter maps it to `denied`; only `request()` decides. A permanently
  denied `request()` returns at once without a dialog → settings effect.
  Do not use `shouldShowRequestRationale` to detect permanent denial.
- iOS: `permanentlyDenied` right after the first refusal; `limited`
  (partial photos) and `provisional` notifications map to `limited`.
- Android 14 partial photo access reports `limited` too (needs
  `READ_MEDIA_VISUAL_USER_SELECTED`; only with a library-access decision).
- Location: `locationWhenInUse` only; background location needs its own
  decision and store review text.
- `request()` throws if another plugin's request is running or a
  manifest/plist entry is missing; the adapter logs it and answers
  `denied`.

## Test checklist

- [ ] Use case maps every access for `check` and `request`.
- [ ] Granted: proceeds without a dialog.
- [ ] First time: rationale, then request, then proceed.
- [ ] Refusal: `declined`, no new effect.
- [ ] Android permanent denial seen only in the request answer → settings.
- [ ] Permanently denied: settings effect → resume re-check → proceed.
- [ ] Revoked in Settings is noticed on resume.
- [ ] Restricted: `unavailable`, no dialog.
- [ ] Double tap asks once; resume before any check does nothing.
- [ ] Answer after `close()` ignored.

## Nguồn

- permission_handler README, changelog and Android guide: https://pub.dev/packages/permission_handler,
  https://github.com/Baseflow/flutter-permission-handler/blob/main/ANDROID_PERMANENTLY_DENIED_FIX_GUIDE.md
- Android: https://developer.android.com/training/permissions/requesting,
  https://developer.android.com/develop/ui/views/notifications/notification-permission
- Android 14 partial media: https://developer.android.com/about/versions/14/changes/partial-photo-video-access
- Photo picker: https://developer.android.com/training/data-storage/shared/photopicker
- Google Play photo/video policy: https://support.google.com/googleplay/android-developer/answer/14115180
- Apple purpose strings: https://developer.apple.com/documentation/uikit/requesting-access-to-protected-resources
- Apple HIG privacy: https://developer.apple.com/design/human-interface-guidelines/privacy
- PhotoKit limited library: https://developer.apple.com/documentation/photokit/delivering-an-enhanced-privacy-experience-in-your-photos-app
