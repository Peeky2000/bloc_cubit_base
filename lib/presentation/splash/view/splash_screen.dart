import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/mixin/after_layout.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/generated/assets.gen.dart';
import 'package:bloc_cubit_base/presentation/splash/cubit/splash_cubit.dart';

Widget splashScreenBuilder() => BlocProvider<SplashCubit>(
  create: (_) => Injector.getIt.get<SplashCubit>(),
  child: const SplashScreen(),
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with AfterLayoutMixin {
  SplashCubit? _splashCubit;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _splashCubit = context.read<SplashCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SplashCubit, SplashState>(
        listenWhen: (previous, current) => previous.effect != current.effect,
        listener: (_, state) {
          final effect = state.effect?.value;
          switch (effect) {
            case SplashNavigateSignInEffect():
              SLIRouting.offAllNamed(AppPage.signIn);
            case SplashNavigateHomeEffect():
              SLIRouting.offAllNamed(AppPage.home);
            case SplashNavigatePhoneVerificationEffect(:final phone):
              SLIRouting.offAllNamed(
                AppPage.confirmInfo,
                arguments: {'phone': phone, 'page_success': AppPage.home},
              );
            case SplashShowErrorEffect(:final error):
              handleErrorResponse(
                context,
                error,
                onRetry: () => _splashCubit!.sendCodeVerify(),
              );
            case null:
              break;
          }
        },
        child: Container(
          color: App.appColor?.primaryColor,
          alignment: Alignment.center,
          child: Assets.images.imgSplash.image(width: 250.w),
        ),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _splashCubit?.load();
  }
}
