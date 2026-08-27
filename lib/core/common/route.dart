import 'package:bloc_cubit_base/core/routing/sli_page.dart';
import 'package:bloc_cubit_base/presentation/confirm_information/view/confirm_information_screen.dart';
import 'package:bloc_cubit_base/presentation/home_page/view/home_page_screen.dart';
import 'package:bloc_cubit_base/presentation/reset_password/view/reset_password_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_up/view/sign_up_screen.dart';
import 'package:bloc_cubit_base/presentation/splash/view/splash_screen.dart';

class AppPage {
  static const String splash = '/';
  static const String signUp = '/sign_up';
  static const String signIn = '/sign_in';
  static const String resetPassword = '/reset_password';
  static const String confirmInfo = '/confirm_info';
  static const String home = '/home';

  static final List<SLIPage> pages = [
    SLIPage(name: splash, page: splashScreenBuilder()),
    SLIPage(name: signUp, page: signUpScreenBuilder()),
    SLIPage(name: signIn, page: signInScreenBuilder()),
    SLIPage(name: resetPassword, page: resetPasswordScreenBuilder()),
    SLIPage(name: confirmInfo, page: confirmInformationScreenBuilder()),
    SLIPage(name: home, page: homePageScreenBuilder()),
  ];
}
