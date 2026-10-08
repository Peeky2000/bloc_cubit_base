import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';

abstract class AuthRepo {
  Future<Login?> appLogin({required String phone, required String password});

  Future<SignUp?> userSignUp({required SignUpParams request});

  Future<UpdateAccount?> verifyPhone({required String idToken});

  Future<void> resetPasswordPhone({
    required String idToken,
    required String newPassword,
  });
}
