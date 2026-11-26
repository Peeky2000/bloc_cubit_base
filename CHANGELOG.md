# Changelog

## Unreleased

- Nâng ràng buộc Dart SDK lên `^3.14.0` bằng `dart migrate`; dùng tham số
  khởi tạo private có tên của Dart 3.13 (`this._debug` mà người gọi vẫn truyền
  `debug:`) ở các lớp observability, network inspector, route observer và
  session interceptor; format lại theo formatter 3.14.
- Nâng mọi package lên bản mới nhất resolve được: `flutter_secure_storage` 11
  (app chỉ dùng mặc định AES-GCM của v10 nên token cũ vẫn đọc được),
  `vm_service` 15, `bloc` 9.2.2, `flutter_bloc` 9.1.2, `bloc_test` 10.0.1,
  `connectivity_plus` 7.3.2 và `pub upgrade` toàn bộ phụ thuộc gián tiếp.
  `sli_common` lên `shadcn_flutter` 0.0.55 và `another_flushbar` 2.
  `build_runner` giữ 2.16.1: 2.17.1 cần `build` 5 mà `injectable_generator`
  3.1.3 (mới nhất) chưa hỗ trợ.
- Nâng `alice` lên 2 (thông báo hệ thống tách khỏi gói, chụp request có sẵn
  redaction): import gộp về `package:alice/alice.dart`, bỏ `showNotification`.
  Kéo theo `equatable` 3, `open_file` thay `open_filex` (bỏ override),
  `share_plus` 13, `package_info_plus` 10, `sensors_plus` 7 và
  `permission_handler` 13 trong `sli_common`. Android đặt `compileSdk 37`;
  bỏ core library desugaring vì không còn `flutter_local_notifications`.
- Tinh gọn base theo ADR-0012: base giữ luật, hạ tầng và bộ kiểm định, không
  giữ màn mẫu để chép. Luồng mẫu còn splash → sign_in → home. Bỏ đăng ký, quên
  mật khẩu, xác minh số điện thoại (OTP Firebase, `firebase_auth`,
  `pin_code_fields`, `AppOtpField`), `LoadingListScreen` + `pull_to_refresh`,
  model shop/role/profile, `SuccessScreen`, `SelectionBottomSheet`, 14/18 file
  font Montserrat, 4 ảnh và 75 chuỗi l10n không dùng. ADR-0010 thành
  superseded.
- `test/patterns/` là bộ kiểm định: skill `flutter-patterns` sinh code từ
  reference, không chép file test.
- Icon dùng `SliIcons` (Lucide) từ `sli_common`; `sli_common` còn 20 export.
  `rulesVersion` 1.2.0.
- iOS chuyển sang Swift Package Manager, bỏ hẳn CocoaPods (`Podfile`,
  `Podfile.lock`, `pod install` trong fastlane). Firebase Apple SDK lên 13.
  `sli_common` nâng `fluttertoast` 10 và `device_info_plus` 12; app ghi đè
  `open_filex` 5 (qua `alice`) vì bản 4 chưa hỗ trợ SPM. Bỏ khối nâng
  compileSdk cho plugin cũ trong `android/build.gradle` vì `fluttertoast` 10
  đã dùng compileSdk 36.
- Nâng `firebase_core` lên 5 và `firebase_auth` lên 7 (Firebase BoM 5.0.0).
  API Dart dùng trong base không đổi; Android cần minSdk 24 (đã có).
- Nâng Flutter lên 3.50.1 (bản vá lỗi của 3.50; không đổi API).
- Nâng `connectivity_plus` lên 7 (chỉ đổi yêu cầu build Android: AGP
  8.12.1+, Gradle 8.13+, Kotlin 2.2+; repo đã đáp ứng).
- Nâng `pin_code_fields` lên 10 (`MaterialPinField`, chạy trên
  `material_ui`); `AppOtpField` bỏ lớp bọc `Material` cũ.
- Nâng lên Flutter 3.50.0 (Dart 3.14): Android lên AGP 9.3.1, Gradle 9.5.0,
  Kotlin 2.4.20, bỏ tự áp Kotlin plugin, bật lại `resValues`; iOS tối thiểu
  15.0, vẫn dùng CocoaPods; `injectable` 3.
- Chuyển app và `sli_common` sang `material_ui`/`cupertino_ui`; delegate
  l10n lấy từ `GlobalMaterialLocalizations.delegates`; `MainApp` bọc
  `MaterialUiCompatibilityBridge` cho package còn dùng Material cũ; ô OTP gộp
  thành `AppOtpField`. `rulesVersion` 1.1.0.
