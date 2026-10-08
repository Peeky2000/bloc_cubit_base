# D-0007: Push notification qua domain port

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: push,notification
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

App cần báo cho user khi app đóng hoặc ở nền. `optional-capabilities.md` hoãn
Firebase Messaging tới khi có hợp đồng thông báo và điều hướng. Base đã có
`firebase_core` 3.x; `flutter_local_notifications` chỉ là phụ thuộc gián tiếp
qua `alice`. Rủi ro chính: token của user cũ vẫn nhận push sau khi đăng xuất,
payload chứa dữ liệu cá nhân, và thao tác từ thông báo tự thực hiện hành động.

## Quyết định

Port `PushRepo` cung cấp quyền, token, token đổi mới và một
`Stream<PushEvent>`; adapter trên `firebase_messaging` ^16.7.0, kéo theo nâng
`firebase_core` lên ^4.15.0 và `firebase_auth` lên ^6.7.0; `PushUseCase` sở
hữu việc đăng ký thiết bị gắn với phiên; `PushCubit` cấp app biến message lúc
foreground thành effect banner và thao tác chạm thành link đi qua parser deep
link.

- Phiên bản: `firebase_messaging` ^16.7.0 vì app đã dùng
  `FlutterSceneDelegate` (UIScene, hỗ trợ từ 16.1.0, có
  `configureNotificationCenterDelegate()`) và 16.7.0 có `deniedPermanently`
  trên Android. 16.7.0 cần `firebase_core` ^4.14.0; với core 3.6.0 chỉ
  15.1.3 giải được. Core 4 cần iOS 15.0, Firebase iOS SDK 12, Android BoM 34;
  `lib/` analyze sạch với core 4.15.0 + auth 6.7.0. Nâng cấp là commit riêng.
- `flutter_local_notifications` ^19.5.0 thêm trực tiếp, chỉ để tạo kênh
  Android `default_channel` (importance high) và `cancelAll()`; không gọi
  `initialize`. 22.x chờ nâng `alice` (`alice ^1.0.0` khoá ^19.4.0).
- Background handler top-level `@pragma('vm:entry-point')`, đăng ký trước
  `runApp`, gọi `Firebase.initializeApp()`, không DI, không UI, dưới 30 giây.
- Payload luôn là notification message có `data{id, type, link}`; data-only
  cần quyết định riêng (không tới app iOS đã tắt hoặc app Android bị
  force-stop, iOS giới hạn 2–3/giờ). `type` lạ thành `PushType.unknown`.
- `onSignedIn()` sau `SessionRepo.start` và mỗi lần mở app có phiên: đăng ký
  token và token xoay vòng (iOS: token tới sau APNs qua `tokenRefreshes`).
  `onSignedOut()` trước `SessionRepo.end()`: huỷ đăng ký trên server, rồi
  luôn `deleteToken()` và xoá thông báo trong khay; revision hoàn tác đăng ký
  về muộn; lỗi push không chặn đăng nhập hay đăng xuất.
- Chạm có link gọi `DeepLinkCubit.openUri`; bỏ chạm trùng `id`. Xin quyền
  sau giải thích trong app, đúng lúc cần, không lúc mở app; kiểm lại khi
  resume.
- Native: `default_notification_channel_id`, `default_notification_icon`,
  `default_notification_color` trong `AndroidManifest.xml`; Push
  Notifications + Background Modes (Remote notifications) trên Xcode; key
  APNs .p8 trên Firebase; gọi `configureNotificationCenterDelegate()` trong
  `AppDelegate`.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `firebase_messaging` 15.1.3 giữ `firebase_core` 3.6 | Không hỗ trợ UIScene trong khi app đã dùng `FlutterSceneDelegate` (chạm thông báo, `getInitialMessage` có thể hỏng); dòng 15.x ngừng từ 14 tháng trước |
| `flutter_local_notifications` 22.x | Xung đột với `alice ^1.0.0` (khoá ^19.4.0); alice mới hơn cần Dart 3.13 hoặc `permission_handler` 13 |
| Hiển thị lại message foreground bằng local notification | Thêm `initialize` và delegate iOS tranh với FCM; banner trong app đủ và không trùng |
| Data-only message cho mọi loại | Không tới app đã tắt trên iOS / force-stop trên Android, bị throttle và hạ ưu tiên |
| Đăng ký theo Firebase Installation ID (`register()`/`onRegistered`) | Firebase docs gọi token là deprecated, nhưng API FlutterFire mới merge (PR #18482, 2026-09-25), chưa phát hành; server vẫn nhận token; port giữ `getToken` là địa chỉ mờ để đổi sau |
| OneSignal | Dịch vụ thứ ba thêm dữ liệu ra ngoài; Firebase đã có trong project |
| APNs/FCM HTTP trực tiếp qua platform channel | Tự duy trì code native hai nền tảng |
| Chỉ `flutter_local_notifications` | Chỉ hiển thị thông báo cục bộ, không nhận push từ server |
| Gọi `firebase_messaging` thẳng trong Cubit | Trái ADR-0010 (SDK nằm sau domain port), không test được |

## Hệ quả

- Mọi push đi qua port này; đăng ký thiết bị luôn gắn với vòng đời phiên.
- Tính năng đầu tiên cần push phải nâng Firebase trước (commit riêng, iOS
  15.0, `pod install`) và cập nhật `optional-capabilities.md`.
- Server: upsert `POST /devices` có timestamp, xoá token khi FCM trả
  `UNREGISTERED`/`INVALID_ARGUMENT` hoặc cũ quá 30 ngày; gửi `android.priority
  high` và `channel_id` `default_channel`.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/push_notification.md`.
- Code mẫu và test bảo vệ:
  `test/patterns/push_notification_pattern_test.dart` (16 test: parse
  payload, đăng ký, token iOS tới muộn, không có dịch vụ push, xoay token,
  đăng xuất xoá token và khay kể cả khi API lỗi, đăng ký muộn bị hoàn tác,
  banner, mở link, chạm trùng, đọc quyền không hỏi). Adapter
  `FirebasePushRepo` trong file đã được analyze với `firebase_messaging`
  16.7.0, `firebase_core` 4.15.0, `flutter_local_notifications` 19.5.0.

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Khi áp dụng lần đầu: nâng `firebase_core` lên 4.x, `firebase_auth` lên 6.x và iOS tối thiểu lên 15.0 trong một commit riêng. Xem lại khi Firebase phát hành API Installation ID cho Flutter.
