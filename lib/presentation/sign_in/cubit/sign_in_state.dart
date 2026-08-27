part of 'sign_in_cubit.dart';

class SignInState extends BaseAppState {
  final bool isRememberLogin;
  final bool showPass;
  final String? errorUsername;
  final String? errorPassword;

  const SignInState({
    required super.loading,
    super.error,
    required this.isRememberLogin,
    this.errorUsername,
    this.errorPassword,
    this.showPass = false,
  });

  factory SignInState.initial() {
    return SignInState(
      loading: LoadingStatus.initial,
      error: null,
      isRememberLogin: true,
    );
  }

  SignInState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? isRememberLogin,
    bool? showPass,
    String? errorUsername,
    String? errorPassword,
    bool forceUpdateError = false,
  }) {
    return SignInState(
      loading: loading ?? this.loading,
      error: error,
      showPass: showPass ?? this.showPass,
      isRememberLogin: isRememberLogin ?? this.isRememberLogin,
      errorUsername: forceUpdateError ? errorUsername : this.errorUsername,
      errorPassword: forceUpdateError ? errorPassword : this.errorPassword,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    isRememberLogin,
    showPass,
    errorUsername,
    errorPassword,
  ];
}
