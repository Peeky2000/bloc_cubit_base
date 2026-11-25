part of 'splash_cubit.dart';

class SplashState extends BaseAppState<Object> {
  const SplashState({
    required super.loading,
    super.error,
    this.isLogin,
    this.effect,
  });

  final bool? isLogin;
  final UiEffect<SplashEffect>? effect;

  factory SplashState.initial() {
    return const SplashState(loading: LoadingStatus.initial);
  }

  SplashState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? isLogin,
    UiEffect<SplashEffect>? effect,
  }) {
    return SplashState(
      loading: loading ?? this.loading,
      error: error,
      isLogin: isLogin ?? this.isLogin,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, isLogin, effect];
}
