# Push notifications

Decision: [D-0007](../../../../docs/decisions/D-0007-push-notification-qua-domain-port.md)
(proposed). Reference code: `test/patterns/push_notification_pattern_test.dart`.

## When to use

The server tells the user about something while the app is closed or in the
background: order updates, messages, reminders, promotions.
`docs/architecture/optional-capabilities.md` lists Firebase Messaging as
deferred until the notification contract and navigation are known; this is
the shape to use once they are.

## Decision

A domain port `PushRepo` (adapter on `firebase_messaging` 15.x, matching
`firebase_core` 3.x, proposed) exposes permission, token, token refreshes and
one `Stream<PushEvent>`; `PushUseCase` owns device registration tied to the
session; an app-scope `PushCubit` turns foreground messages into a banner
effect and taps into links that go through the deep link parser.

## Files to create

| Layer | Path | Content |
|---|---|---|
| Entities | `lib/domain/entities/push/push_message.dart` | `PushMessage{id, type, title, body, link}`, `PushMessage.fromData`, `PushType`, `PushPermission`, `PushEvent` (`PushReceivedInForeground`, `PushOpened`) |
| Ports | `lib/domain/repositories/push_repo.dart` | `requestPermission`, `getToken`, `tokenRefreshes`, `events`, `deleteToken`; `PushFailure{code}` |
|  | `lib/domain/repositories/push_device_repo.dart` | `register(token)`, `unregister(token)` |
| UseCase | `lib/domain/use_case/push_use_case.dart` | `onSignedIn()`, `onSignedOut()` with a revision counter |
| SDK adapter | `lib/data/repositories/firebase_push_repo.dart` | sketch in the test file |
| Device adapter | `lib/data/repositories/push_device_repo_impl.dart` + remote DS | `POST /devices`, `DELETE /devices/{token}` |
| Background handler | `lib/core/app/bootstrap.dart` | top-level `@pragma('vm:entry-point')` handler; no DI, no UI |
| Cubit | `lib/presentation/push/cubit/push_cubit.dart` | `start()`, `requestPermission()` |
| State/effect | `.../push_state.dart`, `push_effect.dart` | `permission`; `PushShowBannerEffect(message)`, `PushOpenLinkEffect(link)` |
| App wiring | `lib/core/app/main_app.dart` | banner via the shared Flushbar helper; link → `DeepLinkCubit.openUri` |
| Native | iOS Push capability + APNs key in Firebase; Android 13 `POST_NOTIFICATIONS` | |

## Payload contract (agree with the server)

```json
{ "notification": { "title": "...", "body": "..." },
  "data": { "id": "n-123", "type": "orderStatus",
            "link": "https://app.example.com/orders/o-1" } }
```

`type` values map to `PushType`; unknown types become `PushType.unknown` and
are never routed. `link` must be an allowlisted app link.

## Registration lifecycle

- `onSignedIn()` after `SessionRepo.start`: register the current token and
  every rotated token.
- `onSignedOut()` from the same end path as sign-out and expiry (storage
  rules 4 and 5): unregister on the server, then `deleteToken()` even if the
  server call failed, so no user's pushes reach the next user of the device.
- A revision counter drops (and undoes) a registration that finishes after
  sign-out (storage rule 6).

## Flow

- Foreground message → `PushShowBannerEffect`; the OS shows nothing in the
  foreground unless the adapter asks it to.
- Tap (background or the one that launched the app) → `PushOpenLinkEffect`
  → `DeepLinkCubit.openUri(link)`, which applies the allowlist, the ready
  gate and the session gate ([deep_link.md](deep_link.md)).
- Tap without a link only opens the app.
- Ask for permission from a screen that explains the benefit, never at
  launch. Denied is a valid state; the app works without push.

## Security and performance

- Never put personal data or secrets in the payload; send an id and let the
  app load the data after authentication.
- A notification action never performs an operation by itself (attack class
  "Push notification actions").
- Do not log tokens or payloads.
- The background handler runs in a separate isolate without the DI graph;
  keep it to local writes.

## Test checklist

- [ ] `fromData`: full contract, unknown type kept, missing/invalid id
      dropped.
- [ ] Sign-in registers the token; rotation re-registers.
- [ ] Sign-out unregisters, deletes the token, ignores later rotations.
- [ ] Sign-out deletes the device token even when the API fails.
- [ ] A registration finishing after sign-out is undone.
- [ ] Cubit: foreground → banner; tap with link → open-link; tap without
      link → nothing; permission stored; close stops listening.

Reference code: `test/patterns/push_notification_pattern_test.dart`
