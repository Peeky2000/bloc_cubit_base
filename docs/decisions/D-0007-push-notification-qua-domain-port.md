# D-0007: Push notification qua domain port

- Trạng thái: proposed
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
`Stream<PushEvent>`; `PushUseCase` sở hữu việc đăng ký thiết bị gắn với phiên;
`PushCubit` cấp app biến message lúc foreground thành effect banner và thao tác
chạm thành link đi qua parser deep link.

- Plugin đề xuất: `firebase_messaging` 15.x (dòng tương thích `firebase_core`
  3.x); background handler top-level `@pragma('vm:entry-point')`, không DI,
  không UI.
- Payload: `data{id, type, link}`; `PushMessage.fromData`; `type` lạ thành
  `PushType.unknown` và không điều hướng.
- `onSignedIn()` đăng ký token và token xoay vòng; `onSignedOut()` (cùng
  đường với đăng xuất và hết hạn) huỷ đăng ký trên server rồi luôn
  `deleteToken()`; revision bỏ và hoàn tác đăng ký về muộn.
- Thao tác chạm có link gọi `DeepLinkCubit.openUri`; xin quyền tại màn giải
  thích lợi ích, không xin lúc mở app.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| OneSignal | Dịch vụ thứ ba thêm dữ liệu ra ngoài; Firebase đã có trong project |
| APNs/FCM HTTP trực tiếp qua platform channel | Tự duy trì code native hai nền tảng |
| Chỉ `flutter_local_notifications` | Chỉ hiển thị thông báo cục bộ, không nhận push từ server |
| Gọi `firebase_messaging` thẳng trong Cubit | Trái ADR-0010 (SDK nằm sau domain port), không test được |

## Hệ quả

- Mọi push đi qua port này; đăng ký thiết bị luôn gắn với vòng đời phiên.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/push_notification.md`.
- Code mẫu và test bảo vệ:
  `test/patterns/push_notification_pattern_test.dart` (12 test: parse
  payload, đăng ký, xoay token, đăng xuất xoá token kể cả khi API lỗi, đăng ký
  muộn bị hoàn tác, banner, mở link).
