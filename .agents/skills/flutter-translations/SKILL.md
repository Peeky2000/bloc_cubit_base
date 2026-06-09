---
name: flutter-translations
description: >
  Localization for this base using Flutter gen-l10n (ARB files) and optional server
  message codes. Trigger: "l10n", "translation", "arb", "localize".
---

# Translations — gen-l10n

## Files

```
lib/l10n/arb/
├── app_en.arb
├── app_vi.arb
└── app_localizations.dart      # generated

lib/l10n/l10n.dart              # export + extension
```

Config: `l10n.yaml` at project root.

## Usage in widgets

```dart
import 'package:<app>/l10n/l10n.dart';

Text(context.l10n.passIsRequired)
```

## Usage in Cubit (existing pattern)

```dart
final ctx = Injector.getIt.get<AppController>().context;
ctx?.l10n.emailPhoneIsInvalid
```

## Add a new string

1. Add key to `app_en.arb` and `app_vi.arb`
2. Run `flutter gen-l10n` or `flutter pub get` (`flutter: generate: true`)

## Server message codes (optional)

See root `README.md`:
- `ServerMessageLocalization.delegate` in main
- `assets/server_localization/`
- `get_message_code.bash` for fetching JSON from server
- `error_mapper` / `messageServerTranslate` for API errors

## Rules

- **No** `easy_localization`, **no** `context.tr()`, **no** `assets/translations/*.json`
- **No** hardcoded user-facing strings in widgets
- Keys: `camelCase` in ARB (match existing files)

## References

- `references/setup.md`, `references/usage-in-ui.md` — use ARB/gen-l10n mentally
