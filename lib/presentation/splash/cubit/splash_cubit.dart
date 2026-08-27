import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/core/extension/string_extension.dart';
import 'package:bloc_cubit_base/core/helper/log.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'splash_state.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  final AuthUseCase _authUseCase;

  SplashCubit(this._authUseCase) : super(SplashState.initial());

  Future<void> load() async {
    bool isAppLogin = _authUseCase.isAppLogin();
    Account account = _authUseCase.accountLocal;
    Future.delayed(const Duration(milliseconds: 1400), () {
      emit(
        state.copyWith(
          isLogin: isAppLogin,
          isPhoneVerified: account.isPhoneVerified,
          phone: account.phone,
        ),
      );
    });
  }

  Future<void> sendCodeVerify() async {
    if (state.phone.isNotNullOrEmpty) {
      await _authUseCase.sendCodeVerify(
        phone: state.phone!,
        onComplete: () {
          SLIRouting.offAllNamed(
            AppPage.confirmInfo,
            arguments: {'phone': state.phone!, 'page_success': AppPage.home},
          );
        },
        onError: (e) {
          Log.e(message: e.message);
        },
      );
    }
  }
}
