import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServerMessageLocalization {
  final Locale? locale;

  ServerMessageLocalization(this.locale);

  static ServerMessageLocalization? of(BuildContext context) {
    return Localizations.of<ServerMessageLocalization>(
        context, ServerMessageLocalization);
  }

  static const LocalizationsDelegate<ServerMessageLocalization> delegate =
      ServerMessageLocalizationDelegate();

  Map<String, String>? _localizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "assets/server" folder

    final jsonString = await rootBundle
        .loadString('assets/server_localization/message_$locale.json');

    final Map jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value);
    });

    return true;
  }

  String? translate(String key) {
    return _localizedStrings?[key];
  }
}

class ServerMessageLocalizationDelegate
    extends LocalizationsDelegate<ServerMessageLocalization> {
  const ServerMessageLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return <String>['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<ServerMessageLocalization> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    final localizations = ServerMessageLocalization(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(ServerMessageLocalizationDelegate old) => false;
}

extension TranslateExtension on String {
  String messageServerTranslate(BuildContext? context) {
    if (context == null) {
      return this;
    }
    return ServerMessageLocalization.of(context)?.translate(this) ?? this;
  }
}
