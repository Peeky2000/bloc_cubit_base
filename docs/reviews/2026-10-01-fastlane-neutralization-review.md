# Review — Fastlane sample artifact/key path (2026-10-01)

## Scope

Chỉ trung hòa delivery adapter, **không** đổi native identity/Firebase client
hoặc upload thật. Android dùng trực tiếp tên artifact Flutter sinh; iOS đặt IPA
trung lập. Store credential/package phải được truyền qua environment, không
trỏ tới key mang tên sample.

## Evidence

- `android/fastlane/Fastfile`: không còn lệnh xóa/đổi tên APK/AAB chỉ để mang
  nhãn `Giaohang247`; Store yêu cầu `ANDROID_PACKAGE_NAME` và
  `GOOGLE_PLAY_JSON_KEY_PATH`, kiểm tra key file tồn tại.
- `android/fastlane/Appfile`: chỉ khai báo package/key khi caller cung cấp env.
- `ios/fastlane/Fastfile`: tên IPA trung lập; Store yêu cầu
  `APP_STORE_CONNECT_API_KEY_PATH` và kiểm tra key file tồn tại.
- `ruby -c` cho ba file Fastlane trên: **Syntax OK**.
- `./build.sh distribute --platform android --environment dev --audience tester --dry-run`
  và `./build.sh store --platform ios --confirm-store --dry-run`: pass, route
  đúng lane, không upload/tag.
- `derry quality` pass: app analyzer 0/65 tests, toolkit analyzer 0/20 tests.
  Đây là repository regression gate; chưa chứng minh Fastlane upload thực tế.

## Giới hạn và follow-up

Không chạy Fastlane upload hay ký native build; dry-run không đọc credential.
Các Firebase client file, native display name/bundle ID, icon/splash, sample
product copy và endpoint vẫn là debt Phase 8. Review này **không** chứng nhận
Store readiness. Xem [hướng dẫn delivery](../guides/use-derry-and-build.md).
