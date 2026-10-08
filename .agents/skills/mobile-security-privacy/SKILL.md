---
name: mobile-security-privacy
description: >
  Assess or implement mobile security and privacy controls in Flutter apps.
  Use for authentication, token storage/refresh, logging, network inspection,
  Firebase/analytics data, permissions, PII, deep links, release secrets or a
  security review or "bảo mật/dữ liệu cá nhân". Prioritize concrete data flows
  and exploit conditions.
---

# Mobile security and privacy

## Trace the data

Identify data collected, its origin, destination, storage, retention and who
can access it. Inspect both Dart and Android/iOS configuration. Treat logs,
crash reports and network inspectors as data sinks.

Check the relevant threats:

- access/refresh tokens in secure storage, refresh single-flight, account
  switching races, terminal expiry and accidental cross-origin bearer headers;
- HTTPS and endpoint configuration, certificate policy and replay of sensitive
  requests;
- redaction of headers, body fields and PII before logs/Alice/Crashlytics;
- minimal runtime permissions, denial/revocation behavior and platform
  manifest/Info.plist declarations;
- analytics consent and data minimization before adding user/device events;
- signing, Firebase config and CI secrets without printing secret values.

## Attack classes

For a security review or audit, read
[references/mobile-attack-classes.md](references/mobile-attack-classes.md).
It lists Flutter-specific attack classes (deep links, WebView bridges,
exported components, storage after logout, token handling, network) and the
verdict and severity rules below in detail.

## Finding standard

Every candidate names the lower-trust actor, the input it controls, the
control that should stop it, the boundary crossed and the concrete result.
Provide the exact source and reachable condition, exposed asset or user impact,
and a verification step.

Classify each candidate as `confirmed` (complete source trace and safe local
evidence; gets a severity from critical to informational), `needs_validation`
(decided by a fact outside the repo; name that fact; no severity) or
`rejected` (disproved; keep it listed). Try to disprove every candidate before
reporting it. Do not copy live credentials into reports. Separate a
confirmed leak from a potential exposure. A review request does not authorize
rotation, deletion or production configuration changes.

For this base, follow `docs/architecture/networking.md` and the session tests.
Keep production Alice disabled, secrets out of `SharedPreferences` and UI
effects out of the network layer. After a fix, run focused redaction/session
tests and `derry quality`.
