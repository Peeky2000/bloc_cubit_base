import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';

@singleton
class AppController {
  BuildContext? get context => SLIRouting.key.currentContext;

  bool get isDarkMode => (theme.brightness == Brightness.dark);

  ThemeData get theme {
    var theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }
}
