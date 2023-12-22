import 'package:delivery_go/data/model/request/sign_up_request_model.dart';
import 'package:delivery_go/domain/entities/auth/login.dart';
import 'package:delivery_go/domain/entities/auth/sign_up.dart';
import 'package:delivery_go/domain/entities/auth/token_wrapper.dart';
import 'package:delivery_go/domain/entities/profile/update_account.dart';

abstract class AuthRepo {
  bool isAppLogin();

  Future<Login?> appLogin({required String phone, required String password});

  Future<SignUp?> userSignUp({required SignUpRequestModel request});

  Future<void> setTokenToLocal({TokenWrapper? tokenWrapper});

  Future<UpdateAccount?> verifyPhone({required String idToken});

  Future<void> resetPasswordPhone(
      {required String idToken, required String newPassword});
}
