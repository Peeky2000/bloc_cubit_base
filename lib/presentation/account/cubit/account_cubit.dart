import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'account_effect.dart';
part 'account_state.dart';

/// Account screen: shows the signed-in account and signs out (spec 001-account).
@injectable
class AccountCubit extends BaseCubit<AccountState> {
  AccountCubit(this._authUseCase) : super(AccountState.initial());

  final AuthUseCase _authUseCase;

  /// AC2: reads the account cached by the session; no network call.
  @override
  Future<void> load() async {
    final account = _authUseCase.accountLocal;
    emit(
      state.copyWith(
        loading: LoadingStatus.complete,
        email: account.email,
        phone: account.phone,
        role: account.role,
      ),
    );
  }

  /// AC3: asks the screen to confirm before signing out.
  void onTapLogout() {
    _emitEffect(const AccountConfirmLogoutEffect());
  }

  /// AC3/AC4: ends the session, then sends the user to sign-in; on failure
  /// stays here and offers a retry.
  Future<void> logout() async {
    if (state.loading == LoadingStatus.loading) {
      return;
    }
    emit(state.copyWith(loading: LoadingStatus.loading));
    try {
      await _authUseCase.logout();
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.complete));
      _emitEffect(const AccountNavigateSignInEffect());
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(AccountShowErrorEffect(error: error));
    }
  }

  void _emitEffect(AccountEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
