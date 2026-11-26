part of 'account_cubit.dart';

class AccountState extends BaseAppState<Object> {
  const AccountState({
    required super.loading,
    super.error,
    this.email,
    this.phone,
    this.role,
    this.effect,
  });

  final String? email;
  final String? phone;
  final String? role;
  final UiEffect<AccountEffect>? effect;

  factory AccountState.initial() =>
      const AccountState(loading: LoadingStatus.initial);

  AccountState copyWith({
    LoadingStatus? loading,
    Object? error,
    String? email,
    String? phone,
    String? role,
    UiEffect<AccountEffect>? effect,
  }) {
    return AccountState(
      loading: loading ?? this.loading,
      error: error,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, email, phone, role, effect];
}
