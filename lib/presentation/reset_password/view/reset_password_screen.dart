import 'package:sli_common/sli_common.dart' show CommonTextField, DialogUtil;
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/generated/assets.gen.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/widget/app_primary_button.dart';
import 'package:bloc_cubit_base/widget/loading_screen.dart';
import 'package:bloc_cubit_base/core/extension/int_extension.dart';
import 'package:flutter/gestures.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/mixin/after_layout.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/reset_password/cubit/reset_password_cubit.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget resetPasswordScreenBuilder() => BlocProvider<ResetPasswordCubit>(
  create: (_) => Injector.getIt.get<ResetPasswordCubit>(),
  child: const ResetPasswordScreen(),
);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with AfterLayoutMixin {
  ResetPasswordCubit? _resetPasswordCubit;
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _resetPasswordCubit = context.read<ResetPasswordCubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildInputTypePhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBar(
          elevation: 0,
          title: Text(
            context.l10n.forgotPassword,
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          leading: BackButton(onPressed: () => SLIRouting.back()),
          centerTitle: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 64.h),
                child: Assets.images.imgLock.image(),
              ),
              Text(
                context.l10n.pleaseTypePhoneNumber,
                style: App.appStyle?.semiBold18?.copyWith(
                  color: App.appColor?.textColor,
                ),
              ),
              SizedBox(height: 32.h),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _phoneController,
                    title: context.l10n.phoneNumber,
                    hint: context.l10n.phoneNumber,
                    keyboardType: TextInputType.phone,
                    error: _phoneError(context, state.phoneError),
                    maxLength: 15,
                  );
                },
              ),
              SizedBox(height: 32.h),
              AppPrimaryButton(
                title: context.l10n.sendRequestSignIn,
                onTap: () {
                  String phone = _phoneController.text.trim();
                  _resetPasswordCubit?.onTapSendRequestLogin(phone);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirm() {
    return Column(
      children: [
        AppBar(
          elevation: 0,
          title: Text(
            context.l10n.confirmAccount,
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          leading: BackButton(
            onPressed: () => _resetPasswordCubit?.onTapBackPage(),
          ),
          centerTitle: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 64.h),
                child: Assets.images.imgLock.image(),
              ),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return Text(
                    context.l10n.confirmOTP(
                      '${state.phone.substring(0, state.phone.length - 3)}***',
                    ),
                    style: App.appStyle?.semiBold18?.copyWith(
                      color: App.appColor?.textColor,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              SizedBox(height: 32.h),
              PinCodeTextField(
                appContext: context,
                length: 6,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  selectedColor: App.appColor?.primaryColor,
                  inactiveColor: App.appColor?.borderColor,
                  activeFillColor: App.appColor?.primaryColor,
                  activeColor: App.appColor?.primaryColor,
                  borderRadius: BorderRadius.circular(5.0.r),
                  fieldHeight: 32.w,
                  fieldWidth: 32.w,
                ),
                textStyle: App.appStyle?.semiBold18,
                cursorHeight: 16.w,
                animationType: AnimationType.scale,
                keyboardType: TextInputType.number,
                autoDisposeControllers: false,
                onChanged: (String value) {},
                onCompleted: (value) =>
                    _resetPasswordCubit?.onCompleteOTP(value),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
                child: BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                  builder: (context, state) {
                    return state.isVerifying
                        ? Text(
                            '${context.l10n.verifying}...',
                            style: App.appStyle?.medium14?.copyWith(
                              color: App.appColor?.textColor,
                            ),
                          )
                        : state.counter > 0
                        ? Text(
                            context.l10n.resendOTPAfter(
                              state.counter.formatTimeMMSS,
                            ),
                            style: App.appStyle?.medium14?.copyWith(
                              color: App.appColor?.textColorLight,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${context.l10n.dontReceivedOTP}. ',
                                ),
                                TextSpan(
                                  text: context.l10n.resendOTP,
                                  style: App.appStyle?.medium14?.copyWith(
                                    color: App.appColor?.textColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        _resetPasswordCubit?.resendCode(),
                                ),
                              ],
                              style: App.appStyle?.medium14?.copyWith(
                                color: App.appColor?.textColor,
                              ),
                            ),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResetPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBar(
          elevation: 0,
          title: Text(
            context.l10n.forgotPassword,
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          leading: BackButton(
            onPressed: () => _resetPasswordCubit?.onTapBackPage(),
          ),
          centerTitle: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 64.h),
                child: Assets.images.imgLock.image(),
              ),
              Text(
                context.l10n.enterNewPass,
                style: App.appStyle?.semiBold18?.copyWith(
                  color: App.appColor?.textColor,
                ),
              ),
              SizedBox(height: 32.h),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _newPasswordController,
                    title: context.l10n.newPassword,
                    hint: context.l10n.newPassword,
                    keyboardType: TextInputType.visiblePassword,
                    error: _passwordError(context, state.newPasswordError),
                    obscureText: !state.showNewPass,
                    suffix: GestureDetector(
                      onTap: () => _resetPasswordCubit?.onTapShowNewPass(),
                      child: Icon(
                        state.showNewPass == true
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: App.appColor?.iconColor,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _confirmPasswordController,
                    title: context.l10n.retypePassword,
                    hint: context.l10n.retypePassword,
                    keyboardType: TextInputType.visiblePassword,
                    error: _passwordError(context, state.confirmPasswordError),
                    obscureText: !state.showConfirmPass,
                    suffix: GestureDetector(
                      onTap: () => _resetPasswordCubit?.onTapShowConfirmPass(),
                      child: Icon(
                        state.showConfirmPass == true
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: App.appColor?.iconColor,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              AppPrimaryButton(
                title: context.l10n.confirmPassword,
                onTap: () {
                  String newPass = _newPasswordController.text.trim();
                  String confirm = _confirmPasswordController.text.trim();
                  _resetPasswordCubit?.onTapResetPassword(
                    newPassword: newPass,
                    confirmPassword: confirm,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<ResetPasswordCubit, ResetPasswordState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final effect = state.effect?.value;
        switch (effect) {
          case ResetPasswordChangePageEffect(:final delta):
            if (delta > 0) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
              );
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
              );
            }
          case ResetPasswordShowErrorEffect(:final error, :final retryAction):
            handleErrorResponse(
              context,
              error,
              onRetry: () => switch (retryAction) {
                ResetPasswordRetryAction.sendVerificationCode =>
                  _resetPasswordCubit!.resendCode(),
                ResetPasswordRetryAction.resetPassword =>
                  _resetPasswordCubit!.onTapResetPassword(
                    newPassword: _newPasswordController.text.trim(),
                    confirmPassword: _confirmPasswordController.text.trim(),
                  ),
              },
            );
          case ResetPasswordInvalidOtpEffect():
            handleErrorResponse(
              context,
              GeneralException(messages: context.l10n.failOTP),
            );
          case ResetPasswordSucceededEffect():
            DialogUtil.alert(
              context,
              title: context.l10n.notification,
              content: context.l10n.resetPassSuccess,
              submit: context.l10n.signIn,
              onSubmit: () => SLIRouting.offAllNamed(AppPage.signIn),
            );
          case null:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => _resetPasswordCubit?.onChangePage(index),
          children: [
            _buildInputTypePhone(),
            _buildConfirm(),
            _buildResetPassword(),
          ],
        ),
      ),
    );
  }

  String? _phoneError(BuildContext context, PhoneInputError? error) =>
      switch (error) {
        PhoneInputError.required => context.l10n.phoneIsRequired,
        PhoneInputError.invalid => context.l10n.phoneIsInvalid,
        null => null,
      };

  String? _passwordError(BuildContext context, PasswordInputError? error) =>
      switch (error) {
        PasswordInputError.required => context.l10n.passIsRequired,
        PasswordInputError.invalid => context.l10n.passIsInvalid,
        PasswordInputError.mismatch => context.l10n.confirmPassIsNotMath,
        null => null,
      };
}
