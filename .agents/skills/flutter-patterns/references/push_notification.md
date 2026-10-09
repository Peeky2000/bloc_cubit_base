# Push notifications

Decision: [D-0007](../../../../docs/decisions/D-0007-push-notification-qua-domain-port.md)
(proposed). Reference code: `test/patterns/push_notification_pattern_test.dart`.

## When to use

The server tells the user about something while the app is closed or in the
background: order updates, messages, reminders, promotions. Firebase
Messaging stays deferred (`docs/architecture/optional-capabilities.md`) until
the notification contract and navigation are known; then use this shape.

## Decision

A domain port `PushRepo` (adapter on `firebase_messaging` ^16.7.0) exposes
permission, token, token refreshes and one `Stream<PushEvent>`;
`PushUseCase` owns device registration tied to the session; an app-scope
`PushCubit` turns foreground messages into a banner effect and taps into
links that go through the deep link parser.

## Packages (one upgrade)

| Package | Constraint | Why |
|---|---|---|
| `firebase_messaging` | `^16.7.0` | UIScene support (16.1.0; this app already uses `FlutterSceneDelegate`), `configureNotificationCenterDelegate()`, Android `deniedPermanently` (16.7.0) |
| `firebase_core` | `^3.6.0` → `^4.15.0` | 16.7.0 needs `^4.14.0`. With core 3.6.0 only `firebase_messaging` 15.1.3 resolves (15.2.10 needs core 3.15.2); 15.x has no UIScene support |
| `firebase_auth` | `^5.3.1` → `^6.7.0` | must move with core 4; `lib/` analyzes clean against it |
| `flutter_local_notifications` | `^19.5.0` (direct) | channel creation and `cancelAll()`; `alice ^1.0.0` pins `^19.4.0`, 22.x waits for an alice upgrade |

Core 4 needs iOS 15.0 (`ios/Podfile` `platform :ios, '15.0'`, then
`pod install`), Firebase iOS SDK 12 and Android BoM 34. Upgrade in its own
commit first.

## Files to create

| Layer | Path | Content |
|---|---|---|
| Entities | `lib/domain/entities/push/push_message.dart` | `PushMessage{id, type, title, body, link}`, `PushMessage.fromData`, `PushType`, `PushPermission`, `PushEvent` (`PushReceivedInForeground`, `PushOpened`) |
| Ports | `lib/domain/repositories/push_repo.dart` | `permission`, `requestPermission`, `getToken`, `tokenRefreshes`, `events`, `deleteToken`, `clearDelivered`; `PushFailure{code}` |
|  | `lib/domain/repositories/push_device_repo.dart` | `register(token)`, `unregister(token)` |
| UseCase | `lib/domain/use_case/push_use_case.dart` | `onSignedIn()`, `onSignedOut()` with a revision counter; never throw |
| SDK adapter | `lib/data/repositories/firebase_push_repo.dart` | verified code in the test file |
| Device adapter | `lib/data/repositories/push_device_repo_impl.dart` + remote DS | `POST /devices` (upsert, timestamp), `DELETE /devices/{token}` |
| Background handler | `lib/bootstrap.dart` | `onBackgroundMessage` before `runApp`; `createChannel()` after DI |
| Cubit | `lib/presentation/push/cubit/push_cubit.dart` | `start()`, `checkPermission()`, `requestPermission()` |
| State/effect | `.../push_state.dart`, `push_effect.dart` | `permission`; `PushShowBannerEffect(message)`, `PushOpenLinkEffect(link)` |
| App wiring | `lib/core/app/main_app.dart` | banner via the shared Flushbar helper; link → `DeepLinkCubit.openUri` |

## Native setup

- Android `AndroidManifest.xml` `<application>`:
  `<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="default_channel"/>`,
  `...default_notification_icon` → `@drawable/ic_notification` (white
  silhouette on transparent), `...default_notification_color` →
  `@color/notification`. `POST_NOTIFICATIONS`, `WAKE_LOCK` and the FCM
  service merge from the plugin manifest; `minSdk 24`, `compileSdk 36`,
  desugaring already set.
- iOS Xcode Signing & Capabilities: Push Notifications (`aps-environment`
  in `Runner.entitlements`, already `development`; distribution signing sets
  `production`) and Background Modes → Background fetch + Remote
  notifications (`UIBackgroundModes` `fetch`, `remote-notification`, already
  present). Keep `FirebaseAppDelegateProxyEnabled` unset (swizzling on).
