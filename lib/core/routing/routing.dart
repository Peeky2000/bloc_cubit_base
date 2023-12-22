import 'dart:io';

import 'package:flutter/material.dart';
import 'package:delivery_go/core/routing/default_transitions.dart';
import 'package:delivery_go/core/routing/route_observer.dart';
import 'package:delivery_go/core/routing/sli_bottomsheet.dart';
import 'package:delivery_go/core/routing/sli_page_route.dart';

class SLIRouting {
  static Transition? defaultTransition;
  static Duration defaultTransitionDuration = const Duration(milliseconds: 300);
  static final _key =
      GlobalKey<NavigatorState>(debugLabel: 'Key Created by default');

  static GlobalKey<NavigatorState> get key => _key;
  static RoutingCache routing = RoutingCache();

  static String get currentRoute => routing.current;

  static BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((element) {
      overlay = element;
    });
    return overlay;
  }

  static String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    /// uncommonent for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  static Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    double? elevation,
    bool persistent = true,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
    bool? ignoreSafeArea,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? settings,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
  }) {
    return Navigator.of(overlayContext!, rootNavigator: useRootNavigator)
        .push(SLIModalBottomSheetRoute<T>(
      builder: (_) => bottomsheet,
      isPersistent: persistent,
      // theme: Theme.of(key.currentContext, shadowThemeOnly: true),
      theme: Theme.of(key.currentContext!),
      isScrollControlled: isScrollControlled,

      barrierLabel: MaterialLocalizations.of(key.currentContext!)
          .modalBarrierDismissLabel,

      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      removeTop: ignoreSafeArea ?? true,
      clipBehavior: clipBehavior,
      isDismissible: isDismissible,
      modalBarrierColor: barrierColor,
      settings: settings,
      enableDrag: enableDrag,
      enterBottomSheetDuration:
          enterBottomSheetDuration ?? const Duration(milliseconds: 250),
      exitBottomSheetDuration:
          exitBottomSheetDuration ?? const Duration(milliseconds: 200),
    ));
  }

  static Future<T?>? to<T>(
    Widget page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    bool preventDuplicates = true,
    bool? popGesture,
    double Function(BuildContext context)? gestureWidth,
  }) {
    // var routeName = "/${page.runtimeType}";
    routeName ??= "/${page.runtimeType}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return key.currentState?.push<T>(
      SLIPageRoute<T>(
        opaque: opaque ?? true,
        page: page,
        routeName: routeName,
        gestureWidth: gestureWidth,
        settings: RouteSettings(
          name: routeName,
          arguments: arguments,
        ),
        popGesture: popGesture ?? Platform.isIOS,
        transition: transition ?? defaultTransition,
        curve: curve ?? Curves.easeOutQuad,
        fullscreenDialog: fullscreenDialog,
        transitionDuration: duration ?? defaultTransitionDuration,
      ),
    );
  }

  static Future<T?>? toNamed<T>(
    String page, {
    dynamic arguments,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (preventDuplicates && page == currentRoute) {
      return null;
    }

    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return key.currentState?.pushNamed<T>(
      page,
      arguments: arguments,
    );
  }

  static Future<T?>? offNamed<T>(
    String page, {
    dynamic arguments,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (preventDuplicates && page == currentRoute) {
      return null;
    }

    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return key.currentState?.pushReplacementNamed(
      page,
      arguments: arguments,
    );
  }

  static void until(RoutePredicate predicate) {
    // if (key.currentState.mounted) // add this if appear problems on future with route navigate
    // when widget don't mounted
    return key.currentState?.popUntil(predicate);
  }

  static Future<T?>? offUntil<T>(Route<T> page, RoutePredicate predicate) {
    // if (key.currentState.mounted) // add this if appear problems on future with route navigate
    // when widget don't mounted
    return key.currentState?.pushAndRemoveUntil<T>(page, predicate);
  }

  Future<T?>? offNamedUntil<T>(
    String page,
    RoutePredicate predicate, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return key.currentState?.pushNamedAndRemoveUntil<T>(
      page,
      predicate,
      arguments: arguments,
    );
  }

  /// The `offNamed()` pop a page, and goes to the next. The
  /// `offAndToNamed()` goes to the next page, and removes the previous one.
  /// The route transition animation is different.
  static Future<T?>? offAndToNamed<T>(
    String page, {
    dynamic arguments,
    dynamic result,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return key.currentState?.popAndPushNamed(
      page,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?>? offAllNamed<T>(
    String newRouteName, {
    RoutePredicate? predicate,
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return key.currentState?.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate ?? (_) => false,
      arguments: arguments,
    );
  }

  static void removeRoute(Route<dynamic> route) {
    return key.currentState?.removeRoute(route);
  }

  static void back<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
  }) {
    if (canPop) {
      if (key.currentState?.canPop() == true) {
        key.currentState?.pop<T>(result);
      }
    } else {
      key.currentState?.pop<T>(result);
    }
  }

  static void close(int times) {
    if (times < 1) {
      times = 1;
    }
    var count = 0;
    var back = key.currentState?.popUntil((route) => count++ == times);

    return back;
  }

  static Future<T?>? off<T>(
    Widget page, {
    bool opaque = false,
    Transition? transition,
    Curve? curve,
    bool? popGesture,
    String? routeName,
    dynamic arguments,
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return key.currentState?.pushReplacement(SLIPageRoute(
        opaque: opaque,
        gestureWidth: gestureWidth,
        page: page,
        settings: RouteSettings(
          arguments: arguments,
          name: routeName,
        ),
        routeName: routeName,
        fullscreenDialog: fullscreenDialog,
        popGesture: popGesture ?? Platform.isIOS,
        transition: transition ?? defaultTransition,
        curve: curve ?? Curves.easeOutQuad,
        transitionDuration: duration ?? defaultTransitionDuration));
  }

  static Future<T?>? offAll<T>(
    Widget page, {
    RoutePredicate? predicate,
    bool opaque = false,
    bool? popGesture,
    String? routeName,
    dynamic arguments,
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    return key.currentState?.pushAndRemoveUntil<T>(
        SLIPageRoute<T>(
          opaque: opaque,
          popGesture: popGesture ?? Platform.isIOS,
          page: page,
          gestureWidth: gestureWidth,
          settings: RouteSettings(
            name: routeName,
            arguments: arguments,
          ),
          fullscreenDialog: fullscreenDialog,
          routeName: routeName,
          transition: transition ?? defaultTransition,
          curve: curve ?? Curves.easeOutQuad,
          transitionDuration: duration ?? defaultTransitionDuration,
        ),
        predicate ?? (route) => false);
  }
}
