import 'package:flutter/material.dart';
import 'package:delivery_go/core/common/enum.dart';

abstract class AppRepo {
  Locale getSavedLocale();

  AppLanguage getSavedLanguage();

  Future<void> saveLanguage({required AppLanguage language});
}
