// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ok => 'Ok';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String get sessionExpired => 'Your session has expired';

  @override
  String get noInternet =>
      'No internet connection found.\nPlease check your connection.';

  @override
  String get noInternetShort => 'No internet connection found.';

  @override
  String get connectionRestored => 'Connection restored';

  @override
  String get errGeneral => 'Something went wrong. Please try again';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get notification => 'Notification';

  @override
  String get confirm => 'Confirm';

  @override
  String get loadFail => 'Fail';

  @override
  String get loading => 'Loading...';

  @override
  String get noMoreData => 'No more data';

  @override
  String get password => 'Mật khẩu';

  @override
  String get email => 'Email';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get phoneNumber => 'Số điện thoại';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get rememberSignIn => 'Ghi nhớ đăng nhập';

  @override
  String get signInNowPerWord => 'Đăng Nhập Ngay';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get passIsRequired => 'Mật khẩu là bắt buộc';

  @override
  String get passIsInvalid => 'Mật khẩu không hợp lệ';

  @override
  String get confirmPassIsNotMath => 'Mật khẩu không trùng khớp';

  @override
  String get emailPhoneIsRequired => 'Email/Số điện thoại là bắt buộc';

  @override
  String get emailPhoneIsInvalid => 'Email/Số điện thoại không hợp lệ';

  @override
  String get shopNameIsRequired => 'Tên cửa hàng không được bỏ trống';
}
