import 'dart:ui';

import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/data/datasource/local/app_local_data_source.dart';
import 'package:delivery_go/domain/repositories/app_repo.dart';

class AppRepoImpl implements AppRepo {
  final AppLocalDataSource _appLocalDataSource;

  AppRepoImpl(this._appLocalDataSource);

  @override
  Locale getSavedLocale() {
    return _appLocalDataSource.currentLocale;
  }

  @override
  AppLanguage getSavedLanguage() {
    if (_appLocalDataSource.currentLocale == const Locale('vi', 'VN')) {
      return AppLanguage.vi;
    }
    return AppLanguage.en;
  }

  @override
  Future<void> saveLanguage({required AppLanguage language}) {
    return _appLocalDataSource.saveLanguage(language: language);
  }
}
