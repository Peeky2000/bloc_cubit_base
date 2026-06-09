# Setup easy_localization

## 1. pubspec.yaml

```yaml
dependencies:
  easy_localization: ^3.0.3
  flutter_localizations:
    sdk: flutter

flutter:
  assets:
    - assets/translations/
```

## 2. l10n.dart — list of supported locales

```dart
// lib/core/localization/l10n.dart
import 'package:flutter/material.dart';

class L10n {
  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  static const Locale fallbackLocale = Locale('vi');
  static const String translationsPath = 'assets/translations';
}
```

## 3. main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: L10n.supportedLocales,
      path: L10n.translationsPath,
      fallbackLocale: L10n.fallbackLocale,
      child: const MyApp(),
    ),
  );
}
```

## 4. MaterialApp

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // ...
    );
  }
}
```

## 5. Generate LocaleKeys

Run once after adding or editing JSON keys:

```bash
flutter pub run easy_localization:generate \
  -S assets/translations \
  -f keys \
  -O lib/l10n \
  -o locale_keys.g.dart
```

Output file: `lib/l10n/locale_keys.g.dart`

```dart
// GENERATED — do not edit manually
abstract class LocaleKeys {
  static const auth_login = 'auth.login';
  static const auth_logout = 'auth.logout';
  static const common_confirm = 'common.confirm';
}
```

## 6. iOS — Info.plist

```xml
<key>CFBundleLocalizations</key>
<array>
  <string>vi</string>
  <string>en</string>
</array>
```