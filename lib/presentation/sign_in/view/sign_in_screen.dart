import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/common/route.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:delivery_go/widget/delivery_go_button.dart';
import 'package:delivery_go/widget/loading_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:sli_common/sli_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/mixin/after_layout.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget signInScreenBuilder() => BlocProvider<SignInCubit>(
      create: (_) => Injector.getIt.get<SignInCubit>(),
      child: const SignInScreen(),
    );

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with AfterLayoutMixin {
  final TextEditingController _usernameTextController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();

  SignInCubit? _signInCubit;

  @override
  void initState() {
    super.initState();
    _signInCubit = context.read<SignInCubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _signInCubit?.close();
    super.dispose();
  }

  Widget _buildOption() {
    return Row(
      children: [
        BlocBuilder<SignInCubit, SignInState>(
          builder: (context, state) {
            return Radio<bool>(
              value: true,
              groupValue: state.isRememberLogin,
              onChanged: (value) => _signInCubit?.onChangeRememberLogin(),
              activeColor: App.appColor?.primaryColor,
              toggleable: true,
            );
          },
        ),
        InkWell(
          onTap: () => _signInCubit?.onChangeRememberLogin(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.h),
            child: Text(
              context.l10n.rememberSignIn,
              style: App.appStyle?.medium14?.copyWith(
                color: App.appColor?.textColor,
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _signInCubit?.onTapForgotPassword(),
          child: Text(
            context.l10n.forgotPassword,
            style: App.appStyle?.medium14?.copyWith(
              color: App.appColor?.textColor,
              decoration: TextDecoration.underline,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.l10n.signIn.toUpperCase(),
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
            child: Text(
              context.l10n.welcomeToGiaohang247,
              style: App.appStyle?.medium14?.copyWith(
                color: App.appColor?.textColor,
              ),
            ),
          ),
          BlocBuilder<SignInCubit, SignInState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _usernameTextController,
                title: '${context.l10n.email}/${context.l10n.phoneNumber}',
                hint: '${context.l10n.email}/${context.l10n.phoneNumber}',
                keyboardType: TextInputType.emailAddress,
                error: state.errorUsername,
              );
            },
          ),
          SizedBox(
            height: 16.h,
          ),
          BlocBuilder<SignInCubit, SignInState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _passTextController,
                title: context.l10n.password,
                hint: context.l10n.password,
                keyboardType: TextInputType.visiblePassword,
                error: state.errorPassword,
                obscureText: !(_signInCubit?.state.showPass ?? false),
                suffixConstraints:
                    BoxConstraints.tightFor(width: 44.w, height: 20.w),
                suffix: GestureDetector(
                  onTap: () => _signInCubit?.onChangeShowPass(),
                  child: Icon(
                    state.showPass == true
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
          _buildOption(),
          SizedBox(
            height: 32.h,
          ),
          DeliveryGoButton(
            title: context.l10n.signInNowPerWord,
            onTap: () {
              String username = _usernameTextController.text.trim();
              String pass = _passTextController.text.trim();
              _signInCubit?.onTapSignIn(username: username, pass: pass);
            },
          ),
          SizedBox(
            height: 32.h,
          ),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '${context.l10n.notReadyAcc}. ',
                style: App.appStyle?.medium14?.copyWith(
                  color: App.appColor?.textColor,
                ),
              ),
              TextSpan(
                text: context.l10n.signUpNow,
                style: App.appStyle?.medium14?.copyWith(
                  color: App.appColor?.textColorPrimary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    SLIRouting.offAllNamed(AppPage.SIGN_UP);
                  },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state.error != null && state.error is FirebaseAuthException) {
          DialogUtil.error(
            context,
            title: context.l10n.error,
            content: (state.error as FirebaseAuthException).message ?? '',
            closeText: context.l10n.close,
            retryText: context.l10n.retry,
            isShowRetry: true,
            onTapRetry: () => _signInCubit?.sendCodeVerify(),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 430.0.w / 320.0.h,
              child: Assets.images.imgAds.image(
                fit: BoxFit.cover,
              ),
            ),
            _buildContent()
          ],
        ),
      ),
    );
  }
}
