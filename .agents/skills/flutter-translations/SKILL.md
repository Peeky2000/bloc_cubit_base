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

## Cubit/BLoC boundary

Do not pass or resolve `BuildContext` in a state owner. Cubit/BLoC emits typed
validation/error values; the widget or `BlocListener` maps them through
`context.l10n`.

## Add a new string

1. Add key to `app_en.arb` and `app_vi.arb`
2. Run `flutter gen-l10n` or `flutter pub get` (`flutter: generate: true`)

## Server message codes (optional)

Keep server codes as typed values until the UI boundary. Any remote catalog must
be authenticated/validated and must not make domain or data depend on l10n.

## Rules

- **No** `easy_localization`, **no** `context.tr()`, **no** `assets/translations/*.json`
- **No** hardcoded user-facing strings in widgets
- Keys: `camelCase` in ARB (match existing files)

## References

- `references/setup.md`, `references/usage-in-ui.md` — use ARB/gen-l10n mentally
