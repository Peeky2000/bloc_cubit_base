# Packages (this base)

From `pubspec.yaml` — use these versions/patterns when adding dependencies.

## Runtime

| Package | Purpose in this base |
|---------|---------------------|
| `flutter_bloc` + `bloc` | Cubit state management |
| `get_it` | Service locator (`Injector` in `lib/di/injection.dart`) |
| `equatable` | State equality in Cubits |
| `dio` | HTTP — `ApiClient` implements `ApiHandler` |
| `json_annotation` + `json_serializable` | API models (`.g.dart`) |
| `shared_preferences` | Local storage (tokens, settings via data sources) |
| `firebase_core` / `firebase_auth` | Phone auth flows in `AuthUseCase` |
| `connectivity_plus` | `NetworkChecker` |
| `flutter_localizations` + `intl` | gen-l10n |
| `flutter_screenutil`, `cached_network_image`, `flutter_svg` | UI |
| `flutter_dotenv` | `.env` in assets |
| `another_flushbar`, `auto_size_text`, `pin_code_fields` | UI helpers |

## Dev

| Package | Purpose |
|---------|---------|
| `build_runner` | Generate `.g.dart` for models |
| `flutter_gen_runner` | `lib/generated/assets.gen.dart` |
| `flutter_lints` | Analysis |

## Not used in this base (do not add via skills unless user requests)

| Package | Note |
|---------|------|
| `injectable` / `injectable_generator` | DI is manual in `injection.dart` |
| `go_router` | Use `SLIRouting` |
| `freezed` | States use `BaseAppState` + `copyWith`; entities are abstract classes |
| `retrofit` | Use `ApiHandler.post/get` with parser callbacks |
| `easy_localization` | Use `AppLocalizations` / `.arb` |
| `drift` / `hive` | Not in current pubspec |

## Storage

| Data | Location in code |
|------|------------------|
| Auth tokens | `TokenProvider` + `AuthLocalDataSource` (SharedPreferences) |
| Account cache | `UserLocalDataSource` |
| App flags | `AppLocalDataSource` |
