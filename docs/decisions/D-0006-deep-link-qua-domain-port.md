# D-0006: Deep link qua domain port

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: deeplink,routing,security
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Link từ email, QR, web và thông báo đẩy cần mở đúng màn. Base dùng
`SLIRouting` + `AppPage` (ADR-0005); `MainApp.generator` dùng `firstWhere` nên
ném lỗi với tên route lạ. `optional-capabilities.md` hoãn deep link tới khi rõ
route và quyền sở hữu. `mobile-attack-classes.md` liệt kê rủi ro link đổi
trạng thái và tham số route bị tin mù quáng. Chưa có plugin đọc link trong
pubspec.

## Quyết định

Port `DeepLinkRepo` trả `Stream<Uri>` (link khởi động trước); một parser domain
`AppLinkParser` chỉ nhận URI trong allowlist và trả `sealed AppLinkTarget`;
`DeepLinkCubit` cấp app giữ link tới khi app sẵn sàng và user đã đăng nhập,
rồi phát effect có kiểu để listener ở app gọi `SLIRouting`.

- Plugin đề xuất: `app_links` (`uriLinkStream` gồm cả link khởi động); tắt
  deep link mặc định của Flutter (`flutter_deeplinking_enabled=false`,
  `FlutterDeepLinkingEnabled=NO`).
- Allowlist: `https` + host chính xác, hoặc scheme riêng của app; từ chối
  port, user-info, path lạ, id ngoài `[A-Za-z0-9_-]{1,64}`.
- Link chỉ điều hướng, chỉ mang id; màn đích tải dữ liệu qua API có kiểm tra
  quyền; mọi thao tác thay đổi dữ liệu cần user xác nhận.
- `DeepLinkCubit`: `start()`, `markReady()` (splash gọi), `onSessionStarted()`
  (auth gọi), `openUri()` (push gọi); effect `DeepLinkOpenEffect(target)`,
  `DeepLinkSignInRequiredEffect`.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Deep link mặc định của Flutter (`onGenerateRoute`) | Không có allowlist hay chờ đăng nhập; `MainApp.generator` ném lỗi với route lạ |
| `uni_links` | Không còn được duy trì; `app_links` là bản thay thế |
| Firebase Dynamic Links | Google đã ngừng dịch vụ |
| Chuyển sang `go_router` | Trái ADR-0005 (giữ `SLIRouting`); cần ADR riêng |

## Hệ quả

- Mọi link từ ngoài và thao tác chạm push đi qua một parser và hai cổng (sẵn
  sàng, phiên).
- Hướng dẫn: `.agents/skills/flutter-patterns/references/deep_link.md`.
- Code mẫu và test bảo vệ: `test/patterns/deep_link_pattern_test.dart`
  (11 test: allowlist chấp nhận và từ chối, chờ splash, chờ đăng nhập, push
  dùng chung parser, widget điều hướng qua `SLIRouting`).
