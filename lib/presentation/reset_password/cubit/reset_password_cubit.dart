import 'dart:async';

import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/common/constant.dart';
import 'package:delivery_go/core/common/route.dart';
import 'package:delivery_go/core/error/exception.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/domain/use_case/auth_use_case.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:sli_common/sli_common.dart';
import 'package:sli_common/extension/extensions.dart';
import 'package:delivery_go/presentation/global_handler.dart';
import 'package:equatable/equatable.dart';
import 'package:delivery_go/core/base_component/base_app_state.dart';
import 'package:delivery_go/core/base_component/base_cubit.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:flutter/material.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends BaseCubit<ResetPasswordState> {
  Timer? _timer;
  final BuildContext? _context = Injector.getIt.get<AppController>().context;
  final AuthUseCase _authUseCase = Injector.getIt.get<AuthUseCase>();
  String? _idToken;
  int counter = Constant.timePeriodOTP;

  ResetPasswordCubit() : super(ResetPasswordState.initial());

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }

  void onTapSendRequestLogin(String phone) {
    String? errPhone;
    bool isValid = true;
    if (phone.isEmpty || !Constant.phoneRegexp.hasMatch(phone)) {
      errPhone = _context?.l10n.phoneIsInvalid;
      isValid = false;
    }
    emit(state.copyWith(errorPhone: errPhone));
    if (isValid) {
      emit(state.copyWith(loading: LoadingStatus.loading));
      _authUseCase.sendCodeVerify(
          phone: phone,
          onComplete: () {
            counter = Constant.timePeriodOTP;
            emit(state.copyWith(
                loading: LoadingStatus.complete,
                changePageStatus: ChangePageViewStatus.next,
                counter: counter,
                phone: phone,
                isVerifying: false));
            _timer = Timer.periodic(
              const Duration(seconds: 1),
              (timer) {
                if (!state.isVerifying && counter > 0) {
                  counter--;
                  emit(state.copyWith(counter: counter));
                }
              },
            );
          },
          onError: (e) {
            emit(state.copyWith(error: e));
          });
    }
  }

  void onTapBackPage() {
    if (state.changePageStatus == ChangePageViewStatus.previous) {
      emit(state.copyWith(changePageStatus: null));
    }
    emit(state.copyWith(changePageStatus: ChangePageViewStatus.previous));
  }

  Future<void> onTapResetPassword(
      {required String newPassword, required String confirmPassword}) async {
    String? errNewPass;
    String? errConfirmPass;
    bool isValid = true;
    if (newPassword.isEmpty) {
      errNewPass = _context?.l10n.passIsRequired;
      isValid = false;
    }
    if (confirmPassword.isEmpty || newPassword != confirmPassword) {
      errConfirmPass = _context?.l10n.confirmPassIsNotMath;
      isValid = false;
    }
    emit(state.copyWith(
        errorNewPass: errNewPass, errorConfirmPass: errConfirmPass));
    if (isValid && _idToken.isNotNullOrEmpty) {
      try {
        emit(state.copyWith(loading: LoadingStatus.loading));
        await _authUseCase.resetPasswordPhone(
            idToken: _idToken!, newPassword: newPassword);
        emit(state.copyWith(loading: LoadingStatus.complete));
        DialogUtil.alert(
          _context!,
          title: _context?.l10n.notification,
          content: _context?.l10n.resetPassSuccess ?? '',
          submit: _context?.l10n.signIn,
          onSubmit: () => SLIRouting.offAllNamed(AppPage.SIGN_IN),
        );
      } catch (e) {
        emit(state.copyWith(loading: LoadingStatus.error));
        handleErrorResponse(e);
      }
    }
  }

  void onTapShowNewPass() {
    emit(state.copyWith(
      showNewPass: !state.showNewPass,
      errorNewPass: state.errorNewPass,
      errorConfirmPass: state.errorConfirmPass,
    ));
  }

  void onTapShowConfirmPass() {
    emit(state.copyWith(
      showConfirmPass: !state.showConfirmPass,
      errorNewPass: state.errorNewPass,
      errorConfirmPass: state.errorConfirmPass,
    ));
  }

  Future<void> onCompleteOTP(String otp) async {
    try {
      emit(state.copyWith(isVerifying: true));
      _idToken = await _authUseCase.verifyOTP(otp: otp);
      emit(state.copyWith(isVerifying: false));
      if (_idToken != null) {
        emit(state.copyWith(
            changePageStatus: ChangePageViewStatus.next, counter: 0));
      }
    } catch (e) {
      emit(state.copyWith(isVerifying: false));
      handleErrorResponse(GeneralException(messages: _context?.l10n.failOTP));
    }
  }

  void onChangePage(int page) {
    if (page != 1) {
      _timer?.cancel();
      _timer = null;
    }
  }
}
