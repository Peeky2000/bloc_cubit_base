part of 'account_cubit.dart';

/// One-shot UI actions. The screen handles them in a BlocListener.
sealed class AccountEffect {
  const AccountEffect();
}

/// Ask the user to confirm signing out.
final class AccountConfirmLogoutEffect extends AccountEffect {
  const AccountConfirmLogoutEffect();
}

/// The session ended; go back to sign-in.
final class AccountNavigateSignInEffect extends AccountEffect {
  const AccountNavigateSignInEffect();
}

final class AccountShowErrorEffect extends AccountEffect {
  const AccountShowErrorEffect({required this.error});

  final Object error;
}
