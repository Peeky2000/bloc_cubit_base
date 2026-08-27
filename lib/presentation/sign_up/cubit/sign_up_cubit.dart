import 'package:bloc_cubit_base/core/app/app_controller.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

part 'sign_up_state.dart';

@injectable
class SignUpCubit extends BaseCubit<SignUpState> {
  final AppController _appController;
  final AuthUseCase _authUseCase;

  String _email = '';
  String _phone = '';
  String _password = '';
  String _shopName = '';
  final List<String> _industry = [];
  ScaleLevel _level = ScaleLevel.KHONG_THUONG_XUYEN;

  SignUpCubit(this._authUseCase, this._appController)
    : super(SignUpState.initial());

  BuildContext? get _context => _appController.context;

  void onChangeShowPass() {
    emit(state.copyWith(showPass: !state.showPass));
  }

  void changePage(int index) {
    emit(state.copyWith(currentPage: index));
  }

  void onNextPage() {
    if (state.changePageViewStatus == ChangePageViewStatus.next) {
      emit(state.copyWith(changePageViewStatus: null));
    }
    emit(state.copyWith(changePageViewStatus: ChangePageViewStatus.next));
  }

  void previousPage() {
    if (state.changePageViewStatus == ChangePageViewStatus.previous) {
      emit(state.copyWith(changePageViewStatus: null));
    }
    emit(state.copyWith(changePageViewStatus: ChangePageViewStatus.previous));
  }

  void onChangeScaleLevel(ScaleLevel level) {
    _level = level;
    emit(state.copyWith(currentScaleLevel: level));
  }

  void onChangeSelectedIndustry(IndustryType type, String name, bool selected) {
    List<IndustryType> industries = (state.industries ?? [])
        .map((e) => e)
        .toList();
    selected ? industries.add(type) : industries.remove(type);
    selected ? _industry.add(name) : _industry.remove(name);
    emit(state.copyWith(industries: industries));
  }

  void onTapSignUp({
    required String phone,
    required String email,
    required String pass,
  }) {
    String? errorPhone;
    String? errorEmail;
    String? errorPass;
    bool isValid = true;
    if (phone.isEmpty) {
      errorPhone = _context?.l10n.phoneIsRequired;
      isValid = false;
    } else if (!Constant.phoneRegexp.hasMatch(phone)) {
      errorPhone = _context?.l10n.phoneIsInvalid;
      isValid = false;
    }
    if (email.isEmpty) {
      errorEmail = _context?.l10n.emailIsRequired;
      isValid = false;
    } else if (!Constant.emailRegexp.hasMatch(email)) {
      errorEmail = _context?.l10n.emailIsInvalid;
      isValid = false;
    }
    if (pass.isEmpty) {
      errorPass = _context?.l10n.passIsRequired;
      isValid = false;
    } else if (!Constant.passwordRegexp.hasMatch(pass)) {
      errorPass = _context?.l10n.passIsInvalid;
      isValid = false;
    }
    emit(
      state.copyWith(
        errorPhone: errorPhone,
        errorEmail: errorEmail,
        errorPassword: errorPass,
        forceUpdateError: true,
      ),
    );
    if (isValid) {
      if (phone[0] == '0') {
        _phone = '+84${phone.substring(1)}';
      } else {
        _phone = phone;
      }
      _email = email;
      _password = pass;
      onNextPage();
    }
  }

  void onTapConfirmInfo({required String shopName}) {
    String? errorShopName;
    String? errIndustry;
    String? errScale;
    bool isValid = true;
    if (shopName.isEmpty) {
      errorShopName = _context?.l10n.shopNameIsRequired;
      isValid = false;
    }
    if (state.industries == null || state.industries!.isEmpty) {
      errIndustry = _context?.l10n.industryIsRequired;
      isValid = false;
    }
    if (state.currentScaleLevel == null) {
      errScale = _context?.l10n.scaleLevelIsRequired;
      isValid = false;
    }
    emit(
      state.copyWith(
        errorShopName: errorShopName,
        errScale: errScale,
        errIndustry: errIndustry,
        forceUpdateError: true,
      ),
    );
    if (isValid) {
      _shopName = shopName;
      _signUp();
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
      emit(state.copyWith(loading: LoadingStatus.complete));
      await sendCodeVerify();
    } catch (e) {
      emit(state.copyWith(loading: LoadingStatus.error));
      handleErrorResponse(e, onRetry: () => _signUp());
    }
  }

  Future<void> sendCodeVerify() async {
    await _authUseCase.sendCodeVerify(
      phone: _phone,
      onComplete: () {
        SLIRouting.toNamed(
          AppPage.confirmInfo,
          arguments: {'phone': _phone, 'page_success': AppPage.signIn},
        );
      },
      onError: (e) {
        emit(state.copyWith(error: e));
      },
    );
  }
}
