import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';

abstract class AuthRepo {
  bool isAppLogin();

  Future<Login?> appLogin({required String phone, required String password});

  Future<SignUp?> userSignUp({required SignUpParams request});

  Future<void> setTokenToLocal({TokenWrapper? tokenWrapper});

  Future<UpdateAccount?> verifyPhone({required String idToken});

  Future<void> resetPasswordPhone({
    required String idToken,
    required String newPassword,
  });
}
