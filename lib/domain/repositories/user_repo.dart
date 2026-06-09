import 'package:mOrder/domain/entities/profile/account.dart';

abstract class UserRepo {
  Account get account;

  Future<void> setAccountToLocal(Account? account);
}
