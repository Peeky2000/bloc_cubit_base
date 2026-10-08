# D-0008: Xin quyền runtime qua domain port

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: permission,privacy
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Camera, ảnh, vị trí, thông báo cần xin quyền lúc chạy. `sli_common` có
`PermissionUtil` dùng `permission_handler` nhưng nhận `BuildContext`, tự hiện
toast và dialog bên trong, nên Cubit không dùng và không test được.
`permission_handler` hiện chỉ là phụ thuộc gián tiếp qua `sli_common`.

## Quyết định

Port `PermissionRepo` trả một `PermissionAccess` cho mỗi lần gọi; UseCase
`PermissionUseCase` map sang tập đóng `PermissionDecision`; Cubit của tính năng
phát effect có kiểu cho giải thích, mở cài đặt và tiếp tục, và kiểm tra lại khi
app quay lại.

- Plugin: `permission_handler`, thêm làm phụ thuộc trực tiếp (adapter
  `PermissionHandlerRepo`, một request đang chạy cho mỗi quyền; Android ≤ 12
  ảnh dùng `storage`).
- `AppPermission{camera, photos, location, notifications}`;
  `PermissionAccess{granted, limited, denied, permanentlyDenied, restricted}`;
  `PermissionDecision{proceed, showRationale, declined, openSettings,
  unavailable}`.
- Chỉ xin khi user chạm tính năng; giải thích trong app trước dialog hệ thống;
  từ chối thì tắt tính năng, không hỏi lại; vĩnh viễn thì mở cài đặt; kiểm tra
  lại ở `onAppResumed`; chạm đôi chỉ hỏi một lần.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `PermissionUtil` của `sli_common` | Cần `BuildContext`, tự hiện UI, không trả kết quả; giữ cho màn cũ |
| Xin quyền trong từng plugin (camera, location) | Mỗi plugin trả lỗi khác nhau, không có luồng giải thích và cài đặt thống nhất |
| Xin tất cả quyền khi mở app | Tỉ lệ từ chối cao, vi phạm hướng dẫn store và tối thiểu dữ liệu |

## Hệ quả

- Mọi tính năng cần quyền dùng port và bảng quyết định này; chỉ khai báo quyền
  thật sự dùng trong manifest và Info.plist.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/permission.md`.
- Code mẫu và test bảo vệ: `test/patterns/permission_pattern_test.dart`
  (11 test: map đủ mọi trạng thái, giải thích trước, từ chối, mở cài đặt rồi
  kiểm tra lại, bị thu hồi, bị hạn chế, chạm đôi, sau `close()`).
