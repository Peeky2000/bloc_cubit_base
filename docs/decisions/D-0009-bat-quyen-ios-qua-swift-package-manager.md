# D-0009: Bật quyền iOS qua Swift Package Manager

- Trạng thái: accepted
- Ngày: 2026-11-25
- Phạm vi: feature
- Tags: permission,privacy,ios,spm
- Tính năng: 
- Thay thế: D-0008
- Bị thay bởi:

## Bối cảnh

D-0008 chọn port `PermissionRepo` trên `permission_handler` và bật từng quyền
iOS bằng macro `PERMISSION_*=1` trong `post_install` của `ios/Podfile`. Từ
commit `0f0abdb` (2026-11-25) app build iOS bằng Swift Package Manager và không
còn `Podfile`, vì CocoaPods trunk chỉ đọc từ 2026-12-02 và Flutter 3.50 cảnh
báo khi tắt SPM. Dòng macro Podfile trong D-0008 vì thế không làm được nữa.

`permission_handler: 12.0.3` (qua `sli_common`) dùng `permission_handler_apple`
9.6.5. Trên SPM, `Package.swift` của gói này đặt macro khi đánh giá manifest:
quyền được bật nếu biến môi trường `PERMISSION_*` khác `0`, nếu không thì khi
`Info.plist` của app có key mô tả tương ứng; `PERMISSION_NOTIFICATIONS` và
`PERMISSION_CRITICAL_ALERTS` mặc định bật. Manifest tìm app từ thư mục chạy
build, nên build mở từ Xcode.app không tự thấy app. Bản 9.6.0 thêm
`permission_handler.yaml` và lệnh `select` để mỗi flavor có bộ quyền riêng.
Ba flavor `dev`, `staging`, `prod` hiện dùng chung `ios/Runner/Info.plist`.

## Quyết định

Giữ toàn bộ D-0008 (port, adapter, `PermissionDecision`, luồng giải thích, phiên
bản, quyền Android, không xin quyền ảnh), chỉ thay cách bật quyền iOS: một quyền
được compile vào app khi và chỉ khi `ios/Runner/Info.plist` có key mô tả của nó;
không dùng macro Podfile, không đặt biến môi trường `PERMISSION_*`.

| `AppPermission` | Key trong `ios/Runner/Info.plist` | Macro được bật |
|---|---|---|
| `camera` | `NSCameraUsageDescription` | `PERMISSION_CAMERA` |
| `location` | `NSLocationWhenInUseUsageDescription` | `PERMISSION_LOCATION_WHENINUSE` |
| `notifications` | không có key | `PERMISSION_NOTIFICATIONS` (mặc định bật) |

- Chuỗi mô tả là câu đầy đủ, nói rõ dùng để làm gì, lấy từ người giữ l10n
  ("App dùng camera để quét hoá đơn."). Không thêm key cho quyền chưa dùng:
  key thừa vừa bật quyền trong binary vừa bị App Review hỏi.
- Thêm hoặc xoá một key: xoá DerivedData một lần
  (`rm -rf ~/Library/Developer/Xcode/DerivedData`) rồi build lại, vì Xcode
  không tự đánh giá lại manifest.
- Build bằng `flutter build ios`, `flutter run` hoặc fastlane (đều chạy từ thư
  mục app). Build mở trực tiếp từ Xcode.app phải đặt
  `PERMISSION_HANDLER_INFO_PLIST` trỏ tới `ios/Runner/Info.plist`, nếu không
  mọi quyền bị compile out.
- Không dùng `permission_handler.yaml` khi các flavor còn dùng chung
  `Info.plist`. Khi một flavor cần ít quyền hơn, tạo quyết định mới cho nó.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Giữ CocoaPods để còn macro Podfile | CocoaPods trunk chỉ đọc từ 2026-12-02, Flutter sắp bỏ tuỳ chọn tắt SPM; app đã bỏ CocoaPods |
| Đặt biến môi trường `PERMISSION_*` (`launchctl setenv`, CI) | Nằm ngoài repo, mỗi máy và CI phải đặt giống nhau; quên một biến là quyền im lặng biến mất |
| `permission_handler.yaml` + `select <flavor>` ngay bây giờ | Ba flavor chung một `Info.plist` nên không có gì để tách; thêm bước `select` trước mỗi build và một build phase kiểm tra |
| Lên `permission_handler` 13 cùng đợt | Bắt `compileSdk 37`, lệch bản 12.x mà `sli_common` khoá; không cần cho việc bật quyền trên SPM |

## Hệ quả

- Mọi tính năng cần quyền vẫn theo port và bảng quyết định của D-0008; phần
  iOS bật quyền bằng key `Info.plist` theo bảng trên.
- Hướng dẫn và cấu hình native:
  `.agents/skills/flutter-patterns/references/permission.md` (đã viết theo
  cách này từ commit `0f0abdb`).
- Code mẫu và test giữ nguyên: `test/patterns/permission_pattern_test.dart`
  (port, use case, Cubit, adapter `PermissionHandlerRepo`); không phụ thuộc
  cách build native.
- Chưa có test tự động kiểm quyền bị compile out. Kiểm bằng tay trên máy thật
  khi tính năng đầu tiên cần quyền được làm: dialog hệ thống phải hiện ở lần
  xin đầu.
- D-0008 chuyển `superseded`; `permission.md`, `SKILL.md` của
  `flutter-patterns` và `permission_pattern_test.dart` trỏ sang D-0009.

## Duyệt

PM chấp nhận ngày 2026-11-25. Phần port, luồng xin quyền, phiên bản và quyền
Android vẫn theo D-0008; chỉ phần bật quyền iOS theo quyết định này.
