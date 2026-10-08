import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'confirm_information_effect.dart';
part 'confirm_information_state.dart';

@injectable
class ConfirmInformationCubit extends BaseCubit<ConfirmInformationState> {
  ConfirmInformationCubit(this._authUseCase)
    : super(ConfirmInformationState.initial());

  final AuthUseCase _authUseCase;
  Timer? _timer;
  String _phone = '';
  int _counter = Constant.timePeriodOTP;

  void initialize({required String phone}) {
    if (_phone.isNotEmpty) {
      return;
    }
    _phone = phone;
    _counter = Constant.timePeriodOTP;
    emit(state.copyWith(phone: phone, counter: _counter));
    _startTimer();
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }

  Future<void> sendCodeVerify() async {
    if (_phone.isEmpty || state.isVerifying) {
      return;
    }
    emit(state.copyWith(loading: LoadingStatus.loading));
    try {
      final outcome = await _authUseCase.sendCodeVerify(phone: _phone);
      if (isClosed || outcome == PhoneVerificationOutcome.superseded) {
        return;
      }
      _counter = Constant.timePeriodOTP;
      emit(
        state.copyWith(
          loading: LoadingStatus.complete,
          counter: _counter,
          isVerifying: false,
        ),
      );
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
    _emitEffect(ConfirmInformationShowErrorEffect(error: error));
  }

  Future<void> verifyOtp(String otp) async {
    try {
      emit(state.copyWith(isVerifying: true));
      final idToken = await _authUseCase.verifyOTP(otp: otp);
      if (isClosed) {
        return;
      }
      if (idToken == null) {
        emit(state.copyWith(isVerifying: false));
        _emitEffect(const ConfirmInformationInvalidOtpEffect());
        return;
      }
      await _authUseCase.verifyPhone(idToken: idToken);
      if (isClosed) {
        return;
      }
      _stopTimer();
      emit(state.copyWith(isVerifying: false, counter: 0));
      _emitEffect(const ConfirmInformationVerifiedEffect());
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isVerifying: false));
      _emitEffect(const ConfirmInformationInvalidOtpEffect());
    }
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

  void _emitEffect(ConfirmInformationEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
