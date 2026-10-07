# Mobile attack classes for Flutter apps

Adapted for Flutter from `DESKTOP-MOBILE-AND-LOCAL-IPC.md`,
`ATTACK-CLASSES.md` and `VALIDATION-AND-REPORTING.md` in
[cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill),
MIT License, Copyright (c) 2025-2026 Cloudflare, Inc. Rewritten for this
repository's stack; the original full-audit workflow and sandbox procedure are
not included.

## Before any class: name the boundary

For every candidate state the lower-trust actor, the input or action it
controls, the control that should stop it, the boundary crossed, and the
concrete result. Realistic actors for a mobile app:

- another app on the same device;
- a link, push payload, QR code or shared file from outside;
- remote web content inside a WebView;
- a network attacker on an untrusted Wi-Fi;
- the next user of the same device after logout or account switch;
- someone with physical access to an unlocked or backed-up device.

The same user harming their own data with their own authority is not a
finding. A missing best practice with no reachable boundary is hardening, not
a vulnerability.

## Deep links, callbacks and navigation

- **Deep link changes state.** A custom scheme, App Link or Universal Link
  opens a route that logs in, confirms OTP, accepts an invite, pays or changes
  account data without a current session and a one-time token. Check route
  parsing in `SLIRouting`, `AndroidManifest.xml` intent filters and
  `Info.plist` URL types.
- **Route arguments trusted blindly.** Arguments from a link select another
  user id, order id or phone number and the screen loads it without the API
  re-checking ownership.
- **Auth callback lands in the wrong place.** OAuth, OTP or password reset
  results return to a stale screen or another account because state is not
  bound to the initiating session.

## WebView and JavaScript bridges

- **Bridge reachable from remote origins.** A `JavascriptChannel` or
  `addJavaScriptHandler` meant for bundled pages is callable after a
  navigation, redirect or iframe to another origin. Check origin at call time.
- **Bridge too powerful.** Web content can pick files, URLs, tokens or native
  actions through a generic bridge method.
- **File or universal access.** WebView settings let remote content read app
  files or internal schemes.

## Exported components and platform entry points

- **Exported Android components.** An activity, service, receiver or provider
  is `exported="true"` or has an intent filter and performs an app-internal
  action. Review the merged manifest, not only `src/main`.
- **FileProvider paths too wide.** `file_paths.xml` exposes the app data
  directory.
- **Push notification actions.** A notification action performs an operation
  different from what was shown, or after logout.

## Storage, tokens and secrets

- **Token in the wrong store.** Access or refresh tokens in
  `SharedPreferences`, plain files, logs, Alice or crash reports instead of
  `flutter_secure_storage`.
- **Data survives logout or account switch.** Cached responses, secure
  storage keys, DI singletons, images, local databases or Cubit state remain
  and appear for the next account.
- **Backups leak data.** `android:allowBackup` or iOS backup includes caches
  with personal data.
- **Secrets shipped in the app.** API keys with server privileges, signing
  keys or production credentials in Dart, assets, `--dart-define` defaults or
  native config. Client keys that are public by design, such as Firebase
  config, are not findings by themselves.

## Network

- **Cleartext or weak TLS.** `usesCleartextTraffic`, NSAllowsArbitraryLoads,
  a custom `badCertificateCallback` returning true, or pinning disabled in
  production.
- **Bearer token sent to the wrong host.** An interceptor adds the token to
  every request, including third-party URLs or redirects.
- **Refresh race.** Concurrent 401 responses trigger parallel refreshes, a
  stale token overwrites a new one, or logout loses to a late refresh.
- **Inspector in production.** Alice or verbose logging reachable in a
  release build.

## Verdicts

- **confirmed**: complete trace from the actor's entry point to the result,
  with source lines and, where safe, a local test or emulator check using a
  dummy account. Only confirmed findings get a severity.
- **needs_validation**: the source path exists but a fact outside the repo
  decides it, such as merged manifest, signing, server-side ownership checks
  or OS version. Name the exact missing fact and a safe way to check it. No
  severity.
- **rejected**: the candidate was disproved. Keep it in the report so it is
  not hunted again.

## Severity for confirmed findings

- **critical**: an outside actor with no account takes over arbitrary
  accounts or reads all user data.
- **high**: full bypass of an explicit control with real consequences, such
  as login bypass, reading another user's data, or a deep link that performs
  a payment or account change without consent.
- **medium**: a real boundary violation with limited reach or uncommon
  preconditions.
- **low**: disclosure of non-secret internals, or an effect needing sustained
  effort for little gain.
- **informational**: confirmed but minimal impact.

If you cannot state the concrete damage, the severity is lower than it feels.

## Validation discipline

1. Before reporting, try to disprove each candidate: re-read every cited
   line and look for the guard, server check or platform control that stops
   it. When subagents are available, give each candidate to a fresh verifier
   that did not find it.
2. Never test against production, other users' data or shared services. Use
   dummy accounts, local builds and emulators.
3. Stop at the minimum result that proves the boundary. Do not build
   persistence or exploitation beyond it.
4. Propose the smallest fix at the last trusted decision point, plus a
   regression test.

## Anti-patterns

- Checklist items presented as vulnerabilities.
- Defense-in-depth advice with no reachable boundary violation.
- Guessing server, store or device behavior that is not in the repo.
- Treating the user's own authority over their own data as a finding.
- Assigning severity to needs_validation items.
