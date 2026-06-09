# Rule: Templates define layout only — no real data, no feature imports

## Why

A Template is the reusable skeleton of a screen type. The moment it imports a feature, a BLoC, or a domain entity, it can only be used in that one context. All its layout value is lost.

## ❌ Bad

```dart
// Template knows about the auth feature
class AuthTemplate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthBloc>().state.isLoggedIn; // ❌

    return Scaffold(
      body: Column(children: [
        if (isLoggedIn) const UserAvatar(), // ❌ template making business decisions
        LoginForm(onSubmit: (_,__) {}),     // ❌ hardcoded organism — not a slot
      ]),
    );
  }
}
```

## ✅ Good

```dart
// Template only defines regions — completely feature-agnostic
class AuthTemplate extends StatelessWidget {
  final Widget body;       // ✅ slot — Page decides what goes here
  final Widget? footer;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          if (showLogo) const AppLogo(),
          Expanded(child: body),     // ✅ body slot filled by Page
          if (footer != null) footer!,
        ]),
      ),
    );
  }
}

// Page fills the slots
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthTemplate(
      showLogo: true,
      body: LoginForm(                // ✅ Page decides which organism fills the slot
        onSubmit: (email, pw) => context.read<AuthBloc>().add(LoginSubmitted(email, pw)),
        isLoading: state.isLoading,
      ),
    );
  }
}
```

## Checklist for a valid Template

- [ ] All children are typed as `Widget`, `PreferredSizeWidget`, or `List<Widget>`
- [ ] No imports from `lib/features/`
- [ ] No `BlocProvider`, `BlocBuilder`, `context.read`, `context.watch`
- [ ] No domain entities (`User`, `Product`, `Order`, etc.) in the constructor
