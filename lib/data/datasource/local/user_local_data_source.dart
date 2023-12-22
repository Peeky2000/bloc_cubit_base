import 'dart:convert';

import 'package:delivery_go/data/model/response/profile/account_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sli_common/extension/extensions.dart';

String _accountKey = 'account_key';

abstract class UserLocalDataSource {
  AccountResponseModel get account;

  Future<void> setAccount(AccountResponseModel? account);

  Future<void> clearAccount();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences _preferences;

  UserLocalDataSourceImpl(this._preferences);

  @override
  AccountResponseModel get account {
    String? data = _preferences.getString(_accountKey);
    return data.isNotNullOrEmpty
        ? AccountResponseModel.fromJson(jsonDecode(data!))
        : AccountResponseModel();
  }

  @override
  Future<void> setAccount(AccountResponseModel? account) async {
    await _preferences.setString(
        _accountKey, account != null ? jsonEncode(account) : '');
  }

  @override
  Future<void> clearAccount() async {
    await _preferences.remove(_accountKey);
  }
}
