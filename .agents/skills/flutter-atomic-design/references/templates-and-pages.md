# Templates & Pages

---

## Templates

Templates define **where** content goes. They know nothing about **what** the content is.

### Available templates

| Template | Use case | Slots / Props |
|---|---|---|
| `ScaffoldTemplate` | Standard screen | `body`, `appBar`, `bottomBar`, `floatingButton`, `backgroundColor` |
| `ScrollableTemplate` | Screen with scrollable body + standard padding | `body`, `appBar`, `bottomBar` |
| `SliverTemplate` | Screen with collapsible header (detail pages) | `header`, `slivers`, `appBar` |
| `TwoColumnTemplate` | Tablet / landscape two-column layout | `left`, `right`, `breakpoint` |
| `ModalTemplate` | Bottom sheet or dialog layout | `title`, `body`, `actions`, `height` |
| `AuthTemplate` | Auth screens: logo + form + footer | `body`, `footer`, `showLogo` |
| `LoadingTemplate` | Full-screen loading | `message` |
| `ErrorTemplate` | Full-screen error | `message`, `onRetry` |
| `EmptyTemplate` | Full-screen empty state | `title`, `subtitle`, `onAction` |

### Template rules

- Templates import only from `shared/` — never from `features/`
- All children are typed as `Widget` or `PreferredSizeWidget` — never domain objects
- No `BlocProvider`, `BlocBuilder`, or `context.read` inside a template

```dart
// ✅ Correct template
class AuthTemplate extends StatelessWidget {
  final Widget body;
  final Widget? footer;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          if (showLogo) const AppLogo(),
          Expanded(child: body),
          if (footer != null) footer!,
        ]),
      ),
    );
  }
}
```

---

## Pages

Pages are **thin connectors**: inject BLoC, read route params, map state → props.

### Page anatomy

```dart
class OrderDetailPage extends StatelessWidget {
  final String orderId; // ← from GoRouter path param

  @override
  Widget build(BuildContext context) {
    return BlocProvider(                                    // 1. Inject BLoC
      create: (_) => getIt<OrderDetailCubit>()
        ..loadOrder(orderId),                              // 2. Trigger initial load
      child: BlocListener<OrderDetailCubit, OrderDetailState>(
        listener: (context, state) {                       // 3. Side effects (nav, toast)
          if (state is OrderDetailCancelSuccess) {
            context.pop();
          }
        },
        child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) => ScaffoldTemplate(   // 4. Pick template
            appBar: AppTopBar(title: LocaleKeys.order_detail.tr()),
            body: switch (state) {                         // 5. Map state → organism
              OrderDetailLoading() => const SkeletonCard(),
              OrderDetailLoaded(:final order) => OrderDetailBody(
                  order: order,
                  onCancel: () => context.read<OrderDetailCubit>().cancelOrder(),
                ),
              OrderDetailError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context.read<OrderDetailCubit>().loadOrder(orderId),
                ),
              _ => const SizedBox(),
            },
          ),
        ),
      ),
    );
  }
}
```

### Page examples from the app

```
LoginPage          →  BlocProvider<AuthBloc>          + AuthTemplate      + LoginForm
ProductListPage    →  BlocProvider<ProductCubit>       + ScaffoldTemplate  + ProductGrid
ProductDetailPage  →  BlocProvider<ProductDetailCubit> + SliverTemplate    + ProductDetailHeader + ProductDetailInfo
CartPage           →  BlocProvider<CartCubit>          + ScaffoldTemplate  + CartItem list + CartSummary
ProfilePage        →  BlocProvider<ProfileBloc>        + ScrollableTemplate + ProfileHeader + ProfileMenuList
```

### What Pages must NOT do

- ❌ Define `Column`, `Row`, `Padding` for layout — that belongs in Template or Organism
- ❌ Contain UI-specific widget trees with many nested children
- ❌ Duplicate BLoC provision already handled by a parent route
