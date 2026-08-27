import 'package:bloc_cubit_base/data/datasource/local/user_local_data_source.dart';
import 'package:bloc_cubit_base/data/model/response/profile/account_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/repositories/user_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UserRepo)
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
