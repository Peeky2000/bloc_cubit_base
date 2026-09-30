import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'splash_effect.dart';
part 'splash_state.dart';

@injectable
class SplashCubit extends BaseCubit<SplashState> {
  SplashCubit(this._authUseCase) : super(SplashState.initial());

  final AuthUseCase _authUseCase;

  @override
  Future<void> load() async {
    final isAppLogin = _authUseCase.isAppLogin();
    final account = _authUseCase.accountLocal;
    final isPhoneVerified = account.isPhoneVerified == true;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        isLogin: isAppLogin,
        isPhoneVerified: isPhoneVerified,
        phone: account.phone,
      ),
    );
    if (!isAppLogin) {
      _emitEffect(const SplashNavigateSignInEffect());
      return;
    }
    if (isPhoneVerified) {
      _emitEffect(const SplashNavigateHomeEffect());
      return;
    }
    await sendCodeVerify();
  }

  Future<void> sendCodeVerify() async {
    final phone = state.phone;
    if (phone == null || phone.isEmpty) {
      _emitEffect(const SplashNavigateSignInEffect());
      return;
    }

    emit(state.copyWith(loading: LoadingStatus.loading));
    try {
      await _authUseCase.sendCodeVerify(
        phone: phone,
        onComplete: () {
          if (isClosed) {
            return;
          }
          emit(state.copyWith(loading: LoadingStatus.complete));
          _emitEffect(SplashNavigatePhoneVerificationEffect(phone: phone));
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
    emit(state.copyWith(loading: LoadingStatus.error, error: error));
    _emitEffect(SplashShowErrorEffect(error: error));
  }

  void _emitEffect(SplashEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
