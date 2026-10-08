import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';

/// The signed-in session: credentials and the cached account, which always
/// live and die together.
///
/// A session that is not persisted exists only in memory and is gone after
/// the app restarts. Ending a session, by sign-out or by expiry, always clears
/// both the credentials and the account.
abstract class SessionRepo {
  /// Whether a usable access token is available right now.
  bool get isSignedIn;

  /// The cached account, or an empty account when there is none.
  Account get account;

  /// Starts a session from a successful sign-in.
  ///
  /// With [persist] false the token and account stay in memory only and any
  /// previously persisted session is removed.
  Future<void> start({
    required TokenWrapper? token,
    required Account? account,
    required bool persist,
  });

  /// Replaces the cached account, keeping the current persistence mode.
  Future<void> updateAccount(Account account);

  /// Ends the session and clears credentials and account.
  Future<void> end();
}
