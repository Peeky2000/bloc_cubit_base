import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'sign_in_effect.dart';
part 'sign_in_state.dart';

@injectable
class SignInCubit extends BaseCubit<SignInState> {
  SignInCubit(this._authUseCase) : super(SignInState.initial());

  final AuthUseCase _authUseCase;
  String _usernameFormat = '';

  void onChangeRememberLogin() {
    emit(state.copyWith(isRememberLogin: !state.isRememberLogin));
  }

  void onChangeShowPass() {
    emit(state.copyWith(showPass: !state.showPass));
  }

  Future<void> onTapSignIn({
    required String username,
    required String pass,
  }) async {
    final usernameError = _validateUsername(username);
    final passwordError = _validatePassword(pass);
    emit(
      state.copyWith(
        usernameError: usernameError,
        passwordError: passwordError,
        forceUpdateValidation: true,
      ),
    );
    if (usernameError == null && passwordError == null) {
      await _signIn(username: username, pass: pass);
    }
  }

  EmailOrPhoneInputError? _validateUsername(String username) {
    if (username.isEmpty) {
      return EmailOrPhoneInputError.required;
    }
    if (!Constant.phoneRegexp.hasMatch(username) &&
        !Constant.emailRegexp.hasMatch(username)) {
      return EmailOrPhoneInputError.invalid;
    }
    return null;
  }

  PasswordInputError? _validatePassword(String password) {
    if (password.isEmpty) {
      return PasswordInputError.required;
    }
    if (!Constant.passwordRegexp.hasMatch(password)) {
      return PasswordInputError.invalid;
    }
    return null;
  }

  Future<void> _signIn({required String username, required String pass}) async {
    try {
      emit(state.copyWith(loading: LoadingStatus.loading));
      _usernameFormat = username.startsWith('0')
          ? '+84${username.substring(1)}'
          : username;
      final Login? loginInfo = await _authUseCase.login(
        phone: _usernameFormat,
        password: pass,
        isRememberLogin: state.isRememberLogin,
      );
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.complete));
      if (loginInfo == null) {
        return;
      }
      if (loginInfo.account?.isPhoneVerified == false) {
        await sendCodeVerify();
      } else {
        _emitEffect(const SignInNavigateHomeEffect());
      }
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(
        SignInShowErrorEffect(
          error: error,
          retryAction: SignInRetryAction.signIn,
        ),
      );
    }
  }

  Future<void> sendCodeVerify() async {
    try {
      await _authUseCase.sendCodeVerify(
        phone: _usernameFormat,
        onComplete: () {
          if (isClosed) {
            return;
          }
          _emitEffect(
            SignInNavigatePhoneVerificationEffect(phone: _usernameFormat),
          );
        },
        onError: _handleSendCodeError,
      );
    } catch (error) {
      _handleSendCodeError(error);
    }
  }

  void _handleSendCodeError(Object error) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(error: error));
    _emitEffect(
      SignInShowErrorEffect(
        error: error,
        retryAction: SignInRetryAction.sendVerificationCode,
      ),
    );
  }

  void onTapForgotPassword() {
    _emitEffect(const SignInNavigateForgotPasswordEffect());
  }

  void _emitEffect(SignInEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
