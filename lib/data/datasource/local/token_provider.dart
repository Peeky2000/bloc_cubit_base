import 'dart:convert';

import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:bloc_cubit_base/core/extension/string_extension.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tokenKey = 'token';

class TokenProvider {
  TokenProvider(this._secureStorage, this._preferences);

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;
  TokenResponseModel _token = TokenResponseModel();

  TokenResponseModel get token => _token;

  Future<TokenProvider> init() async {
    var encodedToken = await _secureStorage.read(key: _tokenKey);

    // One-time migration from the legacy plain preferences value.
    final legacyToken = _preferences.getString(_tokenKey);
    if (encodedToken.isNullOrEmpty && legacyToken.isNotNullOrEmpty) {
      encodedToken = legacyToken;
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
    }
    if (legacyToken != null) {
      await _preferences.remove(_tokenKey);
    }

    _token = encodedToken.isNotNullOrEmpty
        ? TokenResponseModel.fromJson(
            jsonDecode(encodedToken!) as Map<String, dynamic>,
          )
        : TokenResponseModel();
    return this;
  }

  Future<void> setToken(TokenResponseModel? token) async {
    _token = token ?? TokenResponseModel();
    if (token == null) {
      await _secureStorage.delete(key: _tokenKey);
      return;
    }
    await _secureStorage.write(key: _tokenKey, value: jsonEncode(token));
  }

  Future<void> clearToken() async {
    _token = TokenResponseModel();
    await _secureStorage.delete(key: _tokenKey);
  }
}
