import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';

abstract class Login {
  Account? get account;

  TokenWrapper? get token;
}
