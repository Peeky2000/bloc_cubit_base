import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeKey = 'localeKey';

@lazySingleton
class AppLocalDataSource {
  final SharedPreferences _preferences;

  AppLocalDataSource(this._preferences);

  AppLanguage get currentLanguage => AppLanguage.values.firstWhere(
    (language) => language.name == _preferences.getString(_localeKey),
    orElse: () => AppLanguage.vi,
  );

  Future<void> saveLanguage({required AppLanguage language}) async {
    await _preferences.setString(_localeKey, language.name);
  }
}
