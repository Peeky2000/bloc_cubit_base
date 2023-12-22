import 'package:delivery_go/domain/entities/profile/account.dart';

abstract class UserRepo {
  Account get account;

  Future<void> setAccountToLocal(Account? account);
}
