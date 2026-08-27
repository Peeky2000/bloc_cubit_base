import 'dart:async';

import 'package:bloc_cubit_base/core/app/app_controller.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/presentation/success/success_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';

part 'confirm_information_state.dart';

@injectable
class ConfirmInformationCubit extends BaseCubit<ConfirmInformationState> {
  String phone = '';
  String pageSuccess = AppPage.home;
  Timer? _timer;
  int counter = Constant.timePeriodOTP;
  final AppController _appController;
  final AuthUseCase _authUseCase;

  ConfirmInformationCubit(this._authUseCase, this._appController)
    : super(ConfirmInformationState.initial()) {
    dynamic data = SLIRouting.routing.args;
    if (data is Map<String, dynamic> && data.containsKey('phone')) {
      phone = data['phone'];
    }
    if (data is Map<String, dynamic> && data.containsKey('page_success')) {
      pageSuccess = data['page_success'];
    }
  }

  BuildContext? get _context => _appController.context;

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }

  Future<void> sendCodeVerify() async {
    emit(state.copyWith(loading: LoadingStatus.loading));
    await _authUseCase.sendCodeVerify(
      phone: phone,
      onComplete: () {},
      onError: (e) {
        emit(state.copyWith(error: e));
      },
    );
    counter = Constant.timePeriodOTP;
    emit(
      state.copyWith(
        loading: LoadingStatus.complete,
        counter: counter,
        isVerifying: false,
      ),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isVerifying && counter > 0) {
        counter--;
        emit(state.copyWith(counter: counter));
      }
    });
  }

  Future<void> verifyOtp(String otp) async {
    try {
      emit(state.copyWith(isVerifying: true));
      String? idToken = await _authUseCase.verifyOTP(otp: otp);
      emit(state.copyWith(isVerifying: false));
      if (idToken != null) {
        await _authUseCase.verifyPhone(idToken: idToken);
        SLIRouting.to(
          SuccessScreen(
            title: _context?.l10n.verifyPhoneSuccess.toUpperCase(),
            subtitle: _context?.l10n.noteSignupSuccess,
          ),
        );
        Future.delayed(
          const Duration(milliseconds: 1400),
          () => SLIRouting.offAllNamed(pageSuccess),
        );
      }
    } catch (e) {
      emit(state.copyWith(isVerifying: false));
      if (e is FirebaseAuthException) {
        handleErrorResponse(GeneralException(messages: _context?.l10n.failOTP));
      } else {
        handleErrorResponse(e);
      }
    }
  }
}
