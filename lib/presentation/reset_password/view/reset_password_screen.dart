import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:delivery_go/widget/loading_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sli_common/extension/extensions.dart';
import 'package:delivery_go/widget/delivery_go_button.dart';
import 'package:flutter/gestures.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sli_common/sli_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/mixin/after_layout.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/presentation/reset_password/cubit/reset_password_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget resetPasswordScreenBuilder() => BlocProvider<ResetPasswordCubit>(
      create: (_) => Injector.getIt.get<ResetPasswordCubit>(),
      child: const ResetPasswordScreen(),
    );

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
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
    _resetPasswordCubit?.close();
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
          leading: BackButton(
            onPressed: () => SLIRouting.back(),
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
                context.l10n.pleaseTypePhoneNumber,
                style: App.appStyle?.semiBold18?.copyWith(
                  color: App.appColor?.textColor,
                ),
              ),
              SizedBox(
                height: 32.h,
              ),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _phoneController,
                    title: context.l10n.phoneNumber,
                    hint: context.l10n.phoneNumber,
                    keyboardType: TextInputType.phone,
                    error: state.errorPhone,
                    maxLength: 15,
                  );
                },
              ),
              SizedBox(
                height: 32.h,
              ),
              DeliveryGoButton(
                title: context.l10n.sendRequestSignIn,
                onTap: () {
                  String phone = _phoneController.text.trim();
                  _resetPasswordCubit?.onTapSendRequestLogin(phone);
                },
              ),
            ],
          ),
        )
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
                        '${state.phone.substring(0, state.phone.length - 3)}***'),
                    style: App.appStyle?.semiBold18?.copyWith(
                      color: App.appColor?.textColor,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              SizedBox(
                height: 32.h,
              ),
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
                                    state.counter.formatTimeMMSS),
                                style: App.appStyle?.medium14?.copyWith(
                                  color: App.appColor?.textColorLight,
                                ),
                              )
                            : Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text:
                                            '${context.l10n.dontReceivedOTP}. '),
                                    TextSpan(
                                      text: context.l10n.resendOTP,
                                      style: App.appStyle?.medium14?.copyWith(
                                        color: App.appColor?.textColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {},
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
        )
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
              SizedBox(
                height: 32.h,
              ),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _newPasswordController,
                    title: context.l10n.newPassword,
                    hint: context.l10n.newPassword,
                    keyboardType: TextInputType.visiblePassword,
                    error: state.errorNewPass,
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
              SizedBox(
                height: 32.h,
              ),
              BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _confirmPasswordController,
                    title: context.l10n.retypePassword,
                    hint: context.l10n.retypePassword,
                    keyboardType: TextInputType.visiblePassword,
                    error: state.errorConfirmPass,
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
              SizedBox(
                height: 32.h,
              ),
              DeliveryGoButton(
                title: context.l10n.confirmPassword,
                onTap: () {
                  String newPass = _newPasswordController.text.trim();
                  String confirm = _confirmPasswordController.text.trim();
                  _resetPasswordCubit?.onTapResetPassword(
                      newPassword: newPass, confirmPassword: confirm);
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state.error != null && state.error is FirebaseAuthException) {
          DialogUtil.error(
            context,
            title: context.l10n.error,
            content: (state.error as FirebaseAuthException).message ?? '',
            closeText: context.l10n.close,
            retryText: context.l10n.retry,
            isShowRetry: true,
            onTapRetry: () => _resetPasswordCubit
                ?.onTapSendRequestLogin(_phoneController.text.trim()),
          );
        }
        switch (state.changePageStatus) {
          case ChangePageViewStatus.next:
            _pageController.nextPage(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut);
            break;
          case ChangePageViewStatus.previous:
            _pageController.previousPage(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut);
            break;
          default:
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
}
