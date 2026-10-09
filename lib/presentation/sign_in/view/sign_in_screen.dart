import 'package:sli_common/sli_common.dart' show CommonTextField, SliSpacing;
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/generated/assets.gen.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/widget/app_primary_button.dart';
import 'package:bloc_cubit_base/widget/loading_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/mixin/after_layout.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget signInScreenBuilder() => BlocProvider<SignInCubit>(
  create: (_) => Injector.getIt.get<SignInCubit>(),
  child: const SignInScreen(),
);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
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
    _usernameTextController.dispose();
    _passTextController.dispose();
    super.dispose();
  }

  Widget _buildOption() {
    return Row(
      children: [
        BlocBuilder<SignInCubit, SignInState>(
          builder: (context, state) {
            return RadioGroup<bool>(
              groupValue: state.isRememberLogin ? true : null,
              onChanged: (_) => _signInCubit?.onChangeRememberLogin(),
              child: Radio<bool>(
                value: true,
                activeColor: App.appColor?.primaryColor,
                toggleable: true,
              ),
            );
          },
        ),
        InkWell(
          onTap: () => _signInCubit?.onChangeRememberLogin(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SliSpacing.sm),
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
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(SliSpacing.xxl),
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
            padding: EdgeInsets.only(
              top: SliSpacing.lg,
              bottom: SliSpacing.xxl,
            ),
            child: Text(
              context.l10n.welcomeTitle,
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
                error: _usernameError(context, state.usernameError),
              );
            },
          ),
          SizedBox(height: SliSpacing.lg),
          BlocBuilder<SignInCubit, SignInState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _passTextController,
                title: context.l10n.password,
                hint: context.l10n.password,
                keyboardType: TextInputType.visiblePassword,
                error: _passwordError(context, state.passwordError),
                obscureText: !(_signInCubit?.state.showPass ?? false),
                suffixConstraints: BoxConstraints.tightFor(
                  width: 44.w,
                  height: 20.w,
                ),
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
          SizedBox(height: SliSpacing.xxl),
          _buildOption(),
          SizedBox(height: SliSpacing.xxl),
          AppPrimaryButton(
            title: context.l10n.signInNowPerWord,
            onTap: () {
              String username = _usernameTextController.text.trim();
              String pass = _passTextController.text.trim();
              _signInCubit?.onTapSignIn(username: username, pass: pass);
            },
          ),
          SizedBox(height: SliSpacing.xxl),
          Text.rich(
            TextSpan(
              children: [
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
                      SLIRouting.offAllNamed(AppPage.signUp);
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<SignInCubit, SignInState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final effect = state.effect?.value;
        switch (effect) {
          case SignInNavigateHomeEffect():
            SLIRouting.offAllNamed(AppPage.home);
          case SignInNavigateForgotPasswordEffect():
            SLIRouting.toNamed(AppPage.resetPassword);
          case SignInNavigatePhoneVerificationEffect(:final phone):
            SLIRouting.offAllNamed(
              AppPage.confirmInfo,
              arguments: {'phone': phone, 'page_success': AppPage.home},
            );
          case SignInShowErrorEffect(:final error, :final retryAction):
            handleErrorResponse(
              context,
              error,
              onRetry: () => switch (retryAction) {
                SignInRetryAction.signIn => _signInCubit!.onTapSignIn(
                  username: _usernameTextController.text.trim(),
                  pass: _passTextController.text.trim(),
                ),
                SignInRetryAction.sendVerificationCode =>
                  _signInCubit!.sendCodeVerify(),
              },
            );
          case null:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        body: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 430.0.w / 320.0.h,
              child: Assets.images.imgAds.image(fit: BoxFit.cover),
            ),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  String? _usernameError(BuildContext context, EmailOrPhoneInputError? error) =>
      switch (error) {
        EmailOrPhoneInputError.required => context.l10n.emailPhoneIsRequired,
        EmailOrPhoneInputError.invalid => context.l10n.emailPhoneIsInvalid,
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
