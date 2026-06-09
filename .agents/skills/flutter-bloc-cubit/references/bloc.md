# BLoC — Standard Pattern

## Folder structure

```
features/auth/presentation/
└── bloc/
    ├── auth_bloc.dart
    ├── auth_bloc.freezed.dart    ← generated
    ├── auth_event.dart
    └── auth_state.dart
```

---

## Event sealed class

```dart
// features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginPressed({
    required String email,
    required String password,
  }) = AuthLoginPressed;

  const factory AuthEvent.logoutPressed() = AuthLogoutPressed;
  const factory AuthEvent.checkAuthStatus() = AuthCheckStatus;
}
```

---

## BLoC

```dart
// features/auth/presentation/bloc/auth_bloc.dart
part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.freezed.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState.initial()) {
    on<AuthLoginPressed>(_onLogin);
    on<AuthLogoutPressed>(_onLogout);
    on<AuthCheckStatus>(_onCheckStatus);
  }

  final AuthRepository _repo;

  Future<void> _onLogin(
    AuthLoginPressed event,
    Emitter<AuthState> emit,
  ) async {
    // Format validation before hitting the network
    if (event.email.isEmpty || !event.email.contains('@')) {
      emit(const AuthState.error('Invalid email address'));
      return;
    }
    if (event.password.length < 6) {
      emit(const AuthState.error('Password must be at least 6 characters'));
      return;
    }

    emit(const AuthState.loading());
    try {
      final user = await _repo.login(event.email, event.password);
      emit(AuthState.authenticated(user));
    } on ServerException catch (e) {
      emit(AuthState.error(e.message ?? 'Login failed'));
    } on NetworkException {
      emit(const AuthState.error('No internet connection'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repo.logout();
      emit(const AuthState.unauthenticated());
    } on ServerException catch (e) {
      emit(AuthState.error(e.message ?? 'Logout failed'));
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    final isAuth = await _repo.isAuthenticated();
    if (!isAuth) {
      emit(const AuthState.unauthenticated());
      return;
    }
    final user = await _repo.getCurrentUser();
    emit(user != null
        ? AuthState.authenticated(user)
        : const AuthState.unauthenticated());
  }
}
```

---

## Providing in the widget tree

```dart
// Global auth BLoC — needed app-wide for the auth guard
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
    ),
  ],
  child: MaterialApp.router(routerConfig: getIt<AppRouter>().router),
)

// Feature BLoC — scoped to the route
GoRoute(
  path: '/checkout',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<CheckoutBloc>(),
    child: const CheckoutPage(),
  ),
)
```

---

## Naming conventions

| Element | Example |
|---|---|
| BLoC class | `AuthBloc` |
| Event sealed class | `AuthEvent` |
| Event factory | `AuthEvent.loginPressed(...)` |
| Handler method | `_onLogin`, `_onLogout` |
| BLoC file | `auth_bloc.dart` |
| Event file | `auth_event.dart` |
