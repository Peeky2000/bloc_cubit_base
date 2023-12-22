import 'package:flutter/widgets.dart';
import 'package:delivery_go/core/routing/default_transitions.dart';
import 'package:delivery_go/core/routing/sli_page_route.dart';

class SLIPage<T> extends Page<T> {
  final Widget page;
  final bool? popGesture;
  final Map<String, String>? parameters;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final bool? participatesInRootNavigator;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;
  final double Function(BuildContext context)? gestureWidth;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final bool fullscreenDialog;
  final bool preventDuplicates;
  @override
  final Object? arguments;
  @override
  final String name;
  final List<SLIPage> children;
  final SLIPage? unknownRoute;
  final bool showCupertinoParallax;
  final PathDecoded path;

  SLIPage({
    required this.name,
    required this.page,
    this.title,
    this.participatesInRootNavigator,
    this.gestureWidth,
    // RouteSettings settings,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameters,
    this.opaque = true,
    this.transitionDuration,
    this.popGesture,
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.children = const <SLIPage>[],
    this.unknownRoute,
    this.arguments,
    this.showCupertinoParallax = true,
    this.preventDuplicates = true,
  })  : path = _nameToRegex(name),
        assert(name.startsWith('/'),
            'It is necessary to start route name [$name] with a slash: /$name'),
        super(
          key: ValueKey(name),
          name: name,
          arguments: arguments,
        );

  @override
  Route<T> createRoute(BuildContext context) {
    return SLIPageRoute(
      page: page,
      transition: transition,
      curve: curve,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      customTransition: customTransition,
      popGesture: popGesture,
    );
  }

  static PathDecoded _nameToRegex(String path) {
    var keys = <String?>[];

    String _replace(Match pattern) {
      var buffer = StringBuffer('(?:');

      if (pattern[1] != null) buffer.write('.');
      buffer.write('([\\w%+-._~!\$&\'()*,;=:@]+))');
      if (pattern[3] != null) buffer.write('?');

      keys.add(pattern[2]);
      return "$buffer";
    }

    var stringPath = '$path/?'
        .replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), _replace)
        .replaceAll('//', '/');

    return PathDecoded(RegExp('^$stringPath\$'), keys);
  }
}

@immutable
class PathDecoded {
  final RegExp regex;
  final List<String?> keys;

  const PathDecoded(this.regex, this.keys);

  @override
  int get hashCode => regex.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PathDecoded &&
        other.regex == regex; // && listEquals(other.keys, keys);
  }
}