- Thêm bộ đo hiệu năng trên máy thật với dữ liệu thật: mở app, độ mượt, bộ
  nhớ, mạng, chẩn đoán widget chậm, chấm ba mức theo chuẩn, ngưỡng theo lượng
  dữ liệu và phân loại request lỗi theo bên phải xử lý.
- Migrate Android và iOS cho Flutter 3.44: Gradle 8.14, AGP 8.11, Kotlin 2.2,
  Java 17, minSdk 24; iOS giữ CocoaPods.
- Gộp vòng đời phiên vào `SessionRepo`; sửa lỗi đăng nhập không ghi nhớ thiếu
  token, `logout()` rỗng và tài khoản còn sót sau khi phiên hết hạn.
- `PhoneVerificationRepo.sendCode` trả về một kết quả thay cho ba callback.
- Thêm agent đo và sửa hiệu năng, lệnh `/perf-check`, `/perf-scenario`,
  `/security-audit`, `derry review plan`, tài liệu mẫu lưu trữ và mẫu luồng.
- Thêm bootstrap đa môi trường có kiểu rõ ràng và validation.
- Chuyển dependency injection sang `get_it + injectable` với constructor
  injection và cấu hình sinh mã.
- Thêm convention state: Cubit mặc định, vẫn hỗ trợ BLoC.
- Gia cố network inspection, session refresh, redaction, và token storage.
- Thay cây `sli_common` nhúng bằng Git submodule thật và thêm nền tảng toolkit
  ổn định có facade Shadcn.
- Thêm automation FVM/Derry/CI, architecture gates, tests, ADRs, guides, và
  đồng bộ hướng dẫn AI agent.
- Phân tách Derry thành build local, Firebase distribution và Store release;
  chuẩn hóa lại `build.sh` với dry-run, Store confirmation và Git tag opt-in.
- Thêm Dart Base CLI phía sau Derry cho `doctor/create/rename`, dry-run mặc
  định, validation trước mutation và test cho plan/apply guard.
- Thêm catalog `sli_common` với inventory 45/45 export, maturity status,
  showroom, BottomSheet pilot và golden preview có thể tái tạo.
- Hoàn tất Shadcn facade contract bằng semantics/touch-target tests và golden
  light/dark; nâng catalog lên 46/46 export.
- Thêm stable `showSliBottomSheet<T>` + `SliBottomSheetFrame`, migrate selection
  callers và giữ app-local API cũ dưới dạng adapter deprecated có parity test.
- Migrate `ExpandedWidget` app sang public `sli_common` qua adapter deprecated;
  khóa behavior mở/đóng hai trục và ghi matrix cho chín widget trùng còn lại.
- Bỏ tên artifact/key path `Giaohang247` khỏi Fastlane; Store lane dùng package
  và key path từ environment, fail sớm nếu thiếu key file.
- Đưa Firebase Phone Auth ra khỏi domain qua `PhoneVerificationRepo` và data
  adapter; chuyển DI annotation UseCase sang provider, thêm domain import gate
  và 8 regression tests cho callback/failure/stale request.
- Dọn 241 analyzer findings của toàn bộ `sli_common` và đưa full-package
  analyzer/test vào `derry quality` cùng CI; thêm lệnh `derry toolkit quality`.
- Thêm sáu skill quality Flutter/mobile cho review, performance, testing,
  security/privacy, lifecycle và release; bổ sung guide chọn skill cho agent
  và contributor, giữ eval trigger độc lập là follow-up rõ ràng.
- Gia cố session refresh: single-flight concurrent 401, token revision guard,
  cross-origin bearer protection, safe replay và coalesced terminal expiry.
- Thêm test network/session/token cho terminal và transient refresh failure,
  account race, multipart replay, retry 401/500, 403 và offline contract; full
  application suite hiện có 44 tests.
- Thêm typed session-expired flow từ data coordinator → AppCubit →
  `BlocListener`, cùng lifecycle-safe `NetworkChecker` có monitor seam và
  generated singleton disposal.
- Ghi future scope Version Health gồm Analytics, Crashlytics, Firebase
  Performance và Remote Config; không đưa VIPER vào base architecture.
- Tách năm Cubit auth/startup khỏi `BuildContext`, AppController, routing,
  dialog và l10n bằng typed `UiEffect`; thêm typed validation, pure error mapper,
  OTP lifecycle guard, architecture rule và nâng application suite lên 54 test.
- Hoàn tất Phase 3/4 với DI graph reset/dispose testable, generic typed failure
  trên `BaseAppState`, representative Cubit/BLoC lifecycle tests và nâng full
  application suite lên 62 test.
