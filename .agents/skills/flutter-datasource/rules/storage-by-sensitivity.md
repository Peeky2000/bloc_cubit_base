# Rule: Choose Storage by Data Sensitivity

**Why:** Each storage mechanism has a different security model and performance profile.
Storing tokens in SharedPreferences exposes them to other apps on rooted devices.
Using SecureStorage for non-sensitive flags wastes encrypted I/O and adds latency.

---

## Bad

```dart
// Token in SharedPreferences — plaintext, readable by any app on rooted device
@injectable
class AuthLocalApi {
  AuthLocalApi(this._prefs);
  final SharedPreferences _prefs;

  Future<void> saveAccessToken(String token) =>
      _prefs.setString('access_token', token); // not encrypted
}

// Dark mode flag in SecureStorage — over-engineered, slow async for a boolean
@injectable
class SettingsLocalApi {
  SettingsLocalApi(this._storage);
  final FlutterSecureStorage _storage;

  Future<void> setDarkMode(bool value) =>
      _storage.write(key: 'is_dark_mode', value: '$value'); // unnecessary
}

// Complex structured data in SharedPreferences — not designed for queries
@injectable
class ProductLocalApi {
  ProductLocalApi(this._prefs);
  final SharedPreferences _prefs;

  Future<void> cacheProducts(List<Product> products) =>
      _prefs.setString('products', jsonEncode(products)); // manual JSON, no indexing
}
```

---

## Good

```dart
// Token -> FlutterSecureStorage (Keychain on iOS, Keystore on Android)
@injectable
class AuthLocalApi {
  AuthLocalApi(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token); // OS-encrypted
}

// Simple flag -> SharedPreferences (synchronous read, fast, appropriate)
@injectable
class SettingsLocalApi {
  SettingsLocalApi(this._prefs);
  final SharedPreferences _prefs;
  static const _themeKey = 'is_dark_mode';

  bool get isDarkMode => _prefs.getBool(_themeKey) ?? false; // instant sync read
  Future<void> setDarkMode(bool v) => _prefs.setBool(_themeKey, v);
}

// Structured data -> Drift (SQLite) (typed queries, relations, migrations)
@injectable
class ProductLocalApi {
  ProductLocalApi(this._db);
  final AppDatabase _db;

  Future<List<ProductTableData>> getCachedProducts() =>
      _db.select(_db.productTable).get(); // typed, queryable

  Future<void> cacheProducts(List<ProductTableCompanion> products) =>
      _db.batch((batch) => batch.insertAll(_db.productTable, products,
          mode: InsertMode.insertOrReplace)); // indexed, transactional
}
```

---

## Decision matrix

| Data | Storage | Reason |
|---|---|---|
| Access token, refresh token | `FlutterSecureStorage` | Encrypted, OS-protected |
| Structured data, queryable cache | `Drift` (SQLite) | Typed queries, relations, migrations |
| Theme, locale, onboarding flag | `SharedPreferences` | Simple key-value, synchronous read |
| Large binary / media file | File system | Outside API scope |
