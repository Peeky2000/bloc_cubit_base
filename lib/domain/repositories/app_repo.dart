import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';

abstract class AppRepo {
  AppLanguage getSavedLanguage();

  Future<void> saveLanguage({required AppLanguage language});
}
