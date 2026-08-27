import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/repositories/app_repo.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppUseCase {
  final AppRepo _appRepo;

  AppUseCase(this._appRepo);

  AppLanguage getSavedAppLanguage() {
    return _appRepo.getSavedLanguage();
  }

  Future<void> saveLanguage({required AppLanguage language}) {
    return _appRepo.saveLanguage(language: language);
  }
}
