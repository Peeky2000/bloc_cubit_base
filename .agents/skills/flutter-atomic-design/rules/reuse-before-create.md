# Rule: Check the catalog before creating a new widget

## Why

Duplicate widgets with slightly different styles are the #1 source of design inconsistency. Creating a custom button / text / avatar when the atom/molecule already exists means two widgets to maintain, two different spacings, two different loading behaviours.

## ❌ Bad

```dart
// Creating a custom button because "this one is slightly different"
class SubmitButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        color: loading ? Colors.grey : AppColors.primary,
        child: loading
            ? const CircularProgressIndicator()
            : const Text('Submit', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
// → AppButton with isLoading + variant already handles this exactly
```

## ✅ Good

```dart
// Reuse the atom — just pass the right props
AppButton(
  label: LocaleKeys.common_confirm.tr(),
  onPressed: onSubmit,
  isLoading: state.isLoading,
  variant: AppButtonVariant.primary,
)
```

## Decision flow before creating a new widget

```
Need a widget?
  └─ Is it a visual primitive (text/icon/button/input/image)?
       └─ Check catalog-atoms.md → exists? Use it. No? Create atom.
  └─ Is it 2–3 atoms combined into a UX pattern?
       └─ Check catalog-molecules.md → exists? Use it. No? Create molecule.
  └─ Is it a full UI block with domain data?
       └─ Check catalog-organisms.md → exists? Use it. No? Create organism.
```

## When it IS okay to create something new

- The existing atom needs a **genuinely new variant** — add the variant to the atom, don't duplicate the atom
- The use case requires **behaviour not expressible** via existing props — extend the existing widget first
- The widget is **feature-specific** and has zero reuse potential — put it in the feature folder, not in shared
