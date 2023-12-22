import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final SharedPreferences _preferences;

  AuthLocalDataSource(this._preferences);
}
