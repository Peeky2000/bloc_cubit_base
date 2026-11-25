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
