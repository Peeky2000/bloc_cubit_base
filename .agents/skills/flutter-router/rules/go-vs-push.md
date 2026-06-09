# Rule: Use context.go() for Tabs, context.push() for Detail Screens

**Why:** `go()` and `push()` have fundamentally different effects on the navigation stack.
`go()` replaces the entire stack with the new location — the back button disappears because
there's nothing to go back to. `push()` adds a new screen on top of the current stack —
the back button is present and returns to the previous screen. Using the wrong method either
traps users (can't go back from a detail screen) or confuses them (back button from a tab
returns to the previous tab rather than exiting).

---

## ❌ Bad

```dart
// push() for tab navigation — back button returns to the previous tab
// After several taps, pressing back cycles through tab history instead of exiting
void _onTap(BuildContext context, int index) {
  switch (index) {
    case 0: context.push('/home');     // ❌ stacks /home on top of current screen
    case 1: context.push('/products'); // ❌
    case 2: context.push('/cart');     // ❌
    case 3: context.push('/profile');  // ❌
  }
}
// User taps Home → Products → Cart → presses back
// Result: Cart → Products → Home (unexpected — tabs should not have history)

// go() for a detail screen — back button disappears
void onProductTap(String id) {
  context.go('/products/$id'); // ❌ replaces stack — user can't return to the list
}
```

---

## ✅ Good

```dart
// go() for tabs — replaces the stack, no back history between tabs
void _onTap(BuildContext context, int index) {
  switch (index) {
    case 0: context.go('/home');
    case 1: context.go('/products');
    case 2: context.go('/cart');
    case 3: context.go('/profile');
  }
}
// User taps Home → Products → Cart → presses back
// Result: exits the app (or goes to the OS home) — correct for tab navigation

// push() for detail screens — stacks on top, back button returns to list
void onProductTap(String id) {
  context.push('/products/$id'); // ✅ user can press back to return to /products
}

// push() for flows that sit on top of the current screen
void onCheckout() {
  context.push('/checkout'); // ✅ back returns to cart
}

// replace() for screens that should not be back-navigated to
void onLoginSuccess() {
  context.replace('/home'); // ✅ login screen removed from stack — back won't return to it
}
```

---

## Method reference

| Scenario | Method | Effect on stack |
|---|---|---|
| Tab bar navigation | `context.go()` | Clears stack, no back button |
| Detail / sub-screen | `context.push()` | Adds to stack, back button present |
| Post-login redirect | `context.replace()` | Replaces current screen, no back |
| Auth guard redirect | router `redirect` function | Transparent to the user |
| Go back | `context.pop()` | Removes top screen |
| Go back with result | `context.pop(result)` | Removes top screen, returns value |
