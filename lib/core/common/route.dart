import 'package:bloc_cubit_base/core/routing/sli_page.dart';
import 'package:bloc_cubit_base/presentation/account/view/account_screen.dart';
import 'package:bloc_cubit_base/presentation/notification_list/view/notification_list_screen.dart';
import 'package:bloc_cubit_base/presentation/sign_in/view/sign_in_screen.dart';
import 'package:bloc_cubit_base/presentation/splash/view/splash_screen.dart';

class AppPage {
  static const String splash = '/';
  static const String signIn = '/sign_in';
  static const String home = '/home';
  static const String notificationList = '/notifications';

  static final List<SLIPage> pages = [
    SLIPage(name: splash, page: splashScreenBuilder()),
    SLIPage(name: signIn, page: signInScreenBuilder()),
    SLIPage(name: home, page: accountScreenBuilder()),
    SLIPage(name: notificationList, page: notificationListScreenBuilder()),
  ];
}
