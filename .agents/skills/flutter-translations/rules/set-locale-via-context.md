# Rule: Change locale via context.setLocale(), don't create a separate BLoC

## Why

`easy_localization` already manages locale state internally (`EasyLocalization` is an `InheritedWidget`). Creating an additional `LocalizationCubit` or `LanguageBloc` duplicates that state and risks getting out of sync.

## ❌ Bad

```dart
// Separate BLoC just to change locale — redundant
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('vi'));

  void changeLanguage(Locale locale) {
    // must remember to call both context.setLocale() AND emit()
    emit(locale);
  }
}
```

## ✅ Good

```dart
// Call directly from UI — sufficient, no BLoC needed
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => context.setLocale(const Locale('vi')),
          child: const Text('VI'),
        ),
        TextButton(
          onPressed: () => context.setLocale(const Locale('en')),
          child: const Text('EN'),
        ),
      ],
    );
  }
}
```

## Exception

If you need to **persist** the locale selection (e.g. save to SharedPreferences when the user picks a language), use a Cubit **only** for persistence — not to hold locale state:

```dart
class SettingsCubit extends Cubit<SettingsState> {
  Future<void> changeLanguage(BuildContext context, Locale locale) async {
    await context.setLocale(locale);                           // easy_localization owns the state
    await _prefs.setString('locale', locale.languageCode);    // cubit handles persistence only
  }
}
```
