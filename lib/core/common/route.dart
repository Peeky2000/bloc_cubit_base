import 'package:delivery_go/core/routing/sli_page.dart';
import 'package:delivery_go/presentation/confirm_information/view/confirm_information_screen.dart';
import 'package:delivery_go/presentation/home_page/view/home_page_screen.dart';
import 'package:delivery_go/presentation/reset_password/view/reset_password_screen.dart';
import 'package:delivery_go/presentation/sign_in/view/sign_in_screen.dart';
import 'package:delivery_go/presentation/sign_up/view/sign_up_screen.dart';
import 'package:delivery_go/presentation/splash/view/splash_screen.dart';

class AppPage {
  static const String SPLASH = '/';
  static const String SIGN_UP = '/sign_up';
  static const String SIGN_IN = '/sign_in';
  static const String RESET_PASSWORD = '/reset_password';
  static const String CONFIRM_INFO = '/confirm_info';
  static const String HOME = '/home';

  static final List<SLIPage> pages = [
    SLIPage(name: SPLASH, page: splashScreenBuilder()),
    SLIPage(name: SIGN_UP, page: signUpScreenBuilder()),
    SLIPage(name: SIGN_IN, page: signInScreenBuilder()),
    SLIPage(name: RESET_PASSWORD, page: resetPasswordScreenBuilder()),
    SLIPage(name: CONFIRM_INFO, page: confirmInformationScreenBuilder()),
    SLIPage(name: HOME, page: homePageScreenBuilder()),
  ];
}
