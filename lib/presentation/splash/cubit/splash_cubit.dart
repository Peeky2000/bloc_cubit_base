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
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (isClosed) {
      return;
    }

    emit(state.copyWith(isLogin: isAppLogin));
    _emitEffect(
      isAppLogin
          ? const SplashNavigateHomeEffect()
          : const SplashNavigateSignInEffect(),
    );
  }

  void _emitEffect(SplashEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
