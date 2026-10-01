---
name: mobile-release-readiness
description: >
  Audit a Flutter Android/iOS build before distribution or store release. Use
  for release readiness, flavor/signing review, versioning, Firebase mapping,
  build automation, crash visibility, privacy declarations, "chuẩn bị release"
  or rollout/rollback planning. Produce a go/no-go result backed by commands
  and artifacts.
---

# Mobile release readiness

## Evidence to collect

- Correct flavor/entrypoint, package/bundle identifier, app display name,
  version/build number and API/Firebase environment mapping.
- Android manifest/Gradle and iOS Xcode schemes/entitlements/signing match the
  intended audience; no personal key or provisioning profile is committed.
- `derry gen` when generation inputs changed, `derry quality`, focused device
  smoke and build artifact for each target platform.
- Authentication, offline/401 handling, navigation, permissions, accessibility
  and basic startup/scrolling work on release/profile builds.
- Crash reporting and privacy/consent configuration are appropriate for the
  target app. Rollout owner, monitoring signals and rollback path are known.

Separate local build, Firebase tester distribution and Store upload. In this
base, use `derry build`, `derry distribute` and `derry release` according to
`docs/guides/use-derry-and-build.md`. Inspect current Fastlane product names,
Firebase client files and credentials before recommending a real upload.

## Output

Give `GO`, `CONDITIONAL` or `NO-GO`; list evidence, blocking findings, owner and
verification required. Read-only audit does not upload, tag, rotate secrets or
change store state. Do not call a release ready because tests pass in debug
mode alone.
