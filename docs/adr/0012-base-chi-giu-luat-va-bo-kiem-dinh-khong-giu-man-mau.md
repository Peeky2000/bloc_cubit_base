# ADR 0012: Base chỉ giữ luật và bộ kiểm định, không giữ màn mẫu

- Trạng thái: accepted
- Ngày: 2026-11-25
- Phạm vi: project
- Tags: base,ai,template,auth
- Tính năng: 
- Thay thế: ADR-0010
- Bị thay bởi:

## Bối cảnh

Base ra đời để chép rồi đổi tên: đủ màn auth (đăng ký, quên mật khẩu, xác minh
số điện thoại bằng Firebase OTP), danh sách kéo để tải (`LoadingListScreen`),
46 widget trong `sli_common`, 18 file font và hơn 100 chuỗi l10n. Giờ agent
`flutter-dev` sinh màn mới từ spec, luật và skill, nên phần chép-đổi-tên chỉ
làm repo nặng, thêm package phải nâng, và dạy agent chép theo code cũ thay vì
theo luật. ADR-0010 giữ luồng Firebase Phone Auth của sample sau một domain
port; luồng đó không còn trong base.

## Quyết định

Base chỉ giữ ba thứ: luật (docs, ADR, quyết định, skill), hạ tầng dùng lại
(bootstrap, DI, mạng, phiên, routing, l10n, observability, công cụ) và bộ kiểm
định để đo agent sinh code có đúng luật không. Không giữ màn, model hay widget
mẫu để chép.

- Luồng mẫu duy nhất: splash → sign_in → home, đủ để chạy thử hạ tầng
  (phiên, refresh token, điều hướng, typed effect) và cho test hiệu năng
  `app_start`.
- `test/patterns/` là bộ kiểm định: mỗi file biên dịch đủ lớp của một mẫu
  (phân trang, form, cache, upload ảnh, realtime, deep link, push, quyền) và
  ghim hành vi. Agent sinh code từ `flutter-patterns/references/`, không chép
  file test; khi lệch, bộ kiểm định thắng.
- `sli_common` chỉ giữ foundation (`Sli*`, `SliIcons`), Shadcn facade, kit và
  widget legacy app đang import. Widget mới viết từ spec; widget đã bỏ lấy lại
  từ lịch sử git khi thật cần.
- SDK bên thứ ba đi sau một domain port như ADR-0010 đã đặt ra; mẫu đối chiếu
  chuyển sang `test/patterns/image_upload_pattern_test.dart`.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Giữ nguyên bộ màn mẫu | Agent không cần chép; mỗi đợt nâng Flutter phải nâng thêm `firebase_auth`, `pin_code_fields`, `pull_to_refresh`… mà sản phẩm có thể không dùng |
| Bỏ cả `test/patterns/` | Mất chuẩn để đo agent sinh đúng mẫu; luật dạng chữ không bắt được sai lệch hành vi |
| Giữ widget "đáng sưu tầm" trong `sli_common` (lịch, marquee, thước cuộn…) | Không app nào dùng; agent viết lại từ spec nhanh hơn đọc API cũ, và mỗi widget kéo theo package |

## Hệ quả

- Tính năng mới đi theo `tech-design` → `build-feature`, sinh code từ spec và
  skill; không tìm màn cũ để chép.
- Cần đăng ký, quên mật khẩu, OTP… thì viết theo spec của sản phẩm; nếu cần SDK
  (Firebase Auth, …) thì thêm port + adapter theo `flutter-repository` và
  `test/patterns/image_upload_pattern_test.dart`.
- Thay đổi base sau này: thêm luật và bộ kiểm định, không thêm màn mẫu.
- Đã bỏ khỏi app: `sign_up`, `reset_password`, `confirm_information`,
  `PhoneVerificationRepo`/`FirebasePhoneVerificationRepo`, `firebase_auth`,
  `pin_code_fields`, `AppOtpField`, `LoadingListScreen`, `pull_to_refresh`,
  model shop/role/profile, 14 file font, 75 chuỗi l10n. Lấy lại từ commit
  trước ADR này nếu cần.
