# Local API

## Storage decision matrix

| Data type | Storage | Why |
|---|---|---|
| Access / refresh token | `FlutterSecureStorage` | OS-encrypted (Keychain / Keystore) |
| Structured data / queryable cache | `Drift` (SQLite) | Typed queries, relations, migrations |
| Theme, locale, feature flags | `SharedPreferences` | Simple key-value, no sensitivity |
| Large binary / files | File system | Outside API scope |

---

## SecureStorage — tokens

```dart
// shared/api/auth/auth_local_api.dart
@injectable
class AuthLocalApi {
  AuthLocalApi(this._secureStorage);
  final FlutterSecureStorage _secureStorage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      Future.wait([
        _secureStorage.write(key: _accessKey, value: accessToken),
        _secureStorage.write(key: _refreshKey, value: refreshToken),
      ]);

  Future<String?> getAccessToken() => _secureStorage.read(key: _accessKey);

  Future<String?> getRefreshToken() => _secureStorage.read(key: _refreshKey);

  Future<void> clearTokens() => Future.wait([
        _secureStorage.delete(key: _accessKey),
        _secureStorage.delete(key: _refreshKey),
      ]);
}
```

---

## Drift (SQLite) — structured / queryable cache

```dart
// shared/api/transaction/transaction_local_api.dart
@injectable
class TransactionLocalApi {
  TransactionLocalApi(this._db);
  final AppDatabase _db;

  Future<List<TransactionTableData>> getAll() =>
      _db.select(_db.transactionTable).get();

  Future<void> insertAll(List<TransactionTableCompanion> rows) =>
      _db.batch((batch) => batch.insertAll(_db.transactionTable, rows));

  Future<void> deleteAll() => _db.delete(_db.transactionTable).go();
}
```

---

## SharedPreferences — settings and flags

```dart
// shared/api/settings/settings_local_api.dart
@injectable
class SettingsLocalApi {
  SettingsLocalApi(this._prefs);
  final SharedPreferences _prefs;

  static const _themeKey = 'is_dark_mode';
  static const _localeKey = 'locale';

  bool get isDarkMode => _prefs.getBool(_themeKey) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_themeKey, value);

  String get locale => _prefs.getString(_localeKey) ?? 'en';
  Future<void> setLocale(String locale) => _prefs.setString(_localeKey, locale);
}
```

---

## Key points

- Class naming: `{Domain}LocalApi` (not DataSource)
- No abstract interface — concrete class with `@injectable`
- Location: `shared/api/{domain}/{domain}_local_api.dart`
