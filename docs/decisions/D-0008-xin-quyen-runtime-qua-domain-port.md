# D-0008: Xin quyền runtime qua domain port

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: permission,privacy
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Camera, vị trí, thông báo cần xin quyền lúc chạy. `sli_common` có
`PermissionUtil` dùng `permission_handler` nhưng nhận `BuildContext`, tự hiện
toast và dialog bên trong, không có bước giải thích, nên Cubit không dùng và
không test được. `permission_handler` 12.0.3 hiện chỉ là phụ thuộc gián tiếp
qua `sli_common`. Android chỉ biết "từ chối vĩnh viễn" qua kết quả của lần
xin; Google Play chỉ cho xin quyền đọc ảnh khi picker hệ thống không đủ.

## Quyết định

Port `PermissionRepo` (adapter `PermissionHandlerRepo` trên
`permission_handler: ^12.0.3`, thêm làm phụ thuộc trực tiếp) trả một
`PermissionAccess` cho mỗi lần gọi; UseCase `PermissionUseCase` map sang tập
đóng `PermissionDecision`; Cubit của tính năng phát effect có kiểu cho giải
thích, mở cài đặt và tiếp tục, và kiểm tra lại khi app quay lại.

- Phiên bản: `^12.0.3` trùng bản `sli_common` đang dùng nên không đổi build
  native. Lên `^13.0.2` (sửa `status` trên Android) cùng `sli_common`, khi
  app đặt `compileSdk 37` (Flutter 3.44 mặc định 36).
- `AppPermission{camera, location, notifications}`;
  `PermissionAccess{granted, limited, denied, permanentlyDenied, restricted}`;
  `PermissionDecision{proceed, showRationale, declined, openSettings,
  unavailable}`.
- Không có quyền ảnh: chọn ảnh dùng picker hệ thống (`image_picker`,
  D-0004), không khai báo `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` hay
  storage; chụp một ảnh bằng app camera hệ thống không khai báo `CAMERA`.
  Quyền cả thư viện ảnh cần quyết định riêng.
- Adapter: trên Android `status` không bao giờ trả `permanentlyDenied` (map
  về `denied`), chỉ kết quả `request()` quyết định; một request đang chạy
  cho mỗi quyền, các quyền khác xếp hàng; lỗi plugin thành `denied`.
- Native: chỉ khai báo quyền dùng thật: `<uses-permission>` (`CAMERA`,
  `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`),
  `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, macro
  Podfile `PERMISSION_CAMERA=1`, `PERMISSION_LOCATION_WHENINUSE=1`,
  `PERMISSION_NOTIFICATIONS=1` trong `GCC_PREPROCESSOR_DEFINITIONS`.
- Chỉ xin khi user chạm tính năng (kể cả thông báo); giải thích trong app
  với một nút "Tiếp tục" trước dialog hệ thống; từ chối thì tắt tính năng,
  không hỏi lại; vĩnh viễn thì mở cài đặt; kiểm tra lại ở `onAppResumed`;
  chạm đôi chỉ hỏi một lần.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `PermissionUtil` của `sli_common` | Cần `BuildContext`, tự hiện UI, không giải thích trước, không trả kết quả; giữ cho màn cũ |
| `permission_handler` ^13.0.2 ngay | Bắt `compileSdk 37` và AGP 9, lệch bản 12.x mà `sli_common` khoá; adapter đã bù hành vi `status` |
| Xin quyền trong từng plugin (`camera`, `geolocator`, `firebase_messaging`) | Mỗi plugin trả trạng thái và lỗi khác nhau, không có luồng giải thích và cài đặt thống nhất |
| Tự viết platform channel (`ActivityCompat`, `AVCaptureDevice`, `CLLocationManager`) | Tự duy trì code native hai nền tảng và các khác biệt theo phiên bản OS mà `permission_handler` đã xử lý |
| Quyền thư viện ảnh để chọn ảnh | Picker hệ thống không cần quyền; Google Play từ chối `READ_MEDIA_*` khi picker đủ dùng |
| Xin tất cả quyền khi mở app | Tỉ lệ từ chối cao, trái hướng dẫn Android và Apple HIG, trái tối thiểu dữ liệu |

## Hệ quả

- Mọi tính năng cần quyền dùng port và bảng quyết định này; chỉ khai báo quyền
  thật sự dùng trong manifest, `Info.plist` và macro Podfile.
- Thêm `permission_handler: ^12.0.3` vào `pubspec.yaml` khi tính năng đầu
  tiên cần quyền được duyệt.
- Hướng dẫn và cấu hình native: `.agents/skills/flutter-patterns/references/permission.md`.
- Code mẫu để chép (port, use case, Cubit, state, effect) và adapter
  `PermissionHandlerRepo` (đã chạy `flutter analyze` với 12.0.3 và 13.0.2):
  `test/patterns/permission_pattern_test.dart`.
- Test bảo vệ: cùng file, 12 test (map đủ mọi trạng thái, giải thích trước,
  từ chối, từ chối vĩnh viễn chỉ thấy khi xin trên Android, mở cài đặt rồi
  kiểm tra lại, bị thu hồi, bị hạn chế, chạm đôi, sau `close()`).

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Giữ `permission_handler` 12.x cho tới khi dự án nâng `compileSdk` lên 37 (yêu cầu của bản 13).
