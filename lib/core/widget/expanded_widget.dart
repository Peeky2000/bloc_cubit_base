import 'package:flutter/material.dart';
import 'package:sli_common/sli_common.dart' as sli;

@Deprecated('Use ExpandedWidget from package:sli_common/sli_common.dart.')
class ExpandedWidget extends StatelessWidget {
  final Widget? child;
  final bool expand;
  final Curve curve;
  final Axis axis;
  final Duration duration;

  const ExpandedWidget({
    super.key,
    this.expand = false,
    this.child,
    this.curve = Curves.easeInOut,
    this.axis = Axis.vertical,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) => sli.ExpandedWidget(
    expand: expand,
    curve: curve,
    axis: axis,
    duration: duration,
    child: child,
  );
}
