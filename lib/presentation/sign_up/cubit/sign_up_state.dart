part of 'sign_up_cubit.dart';

class SignUpState extends BaseAppState {
  final bool showPass;
  final int currentPage;
  final ChangePageViewStatus? changePageViewStatus;
  final ScaleLevel? currentScaleLevel;
  final List<IndustryType>? industries;
  final String? errorPhone;
  final String? errorEmail;
  final String? errorPassword;
  final String? errorShopName;
  final String? errIndustry;
  final String? errScale;

  const SignUpState({
    required super.loading,
    super.error,
    this.showPass = false,
    this.currentPage = 0,
    this.changePageViewStatus,
    this.currentScaleLevel,
    this.industries,
    this.errorPhone,
    this.errorEmail,
    this.errorPassword,
    this.errorShopName,
    this.errIndustry,
    this.errScale,
  });

  factory SignUpState.initial() {
    return SignUpState(loading: LoadingStatus.initial, error: null);
  }

  SignUpState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? showPass,
    int? currentPage,
    ChangePageViewStatus? changePageViewStatus,
    ScaleLevel? currentScaleLevel,
    List<IndustryType>? industries,
    String? errorPhone,
    String? errorEmail,
    String? errorPassword,
    String? errorShopName,
    String? errIndustry,
    String? errScale,
    bool forceUpdateError = false,
  }) {
    return SignUpState(
      loading: loading ?? this.loading,
      error: error,
      showPass: showPass ?? this.showPass,
      currentPage: currentPage ?? this.currentPage,
      changePageViewStatus: changePageViewStatus,
      currentScaleLevel: currentScaleLevel ?? this.currentScaleLevel,
      industries: industries ?? this.industries,
      errorPhone: forceUpdateError ? errorPhone : this.errorPhone,
      errorEmail: forceUpdateError ? errorEmail : this.errorEmail,
      errorPassword: forceUpdateError ? errorPassword : this.errorPassword,
      errorShopName: forceUpdateError ? errorShopName : this.errorShopName,
      errIndustry: forceUpdateError ? errIndustry : this.errIndustry,
      errScale: forceUpdateError ? errScale : this.errScale,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    showPass,
    currentPage,
    changePageViewStatus,
    currentScaleLevel,
    industries,
    errorPhone,
    errorEmail,
    errorPassword,
    errorShopName,
    errIndustry,
    errScale,
  ];
}
