import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/use_case/app_use_case.dart';
import 'package:injectable/injectable.dart';

part 'app_state.dart';

@singleton
class AppCubit extends Cubit<AppState> {
  final AppUseCase _appUseCase;

  AppCubit(this._appUseCase) : super(AppState.initState());

  void getCurrentLang() {
    final language = _appUseCase.getSavedAppLanguage();
    emit(state.copyWith(locale: _localeFor(language)));
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

  Locale _localeFor(AppLanguage language) => switch (language) {
    AppLanguage.vi => const Locale('vi', 'VN'),
    AppLanguage.en => const Locale('en', 'US'),
  };
}
