// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get ok => 'Ok';

  @override
  String get cancel => 'Hủy';

  @override
  String get error => 'Lỗi';

  @override
  String get sessionExpired => 'Phiên làm việc của bạn đã hết hạn';

  @override
  String get noInternet =>
      'Không tìm thấy kết nối Internet.\nVui lòng kiểm tra kết nối của bạn.';

  @override
  String get noInternetShort => 'Không tìm thấy kết nối Internet.';

  @override
  String get connectionRestored => 'Đã có lại kết nối';

  @override
  String get errGeneral => 'Có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get close => 'Đóng';

  @override
  String get retry => 'Thử lại';

  @override
  String get notification => 'Thông báo';

  @override
  String get confirm => 'Confirm';

  @override
  String get loadFail => 'Lỗi';

  @override
  String get loading => 'Đang tải...';

  @override
  String get noMoreData => 'Đã hết';

  @override
  String get password => 'Mật khẩu';

  @override
  String get email => 'Email';

  @override
  String get welcomeTitle => 'Chào mừng bạn';

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

  @override
  String get accountTitle => 'Tài khoản';

  @override
  String get accountRole => 'Vai trò';

  @override
  String get accountEmptyValue => 'Chưa có';

  @override
  String get logoutConfirm => 'Bạn có chắc muốn đăng xuất?';

  @override
  String get notificationTitle => 'Thông báo';

  @override
  String get notificationEmpty => 'Chưa có thông báo';

  @override
  String get notificationUnread => 'Chưa đọc';
}
