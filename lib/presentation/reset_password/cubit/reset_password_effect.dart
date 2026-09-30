part of 'reset_password_cubit.dart';

enum ResetPasswordRetryAction { sendVerificationCode, resetPassword }

sealed class ResetPasswordEffect {
  const ResetPasswordEffect();
}

final class ResetPasswordChangePageEffect extends ResetPasswordEffect {
  const ResetPasswordChangePageEffect({required this.delta});

  final int delta;
}

final class ResetPasswordShowErrorEffect extends ResetPasswordEffect {
  const ResetPasswordShowErrorEffect({
    required this.error,
    required this.retryAction,
  });

  final Object error;
  final ResetPasswordRetryAction retryAction;
}

final class ResetPasswordInvalidOtpEffect extends ResetPasswordEffect {
  const ResetPasswordInvalidOtpEffect();
}

final class ResetPasswordSucceededEffect extends ResetPasswordEffect {
  const ResetPasswordSucceededEffect();
}
