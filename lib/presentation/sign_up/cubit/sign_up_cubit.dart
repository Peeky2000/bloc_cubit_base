import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:injectable/injectable.dart';

part 'sign_up_effect.dart';
part 'sign_up_state.dart';

@injectable
class SignUpCubit extends BaseCubit<SignUpState> {
  SignUpCubit(this._authUseCase) : super(SignUpState.initial());

  final AuthUseCase _authUseCase;
  String _email = '';
  String _phone = '';
  String _password = '';
  String _shopName = '';
  final List<String> _industry = [];
  ScaleLevel _level = ScaleLevel.KHONG_THUONG_XUYEN;

  void onChangeShowPass() {
    emit(state.copyWith(showPass: !state.showPass));
  }

  void changePage(int index) {
    emit(state.copyWith(currentPage: index));
  }

  void onNextPage() {
    _emitEffect(const SignUpChangePageEffect(delta: 1));
  }

  void previousPage() {
    _emitEffect(const SignUpChangePageEffect(delta: -1));
  }

  void onChangeScaleLevel(ScaleLevel level) {
    _level = level;
    emit(state.copyWith(currentScaleLevel: level));
  }

  void onChangeSelectedIndustry(IndustryType type, String name, bool selected) {
    final industries = [...?state.industries];
    if (selected) {
      if (!industries.contains(type)) {
        industries.add(type);
      }
      if (!_industry.contains(name)) {
        _industry.add(name);
      }
    } else {
      industries.remove(type);
      _industry.remove(name);
    }
    emit(state.copyWith(industries: industries));
  }

  void onTapSignUp({
    required String phone,
    required String email,
    required String pass,
  }) {
    final phoneError = _validatePhone(phone);
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(pass);
    emit(
      state.copyWith(
        phoneError: phoneError,
        emailError: emailError,
        passwordError: passwordError,
        forceUpdateValidation: true,
      ),
    );
    if (phoneError != null || emailError != null || passwordError != null) {
      return;
    }

    _phone = AuthUseCase.normalizePhone(phone);
    _email = email;
    _password = pass;
    onNextPage();
  }

  PhoneInputError? _validatePhone(String phone) {
    if (phone.isEmpty) {
      return PhoneInputError.required;
    }
    return Constant.phoneRegexp.hasMatch(phone)
        ? null
        : PhoneInputError.invalid;
  }

  EmailInputError? _validateEmail(String email) {
    if (email.isEmpty) {
      return EmailInputError.required;
    }
    return Constant.emailRegexp.hasMatch(email)
        ? null
        : EmailInputError.invalid;
  }

  PasswordInputError? _validatePassword(String password) {
    if (password.isEmpty) {
      return PasswordInputError.required;
    }
    return Constant.passwordRegexp.hasMatch(password)
        ? null
        : PasswordInputError.invalid;
  }

  Future<void> onTapConfirmInfo({required String shopName}) async {
    final shopNameError = shopName.isEmpty ? RequiredInputError.required : null;
    final industryError = state.industries?.isNotEmpty == true
        ? null
        : RequiredInputError.required;
    final scaleError = state.currentScaleLevel == null
        ? RequiredInputError.required
        : null;
    emit(
      state.copyWith(
        shopNameError: shopNameError,
        industryError: industryError,
        scaleError: scaleError,
        forceUpdateValidation: true,
      ),
    );
    if (shopNameError == null && industryError == null && scaleError == null) {
      _shopName = shopName;
      await _signUp();
    }
  }

  Future<void> _signUp() async {
    try {
      emit(state.copyWith(loading: LoadingStatus.loading));
      final request = SignUpParams(
        email: _email,
        password: _password,
        phone: _phone,
        industry: _industry.join(','),
        shippingScale: _level,
        shopName: _shopName,
      );
      await _authUseCase.userSignUp(request: request);
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.complete));
      await sendCodeVerify();
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(
        SignUpShowErrorEffect(
          error: error,
          retryAction: SignUpRetryAction.signUp,
        ),
      );
    }
  }

  Future<void> sendCodeVerify() async {
    try {
      final outcome = await _authUseCase.sendCodeVerify(phone: _phone);
      if (isClosed || outcome == PhoneVerificationOutcome.superseded) {
        return;
      }
      _emitEffect(SignUpNavigatePhoneVerificationEffect(phone: _phone));
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
      SignUpShowErrorEffect(
        error: error,
        retryAction: SignUpRetryAction.sendVerificationCode,
      ),
    );
  }

  void _emitEffect(SignUpEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}
