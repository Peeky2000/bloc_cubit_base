import 'package:flutter/widgets.dart';
import 'package:bloc_cubit_base/l10n/arb/app_localizations.dart';

export 'package:bloc_cubit_base/l10n/arb/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
