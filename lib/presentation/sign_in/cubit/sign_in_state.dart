part of 'sign_in_cubit.dart';

class SignInState extends BaseAppState with EquatableMixin {
  bool isRememberLogin;
  bool showPass;
  String? errorUsername;
  String? errorPassword;

  SignInState({
    required LoadingStatus loading,
    dynamic error,
    required this.isRememberLogin,
    this.errorUsername,
    this.errorPassword,
    this.showPass = false,
  }) : super(loading: loading, error: error);

  factory SignInState.initial() {
    return SignInState(
      loading: LoadingStatus.initial,
      error: null,
      isRememberLogin: true,
    );
  }

  SignInState copyWith({
    LoadingStatus? loading,
    dynamic error,
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
