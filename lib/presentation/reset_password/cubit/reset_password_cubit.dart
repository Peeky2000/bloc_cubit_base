import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'reset_password_effect.dart';
part 'reset_password_state.dart';

@injectable
class ResetPasswordCubit extends BaseCubit<ResetPasswordState> {
  ResetPasswordCubit(this._authUseCase) : super(ResetPasswordState.initial());

  final AuthUseCase _authUseCase;
  Timer? _timer;
  String? _idToken;
  String _phone = '';
  String _newPassword = '';
  int _counter = Constant.timePeriodOTP;

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }

  Future<void> onTapSendRequestLogin(String phone) async {
    final phoneError = _validatePhone(phone);
    emit(state.copyWith(phoneError: phoneError, forceUpdateValidation: true));
    if (phoneError != null) {
      return;
    }

    _phone = phone;
    emit(state.copyWith(loading: LoadingStatus.loading));
    await _sendCode();
  }

  Future<void> resendCode() async {
    if (_phone.isEmpty || state.isVerifying) {
      return;
    }
    emit(state.copyWith(loading: LoadingStatus.loading));
    await _sendCode();
  }

  Future<void> _sendCode() async {
    try {
      final outcome = await _authUseCase.sendCodeVerify(phone: _phone);
      if (isClosed || outcome == PhoneVerificationOutcome.superseded) {
        return;
      }
      final shouldAdvance = state.phone.isEmpty;
      _counter = Constant.timePeriodOTP;
      emit(
        state.copyWith(
          loading: LoadingStatus.complete,
          counter: _counter,
          phone: _phone,
          isVerifying: false,
        ),
      );
      if (shouldAdvance) {
        _emitEffect(const ResetPasswordChangePageEffect(delta: 1));
      }
      _startTimer();
    } catch (error) {
      _handleSendCodeError(error);
    }
  }

  void _handleSendCodeError(Object error) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(loading: LoadingStatus.error, error: error));
    _emitEffect(
      ResetPasswordShowErrorEffect(
        error: error,
        retryAction: ResetPasswordRetryAction.sendVerificationCode,
      ),
    );
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isVerifying && _counter > 0) {
        _counter--;
        emit(state.copyWith(counter: _counter));
      }
      if (_counter == 0) {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void onTapBackPage() {
    _emitEffect(const ResetPasswordChangePageEffect(delta: -1));
  }

  Future<void> onTapResetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final newPasswordError = newPassword.isEmpty
        ? PasswordInputError.required
        : null;
    final confirmPasswordError = confirmPassword.isEmpty
        ? PasswordInputError.required
        : newPassword != confirmPassword
        ? PasswordInputError.mismatch
        : null;
    emit(
      state.copyWith(
        newPasswordError: newPasswordError,
        confirmPasswordError: confirmPasswordError,
        forceUpdateValidation: true,
      ),
    );
    if (newPasswordError != null ||
        confirmPasswordError != null ||
        _idToken == null) {
      return;
    }

    _newPassword = newPassword;
    try {
      emit(state.copyWith(loading: LoadingStatus.loading));
      await _authUseCase.resetPasswordPhone(
        idToken: _idToken!,
        newPassword: _newPassword,
      );
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.complete));
      _emitEffect(const ResetPasswordSucceededEffect());
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(
        ResetPasswordShowErrorEffect(
          error: error,
          retryAction: ResetPasswordRetryAction.resetPassword,
        ),
      );
    }
  }

  void onTapShowNewPass() {
    emit(state.copyWith(showNewPass: !state.showNewPass));
  }

  void onTapShowConfirmPass() {
    emit(state.copyWith(showConfirmPass: !state.showConfirmPass));
  }

  Future<void> onCompleteOTP(String otp) async {
    try {
      emit(state.copyWith(isVerifying: true));
      _idToken = await _authUseCase.verifyOTP(otp: otp);
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isVerifying: false));
      if (_idToken != null) {
        _stopTimer();
        emit(state.copyWith(counter: 0));
        _emitEffect(const ResetPasswordChangePageEffect(delta: 1));
      }
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isVerifying: false));
      _emitEffect(const ResetPasswordInvalidOtpEffect());
    }
  }

  void onChangePage(int page) {
    if (page != 1) {
      _stopTimer();
    }
  }

  PhoneInputError? _validatePhone(String phone) {
    if (phone.isEmpty) {
      return PhoneInputError.required;
    }
    return Constant.phoneRegexp.hasMatch(phone)
        ? null
        : PhoneInputError.invalid;
  }

  void _emitEffect(ResetPasswordEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
