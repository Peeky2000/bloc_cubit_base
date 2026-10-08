# Deep links

Decision: [D-0006](../../../../docs/decisions/D-0006-deep-link-qua-domain-port.md)
(proposed). Reference code: `test/patterns/deep_link_pattern_test.dart`.

## When to use

A URL from outside opens a screen: App Links, Universal Links, a custom
scheme, push taps. `optional-capabilities.md` defers deep links until product
routes and ownership are known; this is the shape to use then.

## Decision

Verified `https` links (App Links + Universal Links) are the primary
channel; the custom scheme is a fallback for links that are safe to leak. A
domain port `DeepLinkRepo` exposes `Stream<Uri>` (adapter on `app_links`);
one domain parser `AppLinkParser` turns an allowlisted URI into a sealed
`AppLinkTarget`; an app-scope `DeepLinkCubit` holds a link until splash is
done and the user is signed in, then emits a typed effect that the app
listener maps to `SLIRouting`.

Package: `app_links: ^7.2.2` (publisher cow-level.ovh). 7.2.2 replays every
link received before the first listen and no longer resends the launch link
when the Android activity is rebuilt; 7.1+ needs Flutter ≥ 3.44 (we use
3.44.5). Android `compileSdk 36`, `minSdk 24` (Flutter defaults).

## Files to create

| Layer | Path | Content |
|---|---|---|
| Targets | `lib/domain/entities/link/app_link_target.dart` | `sealed AppLinkTarget{requiresSession}`; `OrderDetailLink(orderId)`, `InviteLink(code)`, `PromotionLink(promotionId)` |
| Parser | `lib/domain/entities/link/app_link_parser.dart` | `parse(Uri) → AppLinkTarget?`; `hosts`, `scheme` |
| Port | `lib/domain/repositories/deep_link_repo.dart` | `Stream<Uri> watchLinks()` (launch link first) |
| Adapter | `lib/data/repositories/app_links_deep_link_repo.dart` | `uriLinkStream`; `AppLinks` from `RegisterModule` (sketch in the test file, analyzed) |
| UseCase | `lib/domain/use_case/deep_link_use_case.dart` | `watchTargets()`, `isSignedIn` from `SessionRepo` |
| Cubit | `lib/presentation/deep_link/cubit/deep_link_cubit.dart` | `start()`, `markReady()`, `onSessionStarted()`, `openUri(uri)` |
| State/effect | `.../deep_link_state.dart`, `deep_link_effect.dart` | `ready`, `pending`; `DeepLinkOpenEffect(target)`, `DeepLinkSignInRequiredEffect` |
| App wiring | `lib/core/app/main_app.dart` | Cubit resolved in `buildMainApp()`; `BlocListener` → `handleDeepLinkEffect` |
| Routes | `lib/core/common/route.dart` | one `AppPage` per destination |

## Native setup (exact keys)

Android, inside `.MainActivity` (already `singleTop`):

```xml
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="app.example.com" />
  <data android:pathPrefix="/orders/" /><data android:pathPrefix="/invites/" />
  <data android:pathPrefix="/promotions/" />
</intent-filter>
<intent-filter> <!-- custom scheme: no autoVerify -->
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="blocbase" />
</intent-filter>
```

`https://app.example.com/.well-known/assetlinks.json` (HTTPS, no redirect,
`application/json`; the **Play App Signing** SHA-256 plus upload/debug keys):

```json
[{"relation": ["delegate_permission/common.handle_all_urls"],
  "target": {"namespace": "android_app", "package_name": "com.giaohang247",
             "sha256_cert_fingerprints": ["AA:BB:…"]}}]
```

iOS: `Runner.entitlements` →
`com.apple.developer.associated-domains` = `["applinks:app.example.com"]`
(`applinks:app.example.com?mode=developer` while testing);
`Info.plist` → `<key>FlutterDeepLinkingEnabled</key><false/>` and a
`CFBundleURLTypes` entry for `blocbase`. The app uses `FlutterSceneDelegate`;
app_links 7 handles it with no Swift code. Host
`https://app.example.com/.well-known/apple-app-site-association` (no
extension, no redirect, JSON):

