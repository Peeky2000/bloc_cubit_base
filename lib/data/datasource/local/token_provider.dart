import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mOrder/data/model/response/token_response_model.dart';
import 'package:mOrder/core/extension/string_extension.dart';

const String _tokenKey = 'token';

class TokenProvider {
  final SharedPreferences _preferences;

  TokenProvider(this._preferences);

  TokenResponseModel get token {
    String? data = _preferences.getString(_tokenKey);
    return data.isNotNullOrEmpty
        ? TokenResponseModel.fromJson(jsonDecode(data!))
        : TokenResponseModel();
  }

  Future<void> setToken(TokenResponseModel? token) async {
    await _preferences.setString(
        _tokenKey, token != null ? jsonEncode(token) : '');
  }

  Future<void> clearToken() async {
    await _preferences.remove(_tokenKey);
  }
}
