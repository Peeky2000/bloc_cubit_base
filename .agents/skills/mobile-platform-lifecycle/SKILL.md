---
name: mobile-platform-lifecycle
description: >
  Review or implement Flutter app lifecycle and Android/iOS integration. Use
  for background/foreground transitions, subscriptions, controllers, app links,
  permissions, process death, platform channels, push callbacks or native
  configuration, "vòng đời app" or "rò rỉ subscription". Verify resource
  ownership and behavior across lifecycle edges.
---

# Mobile platform lifecycle

## Workflow

1. Identify owners of controllers, subscriptions, timers, observers, streams,
   sockets and native callbacks. Match every registration with disposal or an
   application-lifetime owner.
2. Trace transitions: launch, resume, pause/background, process recreation,
   route removal, logout/account switch and permission revocation. Check async
   callbacks against `mounted`/`isClosed` before UI/state writes.
3. Inspect platform-specific behavior: Android Activity/manifest, iOS
   Info.plist/entitlements, app links, notification callbacks and plugin
   initialization order only where the feature uses them.
4. Verify on the smallest relevant level: unit seam for owner lifecycle,
   widget test for navigation/listeners, device test for OS behavior. Record
   device/OS and the transitions exercised.

In this base, keep `NetworkChecker` and session coordinator lifetime tied to
generated DI disposal; Cubit/BLoC route ownership belongs to the composition
boundary. `BuildContext` stays out of Cubit and data layers. Avoid assuming a
hot reload reproduces cold-start or process-death behavior.

Output a transition table or concise sequence when multiple states interact,
with exact code locations and unverified device behavior stated plainly.
