import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired'**
  String get sessionExpired;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection found.\nPlease check your connection.'**
  String get noInternet;

  /// No description provided for @reconnectInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet connection has been.\nPlease click try again.'**
  String get reconnectInternet;

  /// No description provided for @noInternetShort.
  ///
  /// In en, this message translates to:
  /// **'No internet connection found.'**
  String get noInternetShort;

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get connectionRestored;

  /// No description provided for @systemBusy.
  ///
  /// In en, this message translates to:
  /// **'The system is busy.\nPlease try again later'**
  String get systemBusy;

  /// No description provided for @errGeneral.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get errGeneral;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Tiếp tục'**
  String get continueText;

  /// No description provided for @releaseToLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Release to load more'**
  String get releaseToLoadMore;

  /// No description provided for @loadFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get loadFail;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get noMoreData;

  /// No description provided for @pullUpLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Pull up to load more'**
  String get pullUpLoadMore;

  /// No description provided for @refreshCompleted.
  ///
  /// In en, this message translates to:
  /// **'Refresh completed'**
  String get refreshCompleted;

  /// No description provided for @refreshingText.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshingText;

  /// No description provided for @refreshFailedText.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailedText;

  /// No description provided for @idleRefreshText.
  ///
  /// In en, this message translates to:
  /// **'Pull down Refresh'**
  String get idleRefreshText;

  /// No description provided for @canRefreshText.
  ///
  /// In en, this message translates to:
  /// **'Release to refresh'**
  String get canRefreshText;

  /// No description provided for @canTwoLevelText.
  ///
  /// In en, this message translates to:
  /// **'Release to enter secondfloor'**
  String get canTwoLevelText;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @usernameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Tên đăng nhập không được để trống'**
  String get usernameIsRequired;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu không được để trống'**
  String get passwordIsRequired;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Xin chào, '**
  String get hello;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Tổng quan'**
  String get summary;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Lịch trình'**
  String get schedule;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Công việc'**
  String get task;

  /// No description provided for @salaryAndTax.
  ///
  /// In en, this message translates to:
  /// **'Lương & Thuế'**
  String get salaryAndTax;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Yêu cầu'**
  String get request;

  /// No description provided for @whichFoodForLunch.
  ///
  /// In en, this message translates to:
  /// **'Trưa nay ăn gì ?'**
  String get whichFoodForLunch;

  /// No description provided for @happyLunch.
  ///
  /// In en, this message translates to:
  /// **'Chúc bạn buổi trưa vui vẻ nhé :)'**
  String get happyLunch;

  /// No description provided for @cameraRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Bạn có cho phép ứng dụng truy cập camera không ?'**
  String get cameraRequestTitle;

  /// No description provided for @alignFlash.
  ///
  /// In en, this message translates to:
  /// **'Căn cho mã quét vào giữa ô vuông này nhé'**
  String get alignFlash;

  /// No description provided for @notHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get notHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Đăng ký'**
  String get signUp;

  /// No description provided for @welcomeToMySli.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Giaohang247'**
  String get welcomeToMySli;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgotPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get passwordConfirm;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Đã có tài khoản?'**
  String get alreadyHaveAccount;

  /// No description provided for @registerAccountSli.
  ///
  /// In en, this message translates to:
  /// **'Đăng ký tài khoản Giaohang247'**
  String get registerAccountSli;

  /// No description provided for @inputCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Nhập mã xác thực đã được gửi vào email'**
  String get inputCodeSentToEmail;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Xác thực tài khoản'**
  String get verifyAccount;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Xác thực'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Gửi lại mã xác thực'**
  String get resendCode;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email không được để trống'**
  String get emailIsRequired;

  /// No description provided for @passwordCfIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Xác nhận mật khẩu không được để trống'**
  String get passwordCfIsRequired;

  /// No description provided for @firstNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Tên không được để trống'**
  String get firstNameIsRequired;

  /// No description provided for @lastNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Họ không được để trống'**
  String get lastNameIsRequired;

  /// No description provided for @passwordIsNotEqual.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu không trùng khớp'**
  String get passwordIsNotEqual;

  /// No description provided for @scaleL1.
  ///
  /// In en, this message translates to:
  /// **'Không có nhu cầu thường xuyên'**
  String get scaleL1;

  /// No description provided for @scaleL2.
  ///
  /// In en, this message translates to:
  /// **'Dưới 150 đơn hàng/tháng'**
  String get scaleL2;

  /// No description provided for @scaleL3.
  ///
  /// In en, this message translates to:
  /// **'Từ 150 tới dưới 900 đơn hàng/tháng'**
  String get scaleL3;

  /// No description provided for @scaleL4.
  ///
  /// In en, this message translates to:
  /// **'Từ 900 đơn hàng/tháng đến dưới 3,000 đơn hàng/tháng'**
  String get scaleL4;

  /// No description provided for @scaleL5.
  ///
  /// In en, this message translates to:
  /// **'Từ 3,000 đơn hàng/tháng đến dưới 6,000 đơn hàng/tháng'**
  String get scaleL5;

  /// No description provided for @scaleL6.
  ///
  /// In en, this message translates to:
  /// **'Từ 6,000 đơn hàng/tháng'**
  String get scaleL6;

  /// No description provided for @fashion.
  ///
  /// In en, this message translates to:
  /// **'Thời trang'**
  String get fashion;

  /// No description provided for @cosmetics.
  ///
  /// In en, this message translates to:
  /// **'Mỹ phẩm'**
  String get cosmetics;

  /// No description provided for @interior.
  ///
  /// In en, this message translates to:
  /// **'Nội thất'**
  String get interior;

  /// No description provided for @motherAndBaby.
  ///
  /// In en, this message translates to:
  /// **'Mẹ và bé'**
  String get motherAndBaby;

  /// No description provided for @computers.
  ///
  /// In en, this message translates to:
  /// **'Máy tính, laptop'**
  String get computers;

  /// No description provided for @fragileGoods.
  ///
  /// In en, this message translates to:
  /// **'Hàng hóa dễ vỡ'**
  String get fragileGoods;

  /// No description provided for @householdElectrical.
  ///
  /// In en, this message translates to:
  /// **'Tivi và thiết bị điện gia dụng'**
  String get householdElectrical;

  /// No description provided for @houseware.
  ///
  /// In en, this message translates to:
  /// **'Đồ gia dụng'**
  String get houseware;

  /// No description provided for @motorcycles.
  ///
  /// In en, this message translates to:
  /// **'Xe máy và phương tiện giao thông'**
  String get motorcycles;

  /// No description provided for @drums.
  ///
  /// In en, this message translates to:
  /// **'Cây trống và vật tư nông nghiệp'**
  String get drums;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Thực phẩm, nông sản chế biến và đóng gói'**
  String get food;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Dụng cụ và phụ kiện thể thao, dã ngoại'**
  String get sports;

  /// No description provided for @jewelry.
  ///
  /// In en, this message translates to:
  /// **'Trang sức và phụ kiện thời trang'**
  String get jewelry;

  /// No description provided for @consumables.
  ///
  /// In en, this message translates to:
  /// **'Hàng tiêu dùng và tạp hóa'**
  String get consumables;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Sách và văn phòng phẩm'**
  String get books;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Khác'**
  String get other;

  /// No description provided for @welcomeToGiaohang247.
  ///
  /// In en, this message translates to:
  /// **'Chào mừng bạn đến với Giao Hàng 247'**
  String get welcomeToGiaohang247;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Số điện thoại'**
  String get phoneNumber;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Đăng ký ngay'**
  String get signUpNow;

  /// No description provided for @alreadyAcc.
  ///
  /// In en, this message translates to:
  /// **'Đã có tài khoản?'**
  String get alreadyAcc;

  /// No description provided for @signInNow.
  ///
  /// In en, this message translates to:
  /// **'Đăng nhập ngay'**
  String get signInNow;

  /// No description provided for @shippingScale.
  ///
  /// In en, this message translates to:
  /// **'Quy mô vận chuyển'**
  String get shippingScale;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Ngành hàng'**
  String get industry;

  /// No description provided for @shopInfo.
  ///
  /// In en, this message translates to:
  /// **'Thông tin cửa hàng'**
  String get shopInfo;

  /// No description provided for @giaohang247DuetYou.
  ///
  /// In en, this message translates to:
  /// **'Giao Hàng 247 luôn đồng hành cùng bạn'**
  String get giaohang247DuetYou;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Tên cửa hàng'**
  String get shopName;

  /// No description provided for @tos1.
  ///
  /// In en, this message translates to:
  /// **'Bằng việc nhấn “Xác nhận thông tin”, bạn đồng ý với'**
  String get tos1;

  /// No description provided for @tos2.
  ///
  /// In en, this message translates to:
  /// **'Điều khoản dịch vụ'**
  String get tos2;

  /// No description provided for @tos3.
  ///
  /// In en, this message translates to:
  /// **'Quy định Riêng tư cá nhân'**
  String get tos3;

  /// No description provided for @tos4.
  ///
  /// In en, this message translates to:
  /// **'của chúng tôi'**
  String get tos4;

  /// No description provided for @confirmInfo.
  ///
  /// In en, this message translates to:
  /// **'Xác nhận thông tin'**
  String get confirmInfo;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'và'**
  String get and;

  /// No description provided for @signUpNowPerWord.
  ///
  /// In en, this message translates to:
  /// **'Đăng Ký Ngay'**
  String get signUpNowPerWord;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Đăng nhập'**
  String get signIn;

  /// No description provided for @rememberSignIn.
  ///
  /// In en, this message translates to:
  /// **'Ghi nhớ đăng nhập'**
  String get rememberSignIn;

  /// No description provided for @notReadyAcc.
  ///
  /// In en, this message translates to:
  /// **'Chưa có tài khoản'**
  String get notReadyAcc;

  /// No description provided for @signInNowPerWord.
  ///
  /// In en, this message translates to:
  /// **'Đăng Nhập Ngay'**
  String get signInNowPerWord;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @pleaseTypePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Vui lòng nhập số điện thoại của bạn'**
  String get pleaseTypePhoneNumber;

  /// No description provided for @sendRequestSignIn.
  ///
  /// In en, this message translates to:
  /// **'Gửi Yêu Cầu Đăng Nhập'**
  String get sendRequestSignIn;

  /// No description provided for @confirmAccount.
  ///
  /// In en, this message translates to:
  /// **'Xác nhận tài khoản'**
  String get confirmAccount;

  /// No description provided for @confirmOTP.
  ///
  /// In en, this message translates to:
  /// **'Vui lòng xác nhập mã xác thực được gửi về số điện thoại {phone_number} của bạn'**
  String confirmOTP(Object phone_number);

  /// No description provided for @resendOTPAfter.
  ///
  /// In en, this message translates to:
  /// **'Gửi lại OTP sau {time}'**
  String resendOTPAfter(Object time);

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Đang kiểm tra'**
  String get verifying;

  /// No description provided for @dontReceivedOTP.
  ///
  /// In en, this message translates to:
  /// **'Không nhận được mã OTP'**
  String get dontReceivedOTP;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Gửi lại mã'**
  String get resendOTP;

  /// No description provided for @enterNewPass.
  ///
  /// In en, this message translates to:
  /// **'Nhập mật khẩu mới'**
  String get enterNewPass;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu mới'**
  String get newPassword;

  /// No description provided for @retypePassword.
  ///
  /// In en, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get retypePassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Xác Nhận Mật Khẩu'**
  String get confirmPassword;

  /// No description provided for @phoneIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Số điện thoại là bắt buộc'**
  String get phoneIsRequired;

  /// No description provided for @phoneIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Số điện thoại không hợp lệ'**
  String get phoneIsInvalid;

  /// No description provided for @passIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu là bắt buộc'**
  String get passIsRequired;

  /// No description provided for @passIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu không hợp lệ'**
  String get passIsInvalid;

  /// No description provided for @confirmPassIsNotMath.
  ///
  /// In en, this message translates to:
  /// **'Mật khẩu không trùng khớp'**
  String get confirmPassIsNotMath;

  /// No description provided for @emailPhoneIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email/Số điện thoại là bắt buộc'**
  String get emailPhoneIsRequired;

  /// No description provided for @emailPhoneIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email/Số điện thoại không hợp lệ'**
  String get emailPhoneIsInvalid;

  /// No description provided for @emailIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email không hợp lệ'**
  String get emailIsInvalid;

  /// No description provided for @shopNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Tên cửa hàng không được bỏ trống'**
  String get shopNameIsRequired;

  /// No description provided for @industryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Ngành hàng không được bỏ trống'**
  String get industryIsRequired;

  /// No description provided for @scaleLevelIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Quy mô vận chuyển không được bỏ trống'**
  String get scaleLevelIsRequired;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Đăng ký thành công'**
  String get signupSuccess;

  /// No description provided for @noteSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'GIAOHANG247 luôn đồng hành cùng bạn'**
  String get noteSignupSuccess;

  /// No description provided for @verifyPhoneSuccess.
  ///
  /// In en, this message translates to:
  /// **'Xác thực số điện thoại thành công'**
  String get verifyPhoneSuccess;

  /// No description provided for @resetPassSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cập nhật mật khẩu thành công.\nVui lòng đăng nhập lại'**
  String get resetPassSuccess;

  /// No description provided for @failOTP.
  ///
  /// In en, this message translates to:
  /// **'Mã OTP không hợp lệ.\nVui lòng thử lại.'**
  String get failOTP;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
