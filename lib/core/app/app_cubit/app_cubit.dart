import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/domain/use_case/app_use_case.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  final AppUseCase _appUseCase = Injector.getIt.get<AppUseCase>();

  AppCubit() : super(AppState.initState());

  void getCurrentLang() {
    Locale currentLocale = _appUseCase.getSavedLocale();
    emit(state.copyWith(locale: currentLocale));
  }

  Future<void> changeLanguage() async {
    if (_appUseCase.getSavedAppLanguage() == AppLanguage.en) {
      _appUseCase.saveLanguage(language: AppLanguage.vi);
      emit(state.copyWith(locale: const Locale('vi', 'VN')));
    } else {
      _appUseCase.saveLanguage(language: AppLanguage.en);
      emit(state.copyWith(locale: const Locale('en', 'US')));
    }
  }
}
