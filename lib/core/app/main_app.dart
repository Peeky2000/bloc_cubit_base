import 'package:delivery_go/core/common/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/app/app_cubit/app_cubit.dart';
import 'package:delivery_go/core/common/route.dart';
import 'package:delivery_go/core/helper/network/network_checker.dart';
import 'package:delivery_go/core/routing/route_observer.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/core/routing/sli_page.dart';
import 'package:delivery_go/core/routing/sli_page_route.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:sli_common/l10n/arb/app_localizations.dart'
    as sliCommonLocalization;
import 'package:sli_common/sli_common.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  static SLIPageRoute<T> generator<T>(RouteSettings settings) {
    SLIPage page =
        AppPage.pages.firstWhere((element) => element.name == settings.name);
    return SLIPageRoute<T>(
      page: page.page,
      settings: settings,
      transitionDuration:
          page.transitionDuration ?? SLIRouting.defaultTransitionDuration,
      opaque: page.opaque,
      parameter: page.parameters,
      curve: page.curve,
      alignment: page.alignment,
      transition: page.transition,
      popGesture: page.popGesture,
      customTransition: page.customTransition,
      routeName: page.name,
      title: page.title,
      showCupertinoParallax: page.showCupertinoParallax,
      maintainState: page.maintainState,
      fullscreenDialog: page.fullscreenDialog,
      gestureWidth: page.gestureWidth,
    );
  }

  void _initDefault() {
    DialogUtil.defaultTitle =
        Injector.getIt.get<AppController>().context?.l10n.notification ?? '';
    DialogUtil.defaultTitleError =
        Injector.getIt.get<AppController>().context?.l10n.error ?? '';
    DialogUtil.confirmStyle = App.appStyle?.medium16?.copyWith(
      color: App.appColor?.secondary1,
    );
    DialogUtil.cancelStyle = App.appStyle?.medium16?.copyWith(
      color: Colors.black,
    );
    TitleWidget.defaultTitleStyle =
        App.appStyle?.medium24?.copyWith(color: App.appColor?.textColor);
    TitleWidget.defaultValueStyle =
        App.appStyle?.medium14?.copyWith(color: App.appColor?.secondary1);
    MoneyWidget.unitDefault = ' đ';

    CommonTextField.commonTextFieldStyle = CommonTextFieldStyle(
      titleStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColorLight,
      ),
      labelStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColor,
      ),
      hintStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColorLight,
      ),
      errorStyle: App.appStyle?.medium10?.copyWith(
        color: App.appColor?.redBase,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
      borderColor: App.appColor?.borderColor,
      enableBorderColor: App.appColor?.borderColor,
      disableBorderColor: App.appColor?.borderColor,
      focusedBorderColor: App.appColor?.primaryColor,
      focusedErrorBorderColor: App.appColor?.redBase,
      errorBorderColor: App.appColor?.redBase,
      borderRadius: kRadiusTextField,
      titlePadding: EdgeInsets.only(bottom: 12.h),
    );
    BaseField.baseFieldStyle = BaseFieldStyle(
      titleDefaultStyle:
          App.appStyle?.medium10?.copyWith(color: App.appColor?.textColorLight),
      valueDefaultStyle:
          App.appStyle?.medium14?.copyWith(color: App.appColor?.textColor),
    );

    CommonDropDown.commonDropDownStyle = CommonDropDownStyle(
      borderColor: App.appColor?.borderColor,
      disableBorderColor: App.appColor?.borderColor,
      errorBorderColor: App.appColor?.redBase,
      hintStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColorLight,
      ),
      titleStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColorLight,
      ),
      valueStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColor,
      ),
      errorStyle: App.appStyle?.medium10?.copyWith(
        color: App.appColor?.redBase,
      ),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
      titlePadding: EdgeInsets.only(bottom: 12.h),
      radius: kRadiusTextField,
    );
  }

  void _setupListen() {
    Injector.getIt
        .get<NetworkChecker>()
        .connectController
        .stream
        .listen((value) async {
      // if (!DialogUtil.isShowingDialog) {
      if (value) {
        await DialogUtil.showFlushBar(
            SLIRouting.key.currentContext!,
            Injector.getIt
                    .get<AppController>()
                    .context
                    ?.l10n
                    .connectionRestored ??
                '',
            iconFlushBar: const Icon(
              Icons.wifi_rounded,
              color: Colors.white,
            ));
      } else {
        await DialogUtil.showFlushBar(
            SLIRouting.key.currentContext!,
            Injector.getIt.get<AppController>().context?.l10n.noInternetShort ??
                '',
            backgroundColor: Colors.redAccent,
            iconFlushBar: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
            ));
      }
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, child) {
          App.init();
          bool isDarkMode = Injector.getIt.get<AppController>().isDarkMode;
          return BlocProvider<AppCubit>(
            create: (context) =>
                Injector.getIt.get<AppCubit>()..getCurrentLang(),
            child: BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                return MaterialApp(
                  builder: (context, widget) {
                    _initDefault();
                    _setupListen();
                    return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaleFactor: 1.0),
                        child: widget!);
                  },
                  debugShowCheckedModeBanner: false,
                  locale: state.locale,
                  title: 'Giaohang247',
                  theme: App.theme?.lightTheme,
                  darkTheme: App.theme?.darkTheme,
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  initialRoute: AppPage.SPLASH,
                  onGenerateRoute: (settings) => generator(settings),
                  navigatorKey: SLIRouting.key,
                  navigatorObservers: [
                    SLIRouteObserver(SLIRouting.routing),
                  ],
                  localizationsDelegates: const [
                    sliCommonLocalization.AppLocalizations.delegate,
                    AppLocalizations.delegate,
                    // ServerMessageLocalization.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
