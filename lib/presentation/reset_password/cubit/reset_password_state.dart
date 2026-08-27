part of 'reset_password_cubit.dart';

class ResetPasswordState extends BaseAppState {
  final ChangePageViewStatus? changePageStatus;
  final String? errorPhone;
  final String? errorNewPass;
  final String? errorConfirmPass;
  final int counter;
  final bool showNewPass;
  final bool showConfirmPass;
  final bool isVerifying;
  final String phone;

  const ResetPasswordState({
    required super.loading,
    super.error,
    this.changePageStatus,
    this.errorPhone,
    this.errorNewPass,
    this.errorConfirmPass,
    this.counter = 0,
    this.showNewPass = false,
    this.showConfirmPass = false,
    this.isVerifying = false,
    this.phone = '',
  });

  factory ResetPasswordState.initial() {
    return ResetPasswordState(loading: LoadingStatus.initial, error: null);
  }

  ResetPasswordState copyWith({
    LoadingStatus? loading,
    Object? error,
    ChangePageViewStatus? changePageStatus,
    String? errorPhone,
    String? errorNewPass,
    String? errorConfirmPass,
    int? counter,
    bool? showNewPass,
    bool? showConfirmPass,
    bool? isVerifying,
    String? phone,
  }) {
    return ResetPasswordState(
      loading: loading ?? this.loading,
      error: error,
      changePageStatus: changePageStatus,
      errorPhone: errorPhone,
      errorNewPass: errorNewPass,
      errorConfirmPass: errorConfirmPass,
      counter: counter ?? this.counter,
      showNewPass: showNewPass ?? this.showNewPass,
      showConfirmPass: showConfirmPass ?? this.showConfirmPass,
      isVerifying: isVerifying ?? this.isVerifying,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    changePageStatus,
    errorPhone,
    errorNewPass,
    errorConfirmPass,
    counter,
    showNewPass,
    showConfirmPass,
    isVerifying,
    phone,
  ];
}
