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
  Future<void> _storageOperation = Future<void>.value();
  int _revision = 0;

  TokenResponseModel get token => _token;
  int get revision => _revision;

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
    _revision++;
    return this;
  }

  Future<void> setToken(TokenResponseModel? token) async {
    _revision++;
    _token = token ?? TokenResponseModel();
    await _enqueueStorageOperation(() async {
      if (token == null) {
        await _secureStorage.delete(key: _tokenKey);
        return;
      }
      await _secureStorage.write(key: _tokenKey, value: jsonEncode(token));
    });
  }

  Future<bool> setTokenIfRevision(
    TokenResponseModel token, {
    required int expectedRevision,
  }) async {
    if (_revision != expectedRevision) {
      return false;
    }

    _revision++;
    _token = token;
    await _enqueueStorageOperation(
      () => _secureStorage.write(key: _tokenKey, value: jsonEncode(token)),
    );
    return true;
  }

  Future<void> clearToken() async {
    _revision++;
    _token = TokenResponseModel();
    await _enqueueStorageOperation(() => _secureStorage.delete(key: _tokenKey));
  }

  Future<void> _enqueueStorageOperation(Future<void> Function() operation) {
    final queued = _storageOperation.then((_) => operation());
    _storageOperation = queued.catchError((Object _) {});
    return queued;
  }
}
