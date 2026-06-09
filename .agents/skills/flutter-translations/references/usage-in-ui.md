# Usage in UI

## Import

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:your_app/l10n/locale_keys.g.dart';
```

## Basic — .tr()

```dart
// Inside widget build()
Text(LocaleKeys.auth_login.tr())
Text(LocaleKeys.common_confirm.tr())
```

## Args — positional parameters via {}

JSON: `"auth_welcome": "Hello, {}!"`

```dart
Text(LocaleKeys.auth_welcome.tr(args: ['Anna']))
// Output: "Hello, Anna!"
```

## Named args — named parameters

JSON: `"order_summary": "Order {id} - {status}"`

```dart
Text(
  LocaleKeys.order_summary.tr(
    namedArgs: {'id': '123', 'status': 'Shipping'},
  ),
)
```

## Plural

JSON:
```json
"product_count": {
  "zero": "No products",
  "one": "{} product",
  "other": "{} products"
}
```

```dart
Text(LocaleKeys.product_count.plural(itemCount))
```

## Change language at runtime

```dart
// Inside onTap or a Cubit method
ElevatedButton(
  onPressed: () => context.setLocale(const Locale('en')),
  child: const Text('English'),
)

ElevatedButton(
  onPressed: () => context.setLocale(const Locale('vi')),
  child: const Text('Tiếng Việt'),
)
```

## Read current locale

```dart
final currentLocale = context.locale;         // Locale('vi')
final langCode = context.locale.languageCode;  // 'vi'
```

## Reset to fallback locale

```dart
context.resetLocale();
```

## Using translations with Cubit/BLoC

`.tr()` requires a `BuildContext` — it cannot be called inside a Cubit. Instead, emit the translation key from the Cubit and translate in the UI:

```dart
// ❌ Wrong — Cubit has no BuildContext
class ProductCubit extends Cubit<ProductState> {
  void load() {
    emit(ProductError(LocaleKeys.error_network.tr())); // no context → wrong locale or crash
  }
}

// ✅ Correct — emit the key, translate in the UI
// Cubit emits the raw key
emit(ProductError(errorKey: LocaleKeys.error_network));

// UI translates inside build()
Text(state.errorKey.tr())
```
