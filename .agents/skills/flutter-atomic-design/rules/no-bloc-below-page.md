# Rule: Never call BLoC inside Atom / Molecule / Organism

## Why

- Atoms, Molecules, and Organisms are shared across features — they must have zero knowledge of any specific BLoC
- Coupling a widget to a BLoC makes it impossible to reuse in another feature or preview in isolation
- It breaks the data-flow contract: data flows **down** via constructors, events flow **up** via callbacks

## ❌ Bad

```dart
// Organism reading BLoC directly
class ProductCard extends StatelessWidget {
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>(); // ❌ organism knows about CartCubit

    return AppButton(
      label: 'Add to cart',
      onPressed: () => cubit.addToCart(product), // ❌ organism decides behaviour
    );
  }
}

// Molecule watching BLoC
class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = context.watch<SearchCubit>().state.query; // ❌
    return AppSearchField(hint: query, onChanged: (_) {});
  }
}
```

## ✅ Good

```dart
// Organism receives callback — Page decides what to do with it
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart; // ✅ callback injected from outside

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Add to cart',
      onPressed: onAddToCart, // ✅ fires callback, decides nothing
    );
  }
}

// Page wires the callback to the BLoC
ProductCard(
  product: product,
  onAddToCart: () => context.read<CartCubit>().addToCart(product), // ✅ only Page knows CartCubit
)
```

## Layers allowed to use BLoC

| Layer | May use BLoC? |
|---|---|
| Atom | ❌ Never |
| Molecule | ❌ Never |
| Organism | ❌ Never |
| Template | ❌ Never |
| Page | ✅ Yes — this is its sole responsibility |
