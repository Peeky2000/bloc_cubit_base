import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/user_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthUseCase {
  final AuthRepo _authRepo;
  final UserRepo _userRepo;

  final FirebaseAuth _auth;
  String _verificationId = '';

  AuthUseCase(this._authRepo, this._userRepo, this._auth);

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
    Function(bool)? verificationCompleted,
    Function()? onComplete,
    Function(FirebaseAuthException)? onError,
  }) async {
    String phoneNumber = '';
    if (phone[0] == '0') {
      phoneNumber = '+84${phone.substring(1)}';
    } else {
      phoneNumber = phone;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        if (verificationCompleted != null) {
          verificationCompleted(userCredential.user != null);
        }
      },
      verificationFailed: (e) {
        if (onError != null) {
          onError(e);
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        if (onComplete != null) {
          onComplete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<String?> verifyOTP({required String otp}) async {
    UserCredential credential = await _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      ),
    );
    return credential.user?.getIdToken();
  }

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
