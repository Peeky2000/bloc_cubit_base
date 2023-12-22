import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:delivery_go/core/routing/sli_bottomsheet.dart';
import 'package:delivery_go/core/routing/sli_page_route.dart';

String? _extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }

  if (route is SLIPageRoute) {
    return route.routeName;
  }

  if (route is SLIModalBottomSheetRoute) {
    return 'BOTTOMSHEET ${route.hashCode}';
  }

  return null;
}

class SLIRouteObserver extends NavigatorObserver {
  final RoutingCache? _routeSend;

  SLIRouteObserver(this._routeSend);

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRoute = _RouteData.ofRoute(route);
    final newRoute = _RouteData.ofRoute(previousRoute);

    if (currentRoute.isBottomSheet) {
      log('CLOSE ${currentRoute.name}', name: 'Giaohang247');
    } else if (currentRoute.isGetPageRoute) {
      log('CLOSE TO ROUTE ${currentRoute.name}', name: 'Giaohang247');
    }

    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (previousRoute is PageRoute) {
        value.current = _extractRouteName(previousRoute) ?? '';
        value.previous = newRoute.name ?? '';
      } else if (value.previous.isNotEmpty) {
        value.current = value.previous;
      }

      value.args = previousRoute?.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
      value.isBottomSheet = newRoute.isBottomSheet;
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = _RouteData.ofRoute(route);

    if (newRoute.isBottomSheet) {
      log('OPEN ${newRoute.name}', name: 'Giaohang247');
    } else if (newRoute.isGetPageRoute) {
      log('GOING TO ROUTE ${newRoute.name}', name: 'Giaohang247');
    }

    _routeSend?.update((value) {
      if (route is PageRoute) {
        value.current = newRoute.name ?? '';
      }
      final previousRouteName = _extractRouteName(previousRoute);
      if (previousRouteName != null) {
        value.previous = previousRouteName;
      }

      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
      value.isBottomSheet =
          newRoute.isBottomSheet ? true : value.isBottomSheet ?? false;
    });
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = _extractRouteName(route);
    final currentRoute = _RouteData.ofRoute(route);

    log('REMOVING ROUTE $routeName', name: 'Giaohang247');

    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = routeName ?? '';
      value.previous = routeName ?? '';
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
    });
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = _extractRouteName(newRoute);
    final oldName = _extractRouteName(oldRoute);
    final currentRoute = _RouteData.ofRoute(oldRoute);

    log('REPLACE ROUTE $oldName', name: 'Giaohang247');
    log('NEW ROUTE $newName', name: 'Giaohang247');

    _routeSend?.update((value) {
      if (newRoute is PageRoute) {
        value.current = newName ?? '';
      }

      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = '$oldName';
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
    });
  }
}

class RoutingCache {
  String current;
  String previous;
  dynamic args;
  String removed;
  Route<dynamic>? route;
  bool? isBack;
  bool? isBottomSheet;

  RoutingCache({
    this.current = '',
    this.previous = '',
    this.args,
    this.removed = '',
    this.route,
    this.isBack,
    this.isBottomSheet,
  });

  void update(void Function(RoutingCache value) fn) {
    fn(this);
  }
}

class _RouteData {
  final bool isGetPageRoute;

  //final bool isSnackbar;
  final bool isBottomSheet;
  final String? name;

  _RouteData({
    required this.name,
    required this.isGetPageRoute,
    // required this.isSnackbar,
    required this.isBottomSheet,
  });

  factory _RouteData.ofRoute(Route? route) {
    return _RouteData(
      name: _extractRouteName(route),
      isGetPageRoute: route is SLIPageRoute,
      // isSnackbar: route is SnackRoute,
      isBottomSheet: route is SLIModalBottomSheetRoute,
    );
  }
}
