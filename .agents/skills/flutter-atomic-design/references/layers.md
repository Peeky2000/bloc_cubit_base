# Layer Reference

## Decision table — which layer is my widget?

| Ask yourself | Answer → Layer |
|---|---|
| Is it a single visual primitive (text, icon, button, input)? | **Atom** |
| Does it combine 2–3 atoms into a small UX pattern? | **Molecule** |
| Does it represent a complete UI block (form, card, list section)? | **Organism** |
| Does it define where regions of a screen go (no real data)? | **Template** |
| Does it inject BLoC and map state to props? | **Page** |

---

## Atom

**Renders UI. Receives props. Zero logic.**

- No `BuildContext` reads (`context.read`, `context.watch`)
- No business conditions (`if (user.isAdmin)`)
- Maps `variant` / `size` enum → style from design tokens
- One job: present what it receives

```dart
class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final int? maxLines;

  const AppText(this.text, {required this.variant, this.color, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.of(variant).copyWith(color: color),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
```

---

## Molecule

**2–3 atoms. Stateless. No business data.**

- Composes atoms into a reusable micro-pattern
- May hold **pure UI state** (e.g. `PasswordField` toggles `obscureText` internally)
- Knows nothing about `User`, `Product`, `Order`, etc.
- Props are primitive types or simple value objects

```dart
// ✅ Molecule — props are primitives
class UserAvatarInfo extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String subtitle;
}

// ❌ Not a molecule — knows about a domain entity
class UserAvatarInfo extends StatelessWidget {
  final User user; // domain entity → belongs in Organism
}
```

---

## Organism

**Complete UI block. Receives domain data + callbacks. No BLoC calls.**

- Accepts typed entities (`Product`, `CartItem`, `UserProfile`) as props
- Exposes callbacks (`onTap`, `onAddToCart`, `onSubmit`) — fires them, never decides what happens
- Does NOT know which BLoC or use case exists

```dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        AppImage(url: product.imageUrl),
        AppText(product.name, variant: AppTextVariant.body),
        ProductPriceLine(price: product.price, salePrice: product.salePrice),
        AppButton(label: 'Add', onPressed: onAddToCart),
      ]),
    );
  }
}
```

---

## Template

**Screen layout scaffold. No data. No feature knowledge.**

- Defines regions: `appBar`, `body`, `bottomBar`, `floatingButton`
- Accepts `Widget` slots — not typed domain objects
- Never imports from `features/`

```dart
class ScaffoldTemplate extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;
  final Widget? floatingButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingButton,
    );
  }
}
```

---

## Page

**Thin connector. BLoC injection + state mapping. No layout.**

- Provides BLoC via `BlocProvider`
- Reads route params from `GoRouterState`
- Maps state → organism props via `BlocBuilder` / `BlocListener`
- Does NOT contain `Column`, `Padding`, `SizedBox` for layout — delegates entirely to Template + Organisms

```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductCubit>()..loadProducts(),
      child: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) => ScaffoldTemplate(
          appBar: AppTopBar(title: LocaleKeys.product_title.tr()),
          body: switch (state) {
            ProductLoading()                  => const SkeletonList(),
            ProductLoaded(:final products)    => ProductGrid(
                products: products,
                onProductTap: (p) => context.push('/product/${p.id}'),
                onAddToCart: (p) => context.read<ProductCubit>().addToCart(p),
              ),
            ProductError(:final message)      => ErrorState(
                message: message,
                onRetry: () => context.read<ProductCubit>().loadProducts(),
              ),
            _                                 => const SizedBox(),
          },
        ),
      ),
    );
  }
}
```
