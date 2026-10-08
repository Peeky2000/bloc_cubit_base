import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';

class AuthUseCase {
  final AuthRepo _authRepo;
  final SessionRepo _session;

  final PhoneVerificationRepo _phoneVerificationRepo;

  AuthUseCase(this._authRepo, this._session, this._phoneVerificationRepo);

  /// Converts a local Vietnamese number (`0912…`) to E.164 (`+84912…`).
  /// Other input, such as an email or an E.164 number, is returned unchanged.
  static String normalizePhone(String phone) =>
      phone.startsWith('0') ? '+84${phone.substring(1)}' : phone;

  bool isAppLogin() => _session.isSignedIn;

  /// Signs in and always starts a session, so the next requests are
  /// authenticated. [isRememberLogin] only decides whether the session
  /// survives an app restart.
  Future<Login?> login({
    required String phone,
    required String password,
    bool isRememberLogin = false,
  }) async {
    final result = await _authRepo.appLogin(
      phone: normalizePhone(phone),
      password: password,
    );
    if (result != null) {
      await _session.start(
        token: result.token,
        account: result.account,
        persist: isRememberLogin,
      );
    }
    return result;
  }

  Account get accountLocal => _session.account;

  Future<SignUp?> userSignUp({required SignUpParams request}) {
    return _authRepo.userSignUp(request: request);
  }

  /// Sends a verification code to [phone], normalized to E.164.
  ///
  /// Completes once with the outcome and throws [PhoneVerificationFailure]
  /// when the platform rejects the request.
  Future<PhoneVerificationOutcome> sendCodeVerify({required String phone}) =>
      _phoneVerificationRepo.sendCode(phoneNumber: normalizePhone(phone));

  Future<String?> verifyOTP({required String otp}) =>
      _phoneVerificationRepo.verifyOtp(otp: otp);

  Future<void> verifyPhone({required String idToken}) async {
    final UpdateAccount? infoUpdate = await _authRepo.verifyPhone(
      idToken: idToken,
    );
    final account = infoUpdate?.account;
    if (account != null) {
      await _session.updateAccount(account);
    }
  }

  Future<void> resetPasswordPhone({
    required String idToken,
    required String newPassword,
  }) {
    return _authRepo.resetPasswordPhone(
      idToken: idToken,
      newPassword: newPassword,
    );
  }

  /// Ends the session and clears credentials and the cached account.
  Future<void> logout() => _session.end();
}
