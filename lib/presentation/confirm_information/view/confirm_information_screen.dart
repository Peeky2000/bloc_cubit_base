import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:delivery_go/modules/sli_common/lib/sli_common.dart';
import 'package:delivery_go/widget/loading_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sli_common/extension/extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/mixin/after_layout.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/presentation/confirm_information/cubit/confirm_information_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

Widget confirmInformationScreenBuilder() =>
    BlocProvider<ConfirmInformationCubit>(
      create: (_) => Injector.getIt.get<ConfirmInformationCubit>(),
      child: const ConfirmInformationScreen(),
    );

class ConfirmInformationScreen extends StatefulWidget {
  const ConfirmInformationScreen({Key? key}) : super(key: key);

  @override
  _ConfirmInformationScreenState createState() =>
      _ConfirmInformationScreenState();
}

class _ConfirmInformationScreenState extends State<ConfirmInformationScreen>
    with AfterLayoutMixin {
  ConfirmInformationCubit? _confirmInformationCubit;

  @override
  void initState() {
    super.initState();
    _confirmInformationCubit = context.read<ConfirmInformationCubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _confirmInformationCubit?.close();
    super.dispose();
  }

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
                context.l10n.confirmOTP(
                    '${_confirmInformationCubit?.phone.substring(0, _confirmInformationCubit!.phone.length - 3)}***'),
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
                            context.l10n
                                .resendOTPAfter(state.counter.formatTimeMMSS),
                            style: App.appStyle?.medium14?.copyWith(
                              color: App.appColor?.textColorLight,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text: '${context.l10n.dontReceivedOTP}. '),
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
      listener: (context, state) {
        if (state.error != null && state.error is FirebaseAuthException) {
          DialogUtil.error(
            context,
            title: context.l10n.error,
            content: (state.error as FirebaseAuthException).message ?? '',
            closeText: context.l10n.close,
            retryText: context.l10n.retry,
            isShowRetry: true,
            onTapRetry: () => _confirmInformationCubit?.sendCodeVerify(),
          );
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
              ? BackButton(
                  onPressed: () => SLIRouting.back(),
                )
              : null,
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }
}
