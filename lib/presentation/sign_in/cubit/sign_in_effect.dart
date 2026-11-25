part of 'sign_in_cubit.dart';

sealed class SignInEffect {
  const SignInEffect();
}

final class SignInNavigateHomeEffect extends SignInEffect {
  const SignInNavigateHomeEffect();
}

final class SignInShowErrorEffect extends SignInEffect {
  const SignInShowErrorEffect({required this.error});

  final Object error;
}
