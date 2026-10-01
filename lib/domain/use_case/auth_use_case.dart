import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/user_repo.dart';

class AuthUseCase {
  final AuthRepo _authRepo;
  final UserRepo _userRepo;

  final PhoneVerificationRepo _phoneVerificationRepo;

  AuthUseCase(this._authRepo, this._userRepo, this._phoneVerificationRepo);

  bool isAppLogin() {
    return _authRepo.isAppLogin();
  }

  Future<Login?> login({
    required String phone,
    required String password,
    bool isRememberLogin = false,
  }) async {
    Login? result = await _authRepo.appLogin(phone: phone, password: password);
    if (isRememberLogin) {
      await _authRepo.setTokenToLocal(tokenWrapper: result?.token);
      await _userRepo.setAccountToLocal(result?.account);
    }
    return result;
  }

  Account get accountLocal => _userRepo.account;

  Future<SignUp?> userSignUp({required SignUpParams request}) {
    return _authRepo.userSignUp(request: request);
  }

  Future<void> sendCodeVerify({
    required String phone,
    void Function(bool)? verificationCompleted,
    void Function()? onComplete,
    void Function(PhoneVerificationFailure)? onError,
  }) async {
    await _phoneVerificationRepo.sendCode(
      phoneNumber: phone.startsWith('0') ? '+84${phone.substring(1)}' : phone,
      onVerificationCompleted: verificationCompleted,
      onCodeSent: onComplete,
      onError: onError,
    );
  }

  Future<String?> verifyOTP({required String otp}) =>
      _phoneVerificationRepo.verifyOtp(otp: otp);

  Future<void> verifyPhone({required String idToken}) async {
    UpdateAccount? infoUpdate = await _authRepo.verifyPhone(idToken: idToken);
    if (infoUpdate?.account != null) {
      await _userRepo.setAccountToLocal(infoUpdate?.account);
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

  Future<void> logout() async {}
}
