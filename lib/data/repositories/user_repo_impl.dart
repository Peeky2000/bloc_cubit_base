import 'package:delivery_go/data/datasource/local/user_local_data_source.dart';
import 'package:delivery_go/data/model/response/profile/account_response_model.dart';
import 'package:delivery_go/domain/entities/profile/account.dart';
import 'package:delivery_go/domain/repositories/user_repo.dart';

class UserRepoImpl implements UserRepo {
  final UserLocalDataSource _userLocalDataSource;

  UserRepoImpl(this._userLocalDataSource);

  @override
  Account get account => _userLocalDataSource.account;

  @override
  Future<void> setAccountToLocal(Account? account) async {
    if (account is AccountResponseModel) {
      await _userLocalDataSource.setAccount(account);
    }
  }
}
