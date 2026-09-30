part of 'sign_up_cubit.dart';

class SignUpState extends BaseAppState<Object> {
  final bool showPass;
  final int currentPage;
  final ScaleLevel? currentScaleLevel;
  final List<IndustryType>? industries;
  final PhoneInputError? phoneError;
  final EmailInputError? emailError;
  final PasswordInputError? passwordError;
  final RequiredInputError? shopNameError;
  final RequiredInputError? industryError;
  final RequiredInputError? scaleError;
  final UiEffect<SignUpEffect>? effect;

  const SignUpState({
    required super.loading,
    super.error,
    this.showPass = false,
    this.currentPage = 0,
    this.currentScaleLevel,
    this.industries,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.shopNameError,
    this.industryError,
    this.scaleError,
    this.effect,
  });

  factory SignUpState.initial() {
    return SignUpState(loading: LoadingStatus.initial, error: null);
  }

  SignUpState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? showPass,
    int? currentPage,
    ScaleLevel? currentScaleLevel,
    List<IndustryType>? industries,
    PhoneInputError? phoneError,
    EmailInputError? emailError,
    PasswordInputError? passwordError,
    RequiredInputError? shopNameError,
    RequiredInputError? industryError,
    RequiredInputError? scaleError,
    UiEffect<SignUpEffect>? effect,
    bool forceUpdateValidation = false,
  }) {
    return SignUpState(
      loading: loading ?? this.loading,
      error: error,
      showPass: showPass ?? this.showPass,
      currentPage: currentPage ?? this.currentPage,
      currentScaleLevel: currentScaleLevel ?? this.currentScaleLevel,
      industries: industries ?? this.industries,
      phoneError: forceUpdateValidation ? phoneError : this.phoneError,
      emailError: forceUpdateValidation ? emailError : this.emailError,
      passwordError: forceUpdateValidation ? passwordError : this.passwordError,
      shopNameError: forceUpdateValidation ? shopNameError : this.shopNameError,
      industryError: forceUpdateValidation ? industryError : this.industryError,
      scaleError: forceUpdateValidation ? scaleError : this.scaleError,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    showPass,
    currentPage,
    currentScaleLevel,
    industries,
    phoneError,
    emailError,
    passwordError,
    shopNameError,
    industryError,
    scaleError,
    effect,
  ];
}
