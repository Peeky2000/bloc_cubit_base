# Rule: Pages own BLoC injection and state mapping — no layout logic

## Why

A Page that contains layout (`Column`, `Padding`, `Row`, `SizedBox`) is doing two jobs: connecting state AND building UI. Layout logic in a Page can't be reused, isn't backed by a template, and makes the Page harder to read.

## ❌ Bad

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return Scaffold(                       // ❌ Page building layout from scratch
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    AppAvatar(                   // ❌ Page composing atoms directly
                      url: state.user?.avatarUrl,
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      state.user?.name ?? '',
                      variant: AppTextVariant.title,
                    ),
                    // ... 40 more lines of layout
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## ✅ Good

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(                         // ✅ inject BLoC
      create: (_) => getIt<ProfileBloc>()..loadProfile(),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ScrollableTemplate(             // ✅ delegate layout to Template
            appBar: AppTopBar(title: LocaleKeys.profile_title.tr()),
            body: switch (state) {
              ProfileLoading() => const SkeletonList(itemCount: 3),
              ProfileLoaded(:final user) => ProfileBody( // ✅ delegate content to Organism
                  user: user,
                  onEditTap: () => context.push('/profile/edit'),
                  onLogout: () => context.read<ProfileBloc>().add(LogoutRequested()),
                ),
              ProfileError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context.read<ProfileBloc>().add(ProfileLoadRequested()),
                ),
              _ => const SizedBox(),
            },
          );
        },
      ),
    );
  }
}
```

## Page responsibilities — exactly these, nothing more

| Responsibility | Example |
|---|---|
| Provide BLoC | `BlocProvider(create: (_) => getIt<XCubit>())` |
| Trigger initial load | `..loadData()` in `create` |
| Read route params | `GoRouterState.pathParameters['id']` |
| Map state → organism props | `BlocBuilder` with `switch (state)` |
| Handle side effects | `BlocListener` for navigation, toasts |
| Wire callbacks to BLoC | `onTap: () => context.read<XCubit>().doX()` |
