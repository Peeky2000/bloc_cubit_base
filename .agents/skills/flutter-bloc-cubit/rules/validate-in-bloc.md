# Rule: Validate in BLoC/Cubit, Not in Repository or DataSource

**Why:** Format validation — empty fields, email patterns, password length —
is a UI-layer concern. It maps directly to what the user typed and what
error message they should see. Repository and DataSource are network/storage
layers; they trust their callers and have no business knowing what the user
typed in a form field. Putting validation there also means BLoC can't control
when or how the error state is emitted.

---

## ❌ Bad

```dart
// Validation buried in Repository — hidden from BLoC
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String email, String password) async {
    if (email.isEmpty) throw ArgumentError('Email is required'); // ❌
    if (!email.contains('@')) throw ArgumentError('Invalid email'); // ❌
    if (password.length < 6) throw ArgumentError('Password too short'); // ❌

    final model = await _remote.login(email, password);
    return model.toEntity();
  }
}

// BLoC catches a generic ArgumentError — can't map it to a specific UI message
Future<void> _onLogin(AuthLoginPressed event, Emitter<AuthState> emit) async {
  emit(const AuthState.loading());
  try {
    final user = await _repo.login(event.email, event.password);
    emit(AuthState.authenticated(user));
  } catch (e) {
    // ❌ Forced to use catch-all just to surface the validation message
    emit(AuthState.error(e.toString()));
  }
}

// Validation in DataSource — even worse
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<AuthTokenModel> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) { // ❌ DataSource validating user input
      throw Exception('Fields cannot be empty');
    }
    // ...
  }
}
```

---

## ✅ Good

```dart
// Validation in BLoC — before any network call, with specific error states
Future<void> _onLogin(
  AuthLoginPressed event,
  Emitter<AuthState> emit,
) async {
  // ✅ Validate first — emit specific error states, return early
  if (event.email.isEmpty) {
    emit(const AuthState.error('Email is required'));
    return;
  }
  if (!event.email.contains('@')) {
    emit(const AuthState.error('Enter a valid email address'));
    return;
  }
  if (event.password.length < 6) {
    emit(const AuthState.error('Password must be at least 6 characters'));
    return;
  }

  // ✅ Input is valid — now hit the network
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

// ✅ Repository is clean — just moves data
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String email, String password) async {
    final model = await _remote.login(email, password);
    return model.toEntity();
  }
}
```

---

## Logic placement table

| Logic type | Belongs in |
|---|---|
| Empty field check | BLoC/Cubit |
| Email / phone format | BLoC/Cubit |
| Password length / strength | BLoC/Cubit |
| Business rule (e.g. max items in cart) | BLoC/Cubit |
| Cache strategy (remote vs local) | Repository |
| Calling multiple repositories | BLoC/Cubit (`Future.wait`) |
| HTTP request / DB read-write | DataSource |
