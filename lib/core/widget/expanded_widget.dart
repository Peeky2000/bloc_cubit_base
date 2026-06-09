import 'package:flutter/material.dart';

class ExpandedWidget extends StatefulWidget {
  final Widget? child;
  final bool expand;
  final Curve curve;
  final Axis axis;
  final Duration duration;

  const ExpandedWidget({
    Key? key,
    this.expand = false,
    this.child,
    this.curve = Curves.easeInOut,
    this.axis = Axis.vertical,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _ExpandedWidgetState createState() => _ExpandedWidgetState();
}

class _ExpandedWidgetState extends State<ExpandedWidget> with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(vsync: this, duration: widget.duration);
    animation = CurvedAnimation(
      parent: expandController,
      curve: widget.curve,
    );
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(ExpandedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: 1.0,
      sizeFactor: animation,
      axis: widget.axis,
      child: widget.child,
    );
  }
}
