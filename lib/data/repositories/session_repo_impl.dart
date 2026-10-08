import 'package:bloc_cubit_base/core/extension/string_extension.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/local/user_local_data_source.dart';
import 'package:bloc_cubit_base/data/model/response/profile/account_response_model.dart';
import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SessionRepo)
class SessionRepoImpl implements SessionRepo {
  SessionRepoImpl(this._tokens, this._accounts);

  final TokenProvider _tokens;
  final UserLocalDataSource _accounts;

  /// The account of the current session. Null means "read the persisted
  /// account", which is the state right after app start.
  AccountResponseModel? _account;

  @override
  bool get isSignedIn => _tokens.token.accessToken.isNotNullOrEmpty;

  @override
  Account get account => _account ?? _accounts.account;

  @override
  Future<void> start({
    required TokenWrapper? token,
    required Account? account,
    required bool persist,
  }) async {
    await _tokens.setToken(
      TokenResponseModel(
        accessToken: token?.access?.token,
        refreshToken: token?.refresh?.token,
      ),
      persist: persist,
    );
    await _storeAccount(account, persist: persist);
  }

  @override
  Future<void> updateAccount(Account account) =>
      _storeAccount(account, persist: _tokens.persists);

  @override
  Future<void> end() async {
    _account = null;
    await Future.wait([_tokens.clearToken(), _accounts.clearAccount()]);
  }

  Future<void> _storeAccount(Account? account, {required bool persist}) async {
    final model = account == null
        ? AccountResponseModel()
        : AccountResponseModel.fromAccount(account);
    _account = model;
    if (persist && account != null) {
      await _accounts.setAccount(model);
    } else {
      await _accounts.clearAccount();
    }
  }
}
