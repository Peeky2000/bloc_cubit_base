import 'package:mOrder/core/common/route.dart';
import 'package:mOrder/core/routing/routing.dart';
import 'package:mOrder/domain/entities/profile/account.dart';
import 'package:mOrder/core/extension/string_extension.dart';
import 'package:mOrder/core/helper/log.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mOrder/di/injection.dart';
import 'package:mOrder/domain/use_case/auth_use_case.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final AuthUseCase _authUseCase = Injector.getIt.get<AuthUseCase>();

  SplashCubit() : super(SplashState.initial());

  Future<void> load() async {
    bool isAppLogin = _authUseCase.isAppLogin();
    Account account = _authUseCase.accountLocal;
    Future.delayed(
      const Duration(milliseconds: 1400),
      () {
        emit(
          state.copyWith(
            isLogin: isAppLogin,
            isPhoneVerified: account.isPhoneVerified,
            phone: account.phone,
          ),
        );
      },
    );
  }

  Future<void> sendCodeVerify() async {
    if (state.phone.isNotNullOrEmpty) {
      await _authUseCase.sendCodeVerify(
        phone: state.phone!,
        onComplete: () {
          SLIRouting.offAllNamed(
            AppPage.CONFIRM_INFO,
            arguments: {
              'phone': state.phone!,
              'page_success': AppPage.HOME,
            },
          );
        },
        onError: (e) {
          Log.e(message: e.message);
        },
      );
    }
  }
}
