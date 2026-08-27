part of 'splash_cubit.dart';

class SplashState extends Equatable {
  final bool? isLogin;
  final bool isPhoneVerified;
  final String? phone;

  const SplashState({this.isLogin, this.isPhoneVerified = false, this.phone});

  factory SplashState.initial() {
    return SplashState();
  }

  SplashState copyWith({bool? isLogin, bool? isPhoneVerified, String? phone}) {
    return SplashState(
      isLogin: isLogin ?? this.isLogin,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [isLogin, isPhoneVerified, phone];
}
