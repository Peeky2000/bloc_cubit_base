part of 'splash_cubit.dart';

sealed class SplashEffect {
  const SplashEffect();
}

final class SplashNavigateSignInEffect extends SplashEffect {
  const SplashNavigateSignInEffect();
}

final class SplashNavigateHomeEffect extends SplashEffect {
  const SplashNavigateHomeEffect();
}

final class SplashNavigatePhoneVerificationEffect extends SplashEffect {
  const SplashNavigatePhoneVerificationEffect({required this.phone});

  final String phone;
}

final class SplashShowErrorEffect extends SplashEffect {
  const SplashShowErrorEffect({required this.error});

  final Object error;
}
