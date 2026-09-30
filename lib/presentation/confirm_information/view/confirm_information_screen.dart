import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/generated/assets.gen.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/widget/loading_screen.dart';
import 'package:bloc_cubit_base/core/extension/int_extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/mixin/after_layout.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/confirm_information/cubit/confirm_information_cubit.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/presentation/success/success_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

Widget confirmInformationScreenBuilder() =>
    BlocProvider<ConfirmInformationCubit>(
      create: (_) => Injector.getIt.get<ConfirmInformationCubit>(),
      child: const ConfirmInformationScreen(),
    );

class ConfirmInformationScreen extends StatefulWidget {
  const ConfirmInformationScreen({super.key});

  @override
  State<ConfirmInformationScreen> createState() =>
      _ConfirmInformationScreenState();
}

class _ConfirmInformationScreenState extends State<ConfirmInformationScreen>
    with AfterLayoutMixin {
  ConfirmInformationCubit? _confirmInformationCubit;
  bool _initialized = false;
  String _pageSuccess = AppPage.home;

  @override
  void initState() {
    super.initState();
    _confirmInformationCubit = context.read<ConfirmInformationCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      final phone = arguments['phone'];
      final pageSuccess = arguments['page_success'];
      if (phone is String) {
        _confirmInformationCubit?.initialize(phone: phone);
      }
      if (pageSuccess is String) {
        _pageSuccess = pageSuccess;
      }
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 64.h),
            child: Assets.images.imgLock.image(),
          ),
          BlocBuilder<ConfirmInformationCubit, ConfirmInformationState>(
            builder: (context, state) {
              return Text(
                context.l10n.confirmOTP(_maskedPhone(state.phone)),
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
            onCompleted: (value) => _confirmInformationCubit?.verifyOtp(value),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
            child:
                BlocBuilder<ConfirmInformationCubit, ConfirmInformationState>(
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
                                    ..onTap = () => _confirmInformationCubit
                                        ?.sendCodeVerify(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<ConfirmInformationCubit, ConfirmInformationState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final effect = state.effect?.value;
        switch (effect) {
          case ConfirmInformationShowErrorEffect(:final error):
            handleErrorResponse(
              context,
              error,
              onRetry: () => _confirmInformationCubit!.sendCodeVerify(),
            );
          case ConfirmInformationInvalidOtpEffect():
            handleErrorResponse(
              context,
              GeneralException(messages: context.l10n.failOTP),
            );
          case ConfirmInformationVerifiedEffect():
            _handleVerified();
          case null:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            context.l10n.confirmAccount.toUpperCase(),
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? BackButton(onPressed: () => SLIRouting.back())
              : null,
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  String _maskedPhone(String phone) {
    if (phone.length <= 3) {
      return '***';
    }
    return '${phone.substring(0, phone.length - 3)}***';
  }

  Future<void> _handleVerified() async {
    SLIRouting.to(
      SuccessScreen(
        title: context.l10n.verifyPhoneSuccess.toUpperCase(),
        subtitle: context.l10n.noteSignupSuccess,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      return;
    }
    SLIRouting.offAllNamed(_pageSuccess);
  }
}