```json
{"applinks": {"details": [{"appIDs": ["<TEAMID>.com.giaohang247"],
  "components": [{"/": "/orders/*"}, {"/": "/invites/*"},
                 {"/": "/promotions/*"}]}]}}
```

Flutter's built-in deep linking is off on both platforms because it pushes
the raw path to `onGenerateRoute` (`MainApp.generator` throws on unknown
names) and bypasses the allowlist and session gate.

## Flow

1. `MainApp.initState` → `deepLinkCubit.start()`. The plugin buffers the
   cold-start link; read only `uriLinkStream` (adding `getInitialLink()`
   opens the launch link twice).
2. Links before splash placed the first route are `pending` (latest wins).
3. Splash calls `markReady()` after it navigated → pending is handled.
4. `requiresSession && !isSignedIn` → keep pending, emit
   `DeepLinkSignInRequiredEffect`; the auth flow calls `onSessionStarted()`
   and the same link opens.
5. Otherwise emit `DeepLinkOpenEffect(target)` and clear pending.
6. The listener (`listenWhen: previous.effect != current.effect`) maps each
   target with an exhaustive `switch` to
   `SLIRouting.toNamed(AppPage.x, arguments: id, preventDuplicates: false)`;
   without the flag a second order link is dropped while an order is open.
7. Push taps call `openUri(uri)` and pass the same parser and gates.

Map the link stream with operators, not `async*`: cancelling an `async*`
generator waits for the next event, so `close()` hung in tests.

## Security (the main concern)

- Allowlist only: `https` + exact host, or the app's scheme with a host.
  Reject port, user-info, unknown paths, extra segments, bad `%` escapes and
  ids outside `[A-Za-z0-9_-]{1,64}`. Parsing never throws.
- Custom schemes can be registered by any app (Android shows a chooser; on
  iOS the target is undefined). Links with a secret (invite code, reset
  token) are accepted only from verified https (`InviteLink` test).
- A link only navigates and carries ids. It never signs in, confirms OTP,
  accepts an invite, pays or changes data; the destination asks the user to
  confirm and loads data through the API, which checks ownership.

## Test checklist

- [ ] Parser accepts each allowlisted form (https, mixed-case host, scheme,
      query ignored) and rejects other hosts, schemes, port, user-info,
      paths, ids and `%FF`; invites only over https.
- [ ] Cold-start link waits for `markReady`; latest pending wins.
- [ ] Signed out: sign-in effect, pending kept, opens after
      `onSessionStarted`. Public link opens without a session.
- [ ] Unknown link changes nothing; the same link twice opens twice.
- [ ] `openUri` (push) uses the same parser and gate; `close()` cancels.
- [ ] Widget: listener routes via `SLIRouting` to sign-in, the destination,
      then a second destination of the same route.
- [ ] Device, cold (app killed) and warm:
      `adb shell pm verify-app-links --re-verify com.giaohang247` then
      `adb shell pm get-app-links com.giaohang247` shows `verified`;
      `adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://app.example.com/orders/o-1"`;
      `xcrun simctl openurl booted "https://app.example.com/orders/o-1"`;
      AASA cache: `https://app-site-association.cdn-apple.com/a/v1/app.example.com`.

## Nguồn

- Flutter deep linking and opt-out: https://docs.flutter.dev/ui/navigation/deep-linking
- Flutter App Links / Universal Links cookbooks: https://docs.flutter.dev/cookbook/navigation/set-up-app-links,
  https://docs.flutter.dev/cookbook/navigation/set-up-universal-links
- Android App Links and verification: https://developer.android.com/training/app-links,
  https://developer.android.com/training/app-links/verify-applinks
- Android unsafe deep links: https://developer.android.com/privacy-and-security/risks/unsafe-use-of-deeplinks
- Apple associated domains, custom schemes, TN3155: https://developer.apple.com/documentation/xcode/supporting-associated-domains,
  https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app,
  https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links
- app_links: https://pub.dev/packages/app_links (changelog 7.2.2, `doc/README_ios_7.md`)
