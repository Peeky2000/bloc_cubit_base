part of 'splash_cubit.dart';

class SplashState extends BaseAppState<Object> {
  const SplashState({
    required super.loading,
    super.error,
    this.isLogin,
    this.isPhoneVerified = false,
    this.phone,
    this.effect,
  });

  final bool? isLogin;
  final bool isPhoneVerified;
  final String? phone;
  final UiEffect<SplashEffect>? effect;

  factory SplashState.initial() {
    return const SplashState(loading: LoadingStatus.initial);
  }

  SplashState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? isLogin,
    bool? isPhoneVerified,
    String? phone,
    UiEffect<SplashEffect>? effect,
  }) {
    return SplashState(
      loading: loading ?? this.loading,
      error: error,
      isLogin: isLogin ?? this.isLogin,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      phone: phone ?? this.phone,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    isLogin,
    isPhoneVerified,
    phone,
    effect,
  ];
}
