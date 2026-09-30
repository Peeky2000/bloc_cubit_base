part of 'sign_in_cubit.dart';

enum SignInRetryAction { signIn, sendVerificationCode }

sealed class SignInEffect {
  const SignInEffect();
}

final class SignInNavigateHomeEffect extends SignInEffect {
  const SignInNavigateHomeEffect();
}

final class SignInNavigateForgotPasswordEffect extends SignInEffect {
  const SignInNavigateForgotPasswordEffect();
}

final class SignInNavigatePhoneVerificationEffect extends SignInEffect {
  const SignInNavigatePhoneVerificationEffect({required this.phone});

  final String phone;
}

final class SignInShowErrorEffect extends SignInEffect {
  const SignInShowErrorEffect({required this.error, required this.retryAction});

  final Object error;
  final SignInRetryAction retryAction;
}
