# UI Error Patterns

Three ways to surface errors in the UI. Each has a specific use case.

## Decision table

| Situation | Pattern | Widget |
|---|---|---|
| Full page failed to load | **Error state** replaces body | `ErrorState` organism |
| Background action failed (add to cart, delete, submit) | **Snackbar** — non-blocking | `ScaffoldMessenger.showSnackBar` |
| Destructive or irreversible action confirmation failure | **Dialog** — blocks until dismissed | `ConfirmDialog` organism |
| Field-level form validation | **Inline** under field | `AppTextField(errorText:)` |
| Form-level submit error (wrong password, email taken) | **Inline banner** above submit button | `FormErrorMessage` molecule |

---

## 1. Error State — full page replacement

Use `BlocBuilder` when the error prevents the screen from showing anything useful.

```dart
BlocBuilder<ProductCubit, ProductState>(
  builder: (context, state) => switch (state) {
    ProductLoading() => const SkeletonList(),
    ProductLoaded(:final products) => ProductGrid(products: products, ...),
    ProductError(:final message) => ErrorState(   // ← full page replaced
        message: message,
        onRetry: () => context.read<ProductCubit>().loadProducts(),
      ),
    _ => const SizedBox(),
  },
)
```

---

## 2. Snackbar — transient action errors

Use `BlocListener` for errors that don't replace the current screen content.
The user should still see what was there before the action failed.

```dart
BlocListener<CartCubit, CartState>(
  listenWhen: (prev, curr) =>
      curr is CartLoaded && curr.actionError != null &&
      curr.actionError != (prev is CartLoaded ? prev.actionError : null),
  listener: (context, state) {
    if (state is CartLoaded && state.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.actionError!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  },
  child: BlocBuilder<CartCubit, CartState>(
    builder: (context, state) => ..., // renders cart list normally
  ),
)
```

---

## 3. Dialog — blocking errors

Use when the user must acknowledge the error before proceeding (payment failure, session expired).

```dart
BlocListener<CheckoutCubit, CheckoutState>(
  listener: (context, state) {
    if (state is CheckoutPaymentFailed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ConfirmDialog(
          title: 'Payment Failed',
          message: state.message,
          confirmLabel: 'Try Again',
          onConfirm: () {
            context.pop();
            context.read<CheckoutCubit>().retryPayment();
          },
          onCancel: () => context.pop(),
        ),
      );
    }
  },
  child: ...,
)
```

---

## 4. Inline form errors

Form-level errors go through state, not directly through `FormState`:

```dart
// State carries the form error
@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.idle() = LoginIdle;
  const factory LoginState.loading() = LoginLoading;
  const factory LoginState.success(User user) = LoginSuccess;
  const factory LoginState.error(String message) = LoginError; // ← form-level error
}

// Organism receives errorMessage prop
LoginForm(
  isLoading: state is LoginLoading,
  errorMessage: state is LoginError ? state.message : null,
  onSubmit: (email, pw) => context.read<AuthBloc>().add(LoginSubmitted(email, pw)),
)

// Inside LoginForm organism
if (errorMessage != null)
  FormErrorMessage(message: errorMessage!), // ← shows above submit button
```

---

## Combining Listener + Builder

Most screens need both. The correct structure:

```dart
BlocListener<XCubit, XState>(
  listener: (context, state) {
    // side effects: snackbar, navigation, dialog
  },
  child: BlocBuilder<XCubit, XState>(
    builder: (context, state) {
      // UI rendering
    },
  ),
)

// Or combined:
BlocConsumer<XCubit, XState>(
  listener: (context, state) { ... },
  builder: (context, state) { ... },
)
```
