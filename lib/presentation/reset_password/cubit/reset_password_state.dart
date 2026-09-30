part of 'reset_password_cubit.dart';

class ResetPasswordState extends BaseAppState<Object> {
  const ResetPasswordState({
    required super.loading,
    super.error,
    this.phoneError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.counter = 0,
    this.showNewPass = false,
    this.showConfirmPass = false,
    this.isVerifying = false,
    this.phone = '',
    this.effect,
  });

  final PhoneInputError? phoneError;
  final PasswordInputError? newPasswordError;
  final PasswordInputError? confirmPasswordError;
  final int counter;
  final bool showNewPass;
  final bool showConfirmPass;
  final bool isVerifying;
  final String phone;
  final UiEffect<ResetPasswordEffect>? effect;

  factory ResetPasswordState.initial() {
    return const ResetPasswordState(loading: LoadingStatus.initial);
  }

  ResetPasswordState copyWith({
    LoadingStatus? loading,
    Object? error,
    PhoneInputError? phoneError,
    PasswordInputError? newPasswordError,
    PasswordInputError? confirmPasswordError,
    int? counter,
    bool? showNewPass,
    bool? showConfirmPass,
    bool? isVerifying,
    String? phone,
    UiEffect<ResetPasswordEffect>? effect,
    bool forceUpdateValidation = false,
  }) {
    return ResetPasswordState(
      loading: loading ?? this.loading,
      error: error,
      phoneError: forceUpdateValidation ? phoneError : this.phoneError,
      newPasswordError: forceUpdateValidation
          ? newPasswordError
          : this.newPasswordError,
      confirmPasswordError: forceUpdateValidation
          ? confirmPasswordError
          : this.confirmPasswordError,
      counter: counter ?? this.counter,
      showNewPass: showNewPass ?? this.showNewPass,
      showConfirmPass: showConfirmPass ?? this.showConfirmPass,
      isVerifying: isVerifying ?? this.isVerifying,
      phone: phone ?? this.phone,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    phoneError,
    newPasswordError,
    confirmPasswordError,
    counter,
    showNewPass,
    showConfirmPass,
    isVerifying,
    phone,
    effect,
  ];
}
