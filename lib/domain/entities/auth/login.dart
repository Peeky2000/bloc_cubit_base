import 'package:delivery_go/domain/entities/auth/token_wrapper.dart';
import 'package:delivery_go/domain/entities/profile/account.dart';

abstract class Login {
  Account? get account;

  TokenWrapper? get token;
}
