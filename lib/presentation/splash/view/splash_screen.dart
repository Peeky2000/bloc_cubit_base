import 'package:mOrder/core/app/app.dart';
import 'package:mOrder/core/common/route.dart';
import 'package:mOrder/core/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mOrder/core/mixin/after_layout.dart';
import 'package:mOrder/di/injection.dart';
import 'package:mOrder/generated/assets.gen.dart';
import 'package:mOrder/presentation/splash/cubit/splash_cubit.dart';

Widget splashScreenBuilder() => BlocProvider<SplashCubit>(
      create: (_) => Injector.getIt.get<SplashCubit>(),
      child: const SplashScreen(),
    );

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
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
  void dispose() {
    _splashCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SplashCubit, SplashState>(
        listener: (_, state) {
          switch (state.isLogin) {
            case true:
              if (state.isPhoneVerified) {
                SLIRouting.offAllNamed(AppPage.HOME);
              } else {
                _splashCubit?.sendCodeVerify();
              }
              break;
            case false:
              SLIRouting.offAllNamed(AppPage.SIGN_IN);
              break;
            default:
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
