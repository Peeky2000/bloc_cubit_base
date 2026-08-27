import 'package:bloc_cubit_base/data/datasource/local/app_local_data_source.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/repositories/app_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppRepo)
class AppRepoImpl implements AppRepo {
  final AppLocalDataSource _appLocalDataSource;

  AppRepoImpl(this._appLocalDataSource);

  @override
  AppLanguage getSavedLanguage() => _appLocalDataSource.currentLanguage;

  @override
  Future<void> saveLanguage({required AppLanguage language}) {
    return _appLocalDataSource.saveLanguage(language: language);
  }
}
