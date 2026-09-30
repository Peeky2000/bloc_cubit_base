part of 'sign_up_cubit.dart';

enum SignUpRetryAction { signUp, sendVerificationCode }

sealed class SignUpEffect {
  const SignUpEffect();
}

final class SignUpChangePageEffect extends SignUpEffect {
  const SignUpChangePageEffect({required this.delta});

  final int delta;
}

final class SignUpNavigatePhoneVerificationEffect extends SignUpEffect {
  const SignUpNavigatePhoneVerificationEffect({required this.phone});

  final String phone;
}

final class SignUpShowErrorEffect extends SignUpEffect {
  const SignUpShowErrorEffect({required this.error, required this.retryAction});

  final Object error;
  final SignUpRetryAction retryAction;
}
