# Rule: Always use LocaleKeys.xxx.tr(), never hardcode strings

## Why

- Hardcoded strings are never translated → language bug
- Not compile-time safe → typos are only caught at runtime
- `LocaleKeys` is generated from JSON → renaming a key in JSON immediately surfaces an IDE error

## ❌ Bad

```dart
// Hardcoded Vietnamese — never gets translated
Text('Đăng nhập')

// Raw string key — not type-safe
Text('auth.login'.tr())
Text(tr('auth.login'))
```

## ✅ Good

```dart
// Generated key — type-safe and refactorable
Text(LocaleKeys.auth_login.tr())
```

## Correct workflow when adding new text

1. Add the key to both `vi.json` and `en.json`
2. Run generate: `flutter pub run easy_localization:generate -S assets/translations -f keys -O lib/l10n -o locale_keys.g.dart`
3. Use `LocaleKeys.xxx.tr()` in the widget
