# Rule: Never call .tr() outside the widget tree

## Why

`.tr()` is a `String` extension that requires an active `EasyLocalization` context in the widget tree to resolve the correct locale. Calling it outside the widget tree (inside a Cubit, Repository, or constructor) will either use the fallback locale or crash.

## ❌ Bad

```dart
// In a Cubit constructor — no context yet
class OrderCubit extends Cubit<OrderState> {
  final errorMsg = LocaleKeys.error_network.tr(); // wrong locale or crash

  void placeOrder() {
    emit(OrderFailure(message: LocaleKeys.error_unknown.tr())); // no context
  }
}

// In a static helper
class AppStrings {
  static final title = LocaleKeys.app_title.tr(); // called at class init, before EasyLocalization
}
```

## ✅ Good

```dart
// Cubit emits the key, UI translates
class OrderCubit extends Cubit<OrderState> {
  void placeOrder() {
    emit(const OrderFailure(errorKey: LocaleKeys.error_unknown));
  }
}

// UI receives the key and translates inside build()
BlocBuilder<OrderCubit, OrderState>(
  builder: (context, state) {
    if (state is OrderFailure) {
      return Text(state.errorKey.tr()); // .tr() inside widget tree ✅
    }
    return const SizedBox();
  },
)
```
