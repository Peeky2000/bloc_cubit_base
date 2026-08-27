# Create an App from This Base

## 1. Clone and bootstrap

```bash
git clone --recurse-submodules <base-url> <new-app>
cd <new-app>
dart pub global activate derry
derry bootstrap
```

Create a new repository history only when the project owner explicitly wants
that workflow. Do not detach or delete the `sli_common` submodule accidentally.

## 2. Replace template identity

Change and verify all of the following:

- Dart package name and every `package:bloc_cubit_base/` import.
- Android namespace, application ID, labels, and signing configuration.
- iOS bundle identifier, display name, schemes, and signing team.
- App title, icons, splash, semantic colors, typography, and sample assets.
- Firebase projects/configuration for each real environment.
- API URLs and inspector policy in typed environment configuration.

Never copy signing files, provisioning profiles, credentials, or production
Firebase secrets from another application.

## 3. Remove sample product code intentionally

Decide which example screens/entities are instructional and which should be
deleted. Remove a complete vertical slice, including route, l10n, tests, DI
annotations, assets, and app-memory entries. Do not leave dead generated types.

## 4. Verify

```bash
derry gen
derry quality
git submodule status
```

Run every environment entrypoint and a native debug build. Update README,
prerequisites, architecture decisions, and environment ownership before feature
development begins.
