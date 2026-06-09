# Rule: Always pass data through constructor — no context.read() in organisms

## Why

`context.read()` and `context.watch()` create an implicit dependency on whatever is above in the widget tree. An Organism using `context.read()` can only exist in screens where that specific BLoC is provided — it is no longer reusable.

## ❌ Bad

```dart
class CartSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ CartSummary now requires CartCubit to be in the tree above it
    final summary = context.watch<CartCubit>().state.summary;

    return Column(children: [
      AppText('Subtotal: ${summary.subtotal}', variant: AppTextVariant.body),
      AppText('Total: ${summary.total}', variant: AppTextVariant.title),
    ]);
  }
}

// ProfileHeader reading user from BLoC directly
class ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileBloc>().state.user; // ❌
    return AppAvatar(url: user?.avatarUrl, name: user?.name ?? '');
  }
}
```

## ✅ Good

```dart
// CartSummary receives a value object — works anywhere
class CartSummary extends StatelessWidget {
  final CartSummaryData summary; // ✅ plain data, no BLoC dependency

  const CartSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AppText('Subtotal: ${summary.subtotal}', variant: AppTextVariant.body),
      AppText('Total: ${summary.total}', variant: AppTextVariant.title),
    ]);
  }
}

// Page extracts data from BLoC and passes it down
BlocBuilder<CartCubit, CartState>(
  builder: (context, state) => CartSummary(summary: state.summary), // ✅
)
```

## Exception

`context.read<ThemeCubit>()` or `context.read<LocalizationCubit>()` for app-wide concerns (theme, locale) are acceptable inside any layer because they are always provided at the root.
