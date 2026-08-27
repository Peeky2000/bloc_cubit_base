import 'package:bloc_cubit_base/core/app/app_controller.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

part 'sign_in_state.dart';

@injectable
class SignInCubit extends BaseCubit<SignInState> {
  final AppController _appController;
  final AuthUseCase _authUseCase;
  String usernameFormat = '';

  SignInCubit(this._authUseCase, this._appController)
    : super(SignInState.initial());

  BuildContext? get _context => _appController.context;

  void onChangeRememberLogin() {
    emit(state.copyWith(isRememberLogin: !state.isRememberLogin));
  }

  void onChangeShowPass() {
    emit(state.copyWith(showPass: !state.showPass));
  }

  void onTapSignIn({required String username, required String pass}) {
    String? errorUsername;
    String? errorPass;
    bool isValid = true;
    if (username.isEmpty) {
      errorUsername = _context?.l10n.emailPhoneIsRequired;
      isValid = false;
    } else if (!Constant.phoneRegexp.hasMatch(username) &&
        !Constant.emailRegexp.hasMatch(username)) {
      errorUsername = _context?.l10n.emailPhoneIsInvalid;
      isValid = false;
    }
    if (pass.isEmpty) {
      errorPass = _context?.l10n.passIsRequired;
      isValid = false;
    } else if (!Constant.passwordRegexp.hasMatch(pass)) {
      errorPass = _context?.l10n.passIsInvalid;
      isValid = false;
    }
    emit(
      state.copyWith(
        errorUsername: errorUsername,
        errorPassword: errorPass,
        forceUpdateError: true,
      ),
    );
    if (isValid) {
      _signIn(username: username, pass: pass);
    }
  }

  Future<void> _signIn({required String username, required String pass}) async {
    try {
      emit(state.copyWith(loading: LoadingStatus.loading));
      if (username[0] == '0') {
        usernameFormat = '+84${username.substring(1)}';
      } else {
        usernameFormat = username;
      }
      Login? loginInfo = await _authUseCase.login(
        phone: usernameFormat,
        password: pass,
        isRememberLogin: state.isRememberLogin,
      );
      emit(state.copyWith(loading: LoadingStatus.complete));
      if (loginInfo != null) {
        if (loginInfo.account?.isPhoneVerified == false) {
          await sendCodeVerify();
        } else {
          SLIRouting.offAllNamed(AppPage.home);
        }
      }
    } catch (e) {
      emit(state.copyWith(loading: LoadingStatus.error));
      handleErrorResponse(
        e,
        onRetry: () => _signIn(username: username, pass: pass),
      );
    }
  }

  Future<void> sendCodeVerify() async {
    await _authUseCase.sendCodeVerify(
      phone: usernameFormat,
      onComplete: () {
        SLIRouting.offAllNamed(
          AppPage.confirmInfo,
          arguments: {'phone': usernameFormat, 'page_success': AppPage.home},
        );
      },
      onError: (e) {
        emit(state.copyWith(error: e));
      },
    );
  }

  void onTapForgotPassword() {
    SLIRouting.toNamed(AppPage.resetPassword);
  }
}
