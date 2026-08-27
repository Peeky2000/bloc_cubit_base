import 'package:flutter/material.dart';
import 'package:bloc_cubit_base/core/routing/default_transitions.dart';
import 'package:bloc_cubit_base/core/routing/sli_transaction_mixin.dart';

class SLIPageRoute<T> extends PageRoute<T> with SLIPageRouteTransitionMixin<T> {
  @override
  final Duration transitionDuration;
  final Widget page;
  final String? routeName;
  //final String reference;
  final CustomTransition? customTransition;
  final Map<String, String>? parameter;

  @override
  final bool showCupertinoParallax;

  @override
  final bool opaque;
  final bool? popGesture;

  @override
  final bool barrierDismissible;
  final Transition? transition;
  final Curve? curve;
  final Alignment? alignment;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  final String? title;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';

  @override
  final double Function(BuildContext context)? gestureWidth;

  SLIPageRoute({
    required this.page,
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.parameter,
    this.curve,
    this.alignment,
    this.transition,
    this.popGesture,
    this.customTransition,
    this.barrierDismissible = false,
    this.barrierColor,
    this.routeName,
    this.title,
    this.showCupertinoParallax = true,
    this.barrierLabel,
    this.maintainState = true,
    super.fullscreenDialog,
    this.gestureWidth,
  });

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final child = buildContent(context);
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
    return result;
  }

  @override
  Widget buildContent(BuildContext context) {
    return page;
  }
}
