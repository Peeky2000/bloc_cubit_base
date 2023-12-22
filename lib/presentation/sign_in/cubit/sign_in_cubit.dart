import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/common/constant.dart';
import 'package:delivery_go/core/common/route.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/domain/entities/auth/login.dart';
import 'package:delivery_go/domain/use_case/auth_use_case.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:delivery_go/presentation/global_handler.dart';
import 'package:equatable/equatable.dart';
import 'package:delivery_go/core/base_component/base_app_state.dart';
import 'package:delivery_go/core/base_component/base_cubit.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:flutter/material.dart';

part 'sign_in_state.dart';

class SignInCubit extends BaseCubit<SignInState> {
  final BuildContext? _context = Injector.getIt.get<AppController>().context;
  final AuthUseCase _authUseCase = Injector.getIt.get<AuthUseCase>();
  String usernameFormat = '';

  SignInCubit() : super(SignInState.initial());

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
    emit(state.copyWith(
      errorUsername: errorUsername,
      errorPassword: errorPass,
      forceUpdateError: true,
    ));
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
          isRememberLogin: state.isRememberLogin);
      emit(state.copyWith(loading: LoadingStatus.complete));
      if (loginInfo != null) {
        if (loginInfo.account?.isPhoneVerified == false) {
          await sendCodeVerify();
        } else {
          SLIRouting.offAllNamed(AppPage.HOME);
        }
      }
    } catch (e) {
      emit(state.copyWith(loading: LoadingStatus.error));
      handleErrorResponse(e,
          onRetry: () => _signIn(username: username, pass: pass));
    }
  }

  Future<void> sendCodeVerify() async {
    await _authUseCase.sendCodeVerify(
      phone: usernameFormat,
      onComplete: () {
        SLIRouting.offAllNamed(
          AppPage.CONFIRM_INFO,
          arguments: {
            'phone': usernameFormat,
            'page_success': AppPage.HOME,
          },
        );
      },
      onError: (e) {
        emit(state.copyWith(error: e));
      },
    );
  }

  void onTapForgotPassword() {
    SLIRouting.toNamed(AppPage.RESET_PASSWORD);
  }
}
