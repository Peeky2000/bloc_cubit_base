# Deep links

Decision: [D-0006](../../../../docs/decisions/D-0006-deep-link-qua-domain-port.md)
(proposed). Reference code: `test/patterns/deep_link_pattern_test.dart`.

## When to use

A URL from outside opens a screen in the app: App Links (Android), Universal
Links (iOS), a custom scheme from email or QR, and push notification taps.
`docs/architecture/optional-capabilities.md` lists deep links as deferred
until product routes and ownership rules are known; this pattern is the shape
to use once they are.

## Decision

A domain port `DeepLinkRepo` exposes `Stream<Uri>` (adapter on `app_links`,
proposed); one domain parser `AppLinkParser` turns an allowlisted URI into a
sealed `AppLinkTarget`; an app-scope `DeepLinkCubit` holds a link until the
app is ready and the user is signed in, then emits a typed effect that the
app listener maps to `SLIRouting`.

## Files to create

| Layer | Path | Content |
|---|---|---|
| Targets | `lib/domain/entities/link/app_link_target.dart` | `sealed class AppLinkTarget{requiresSession}`; one subclass per destination (`OrderDetailLink(orderId)`, `InviteLink(code)`, `PromotionLink(promotionId)`) |
| Parser | `lib/domain/entities/link/app_link_parser.dart` | `AppLinkParser.parse(Uri) → AppLinkTarget?`; `hosts`, `scheme` |
| Port | `lib/domain/repositories/deep_link_repo.dart` | `Stream<Uri> watchLinks()` (initial link first) |
| Adapter | `lib/data/repositories/app_links_deep_link_repo.dart` | `AppLinks().uriLinkStream` (sketch in the test file) |
| UseCase | `lib/domain/use_case/deep_link_use_case.dart` | `watchTargets()`, `isSignedIn` from `SessionRepo` |
| Cubit | `lib/presentation/deep_link/cubit/deep_link_cubit.dart` | `start()`, `markReady()`, `onSessionStarted()`, `openUri(uri)` |
| State/effect | `.../deep_link_state.dart`, `deep_link_effect.dart` | `ready`, `pending`; `DeepLinkOpenEffect(target)`, `DeepLinkSignInRequiredEffect` |
| App wiring | `lib/core/app/main_app.dart` | resolve the Cubit once in `buildMainApp()`, `BlocListener` → `handleDeepLinkEffect` |
| Routes | `lib/core/common/route.dart` | `AppPage` entries for each destination |
| Native | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Runner.entitlements`, `Info.plist` | intent-filter `autoVerify`, Associated Domains, custom scheme |
| Hosting | `https://<host>/.well-known/assetlinks.json`, `apple-app-site-association` | signing fingerprint, team id |

## Flow

1. `MainApp.initState` → `deepLinkCubit.start()` (listens once).
2. A link before splash has placed the first route is stored as `pending`
   (latest wins).
3. Splash calls `markReady()` after it navigated → pending is handled.
4. `requiresSession && !isSignedIn` → keep pending, emit
   `DeepLinkSignInRequiredEffect`. After sign-in, the auth flow calls
   `onSessionStarted()` → the same link opens.
5. Otherwise emit `DeepLinkOpenEffect(target)` and clear pending.
6. The app listener (`listenWhen: previous.effect != current.effect`) maps
   each target to `SLIRouting.toNamed(AppPage.x, arguments: id)` with an
   exhaustive `switch`.
7. Push taps call `openUri(uri)` and pass the same parser and gates.

## Security (the main concern)

- Allowlist only: `https` + exact host in `AppLinkParser.hosts`, or the app's
  own scheme. Reject ports, user-info, unknown paths, extra segments, and ids
  outside `[A-Za-z0-9_-]{1,64}`. Unknown links do nothing.
- A link only navigates. It never signs in, confirms OTP, accepts an invite,
  pays or changes data by itself; the destination screen asks the user to
  confirm (see `mobile-security-privacy/references/mobile-attack-classes.md`).
- A link carries ids only. The destination loads data through the API, which
  checks ownership; never trust an id in a link to select another user's
  data.
- Disable Flutter's built-in deep linking
  (`flutter_deeplinking_enabled=false` in the manifest,
  `FlutterDeepLinkingEnabled=NO` in Info.plist): `MainApp.generator` uses
  `firstWhere` and throws for an unknown route name, and two readers of the
  same link would navigate twice.
- Custom schemes can be claimed by other apps; use them only for links that
  are safe to open anyway.

## Implementation trap

Map the link stream with operators (`map`/`where`), not an `async*` loop:
cancelling an `async*` generator waits until the source's next event, so
`DeepLinkCubit.close()` hung in tests until this was changed.

## Error, empty, offline

Parsing never throws. Offline is handled by the destination screen like any
other load.

## Performance

Create the adapter in `bootstrap`/DI so the cold-start link is not missed;
the Cubit buffers it until `markReady`.

## Test checklist

- [ ] Parser accepts each allowlisted form (https, custom scheme, query
      ignored) and rejects every other host, scheme, port, user-info, path
      and id shape.
- [ ] Cold-start link waits for `markReady`; latest pending wins.
- [ ] Signed out: sign-in effect, pending kept, opens after
      `onSessionStarted`.
- [ ] Public link opens without a session.
- [ ] Unknown link changes nothing; the same link twice opens twice.
- [ ] `openUri` (push) uses the same parser and gate.
- [ ] `close()` cancels the subscription.
- [ ] Widget: listener routes through `SLIRouting` to sign-in, then the
      destination.

Reference code: `test/patterns/deep_link_pattern_test.dart`
