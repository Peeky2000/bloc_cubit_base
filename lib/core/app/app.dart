import 'package:delivery_go/core/app/app_color.dart';
import 'package:delivery_go/core/app/app_style.dart';
import 'package:delivery_go/core/app/app_theme.dart';

class App {
  static AppStyle? _appStyle;
  static AppTheme? _theme;
  static AppColor? _appColor;

  static AppStyle? get appStyle => _appStyle;
  static AppTheme? get theme => _theme;
  static AppColor? get appColor => _appColor;

  static void init() {
    _appStyle = AppStyle();
    _theme = AppTheme();
    _appColor = AppColor();
  }
}
