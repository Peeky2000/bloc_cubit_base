import 'dart:async';

import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/app/app_controller.dart';
import 'package:bloc_cubit_base/core/app/app_cubit/app_cubit.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:bloc_cubit_base/core/routing/route_observer.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/core/routing/sli_page_route.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/core/widget/dialog_util.dart';
import 'package:bloc_cubit_base/core/widget/title_widget.dart';
import 'package:bloc_cubit_base/core/widget/money_widget.dart';
import 'package:bloc_cubit_base/core/widget/common_text_field.dart';
import 'package:bloc_cubit_base/core/widget/common_drop_down.dart';
import 'package:bloc_cubit_base/core/widget/base_field.dart';
import 'package:sli_common/sli_common.dart' show SliShadcnScope;

Widget buildMainApp() => MainApp(
  appCubit: Injector.getIt.get<AppCubit>(),
  appController: Injector.getIt.get<AppController>(),
  networkChecker: Injector.getIt.get<NetworkChecker>(),
);

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.appCubit,
    required this.appController,
    required this.networkChecker,
  });

  final AppCubit appCubit;
  final AppController appController;
  final NetworkChecker networkChecker;

  @override
  State<MainApp> createState() => _MainAppState();

  static SLIPageRoute<T> generator<T>(RouteSettings settings) {
    final page = AppPage.pages.firstWhere(
      (element) => element.name == settings.name,
    );
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
}

class _MainAppState extends State<MainApp> {
  StreamSubscription<bool>? _connectionSubscription;
  bool _appInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.appCubit.getCurrentLang();
    _connectionSubscription = widget.networkChecker.connectController.stream
        .listen(_showConnectionStatus);
  }

  void _initDefault() {
    DialogUtil.defaultTitle =
        widget.appController.context?.l10n.notification ?? '';
    DialogUtil.defaultTitleError =
        widget.appController.context?.l10n.error ?? '';
    DialogUtil.confirmStyle = App.appStyle?.medium16?.copyWith(
      color: App.appColor?.secondary1,
    );
    DialogUtil.cancelStyle = App.appStyle?.medium16?.copyWith(
      color: Colors.black,
    );
    TitleWidget.defaultTitleStyle = App.appStyle?.medium24?.copyWith(
      color: App.appColor?.textColor,
    );
    TitleWidget.defaultValueStyle = App.appStyle?.medium14?.copyWith(
      color: App.appColor?.secondary1,
    );
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
      titleDefaultStyle: App.appStyle?.medium10?.copyWith(
        color: App.appColor?.textColorLight,
      ),
      valueDefaultStyle: App.appStyle?.medium14?.copyWith(
        color: App.appColor?.textColor,
      ),
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

  Future<void> _showConnectionStatus(bool isConnected) async {
    final context = SLIRouting.key.currentContext;
    if (!mounted || context == null) {
      return;
    }
    DialogUtil.showFlushBar(
      context,
      isConnected
          ? context.l10n.connectionRestored
          : context.l10n.noInternetShort,
      backgroundColor: isConnected ? null : Colors.redAccent,
      iconFlushBar: Icon(
        isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_connectionSubscription?.cancel());
    super.dispose();
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
          if (!_appInitialized) {
            App.init();
            _appInitialized = true;
          }
          final isDarkMode = widget.appController.isDarkMode;
          return BlocProvider<AppCubit>.value(
            value: widget.appCubit,
            child: BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                return MaterialApp(
                  builder: (context, widget) {
                    _initDefault();
                    return SliShadcnScope(
                      child: MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: const TextScaler.linear(1)),
                        child: widget!,
                      ),
                    );
                  },
                  debugShowCheckedModeBanner: false,
                  locale: state.locale,
                  title: 'Flutter Base',
                  theme: App.theme?.lightTheme,
                  darkTheme: App.theme?.darkTheme,
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  initialRoute: AppPage.splash,
                  onGenerateRoute: (settings) => MainApp.generator(settings),
                  navigatorKey: SLIRouting.key,
                  navigatorObservers: [SLIRouteObserver(SLIRouting.routing)],
                  localizationsDelegates: [
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
