import 'package:flutter/material.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';

extension BuildContextExtension on BuildContext {
  NavigatorState get navigator => Navigator.of(this);

  dynamic get arguments => SLIRouting.routing.args;
}
