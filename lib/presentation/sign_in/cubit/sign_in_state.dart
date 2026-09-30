part of 'sign_in_cubit.dart';

class SignInState extends BaseAppState<Object> {
  final bool isRememberLogin;
  final bool showPass;
  final EmailOrPhoneInputError? usernameError;
  final PasswordInputError? passwordError;
  final UiEffect<SignInEffect>? effect;

  const SignInState({
    required super.loading,
    super.error,
    required this.isRememberLogin,
    this.usernameError,
    this.passwordError,
    this.effect,
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
    EmailOrPhoneInputError? usernameError,
    PasswordInputError? passwordError,
    UiEffect<SignInEffect>? effect,
    bool forceUpdateValidation = false,
  }) {
    return SignInState(
      loading: loading ?? this.loading,
      error: error,
      showPass: showPass ?? this.showPass,
      isRememberLogin: isRememberLogin ?? this.isRememberLogin,
      usernameError: forceUpdateValidation ? usernameError : this.usernameError,
      passwordError: forceUpdateValidation ? passwordError : this.passwordError,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    isRememberLogin,
    showPass,
    usernameError,
    passwordError,
    effect,
  ];
}
