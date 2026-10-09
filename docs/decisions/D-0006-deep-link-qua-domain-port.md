# D-0006: Deep link qua domain port

- Trạng thái: accepted
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
trạng thái và tham số route bị tin mù quáng. Android và Apple đều khuyến nghị
link `https` đã xác minh (App Links, Universal Links) vì scheme riêng có thể bị
app khác đăng ký. Chưa có plugin đọc link trong pubspec.

## Quyết định

Link `https` đã xác minh (App Links + Universal Links) là kênh chính, đọc qua
port `DeepLinkRepo` (`Stream<Uri>`, link khởi động trước) bằng
`app_links: ^7.2.2`; parser domain `AppLinkParser` chỉ nhận URI trong
allowlist và trả `sealed AppLinkTarget`; `DeepLinkCubit` cấp app giữ link tới
khi app sẵn sàng và user đã đăng nhập, rồi phát effect có kiểu để listener ở
app gọi `SLIRouting`.

- Plugin: `app_links: ^7.2.2` (publisher cow-level.ovh; 7.2.2 phát lại mọi
  link đến trước lần listen đầu và không gửi lại link khởi động khi activity
  Android dựng lại; 7.1+ cần Flutter ≥ 3.44). Adapter chỉ đọc
  `uriLinkStream`, không gọi thêm `getInitialLink()` (mở hai lần);
  `AppLinks` đăng ký trong `RegisterModule`.
- Tắt deep link mặc định của Flutter: `flutter_deeplinking_enabled=false`
  trong `AndroidManifest.xml`, `FlutterDeepLinkingEnabled=false` trong
  `Info.plist`.
- Native: intent-filter `android:autoVerify="true"` với `https`, host và
  `pathPrefix` khớp parser; `assetlinks.json` có SHA-256 của Play App
  Signing; entitlement `com.apple.developer.associated-domains`
  (`applinks:<host>`); `apple-app-site-association` với `appIDs`
  `<TEAMID>.<bundle id>` và `components` khớp parser.
- Allowlist: `https` + host chính xác, hoặc scheme riêng có host; từ chối
  port, user-info, path lạ, escape `%` hỏng, id ngoài `[A-Za-z0-9_-]{1,64}`;
  parser không bao giờ ném lỗi.
- Scheme riêng chỉ cho link an toàn nếu lộ; link mang bí mật (mã mời, token)
  chỉ nhận qua `https` đã xác minh.
- Link chỉ điều hướng, chỉ mang id; màn đích tải dữ liệu qua API có kiểm tra
  quyền; mọi thao tác thay đổi dữ liệu cần user xác nhận.
- `DeepLinkCubit`: `start()`, `markReady()` (splash gọi), `onSessionStarted()`
  (auth gọi), `openUri()` (push gọi); effect `DeepLinkOpenEffect(target)`,
  `DeepLinkSignInRequiredEffect`. Listener gọi
  `SLIRouting.toNamed(..., preventDuplicates: false)` để link thứ hai cùng
  route vẫn mở.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Deep link mặc định của Flutter (`onGenerateRoute`/`pushRoute`) | Đẩy path thô vào `MainApp.generator` (ném lỗi với route lạ), bỏ qua allowlist và cổng đăng nhập |
| Chỉ dùng scheme riêng (`blocbase://`) | App khác đăng ký được cùng scheme và nhận link; Android hiện hộp chọn app; Apple và Android đều khuyến nghị link `https` đã xác minh |
| `uni_links` | Đã discontinued trên pub.dev (bản cuối 2021); `app_links` là bản thay thế |
| Firebase Dynamic Links | Google đã tắt dịch vụ ngày 25/08/2025 |
| Tự viết platform channel (`intent`, `NSUserActivity`) | Tự duy trì code native hai nền tảng và scene lifecycle iOS mà `app_links` đã xử lý |
| `go_router` với `Router` | Trái ADR-0005 (giữ `SLIRouting`); cần ADR riêng |

## Hệ quả

- Mọi link từ ngoài và thao tác chạm push đi qua một parser và hai cổng (sẵn
  sàng, phiên); path trong parser, intent-filter và
  `apple-app-site-association` phải khớp nhau.
- Thêm `app_links: ^7.2.2` vào `pubspec.yaml` và cấu hình native khi tính
  năng đầu tiên cần deep link được duyệt; host và team id phải có trước.
- Hướng dẫn và cấu hình native: `.agents/skills/flutter-patterns/references/deep_link.md`.
- Code mẫu để chép (parser, port, use case, Cubit, state, effect, listener)
  và adapter `AppLinksDeepLinkRepo` (đã chạy `flutter analyze` với
  app_links 7.2.2): `test/patterns/deep_link_pattern_test.dart`.
- Test bảo vệ: cùng file, 12 test (allowlist chấp nhận và từ chối, mã mời
  chỉ qua `https`, chờ splash, chờ đăng nhập, push dùng chung parser, widget
  điều hướng qua `SLIRouting` kể cả link thứ hai cùng route).

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Cần host thật, Apple Team ID và SHA-256 chứng chỉ ký của Play để cấu hình App Links và Universal Links.