- `AppDelegate.swift`, first line of `didFinishLaunchingWithOptions`:
  `FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()` (UIScene
  registers plugins after launch); `Runner-Bridging-Header.h`:
  `#import <firebase_messaging/FLTFirebaseMessagingPlugin.h>`.
- Firebase console → Cloud Messaging: upload the APNs auth key (.p8, key ID,
  team ID). Test on a real device; simulators have no APNs token.

## Payload contract (agree with the server)

```json
{ "notification": { "title": "...", "body": "..." },
  "data": { "id": "n-123", "type": "orderStatus",
            "link": "https://app.example.com/orders/o-1" },
  "android": { "priority": "high",
               "notification": { "channel_id": "default_channel" } } }
```

Always a notification message: the OS shows it in background and terminated
state, and a tap reaches `getInitialMessage`/`onMessageOpenedApp`. Data-only
messages are not delivered to a terminated iOS app or a force-stopped
Android app, iOS throttles them to 2–3 per hour, and high-priority data
messages without a visible notification get deprioritized; using them needs
a decision. `data` values are strings, total ≤ 4096 bytes, no keys starting
`google.`/`gcm.`/`from`. `type` maps to `PushType`; unknown is never routed.
`link` must be an allowlisted app link.

## Registration lifecycle

- `onSignedIn()` after `SessionRepo.start` and at every start with a
  restored session: register the current token and every rotated one.
  Re-registering on start keeps the server timestamp fresh; the server drops
  tokens on FCM `UNREGISTERED`/`INVALID_ARGUMENT` and after ~30 days stale.
- iOS: `getToken` returns null until the APNs token exists; the token then
  arrives on `tokenRefreshes`.
- `onSignedOut()` before `SessionRepo.end()` (logout and
  `SessionExpiryCoordinator.expire`): unregister while credentials still
  exist, then `deleteToken()` and `clearDelivered()` even if the server call
  failed, so no user's pushes reach the next user of the device.
- A revision counter undoes a registration finishing after sign-out
  (storage rule 6). Failures never block sign-in or sign-out.

## Flow

- Foreground message → `PushShowBannerEffect` only (iOS presentation options
  stay off; Android shows nothing in the foreground).
- Tap (background, or the one that launched the app, read once per process)
  → `PushOpenLinkEffect` → `DeepLinkCubit.openUri(link)`, which applies the
  allowlist, the ready gate and the session gate ([deep_link.md](deep_link.md)).
  The Cubit drops a repeat of the same message id.
- Tap without a link only opens the app.
- Ask for permission after an in-app explanation, at a moment that needs it
  ("notify me when it ships"), never at launch; on Android 13+ new installs
  start with notifications off. `permanentlyDenied` → offer system settings
  through the permission pattern ([permission.md](permission.md)). Denied is
  a valid state; the app works without push. Re-check on resume.

## Security and performance

- No personal data or secrets in the payload; send an id, load after auth.
- A notification action never performs an operation by itself (attack class
  "Push notification actions").
- Do not log tokens or payloads.
- Background handler: own isolate, no DI, `Firebase.initializeApp()`, < 30 s.

## Test checklist

- [ ] `fromData`: full contract, unknown type kept, missing/invalid id
      dropped.
- [ ] Sign-in registers the token; rotation re-registers; a late (iOS) token
      is registered; no push service → sign-in still completes.
- [ ] Sign-out unregisters, deletes the token (even if the API fails),
      clears the tray, ignores rotations; a late registration is undone.
- [ ] Cubit: foreground → banner; tap with link → open-link; same tap twice →
      one effect; tap without link → nothing; start reads permission without
      asking; permission stored; close stops listening.

## Nguồn

- FCM: https://firebase.google.com/docs/cloud-messaging/flutter/client,
  `.../flutter/receive-messages`, `.../manage-tokens`,
  `.../customize-messages/set-message-type`, `.../android/message-priority`,
  `.../android/client`
- https://pub.dev/packages/firebase_messaging (16.7.0: CHANGELOG, README "iOS
  apps using UIScene"), https://pub.dev/packages/firebase_core,
  https://pub.dev/packages/flutter_local_notifications
- https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- https://developer.android.com/develop/ui/views/notifications/notification-permission,
  `.../notifications/channels`
- https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app,
  `.../asking-permission-to-use-notifications`
- https://github.com/firebase/flutterfire/pull/18482 (FID `register()`,
  merged 2026-09-25, not released)
