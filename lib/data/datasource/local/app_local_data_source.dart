import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_go/core/common/enum.dart';

const String _localeKey = 'localeKey';

class AppLocalDataSource {
  final SharedPreferences _preferences;

  AppLocalDataSource(this._preferences);

  Locale get currentLocale {
    String savedLang =
        _preferences.getString(_localeKey) ?? AppLanguage.vi.name;
    if (savedLang == AppLanguage.vi.name) {
      return const Locale('vi', 'VN');
    } else {
      return const Locale('en', 'US');
    }
  }

  Future<void> saveLanguage({required AppLanguage language}) async {
    await _preferences.setString(_localeKey, language.name);
  }
}
