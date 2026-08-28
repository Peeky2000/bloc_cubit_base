# Review Modernization Base — 2026-08-27

## Kết luận

Nền tảng modernization đã sẵn sàng cho feature work tiếp theo. App hiện có
bootstrap deterministic, typed environments, generated DI, boundary layer được
enforce, primitive state theo hướng Cubit-first/BLoC-capable, network inspection
được bảo vệ, và toolkit `sli_common` thật được version độc lập.

Review này chưa gọi repository là template hoàn toàn trung lập sản phẩm. Legacy
sample feature, branding, native identifier, và surface lịch sử của `sli_common`
vẫn được track có chủ ý như follow-up migration.

## Gates đã verify

| Gate | Kết quả |
|---|---|
| `./scripts/generate.sh` | Pass; generated output reproducible |
| `./scripts/format.sh --check` | Pass; 169 Dart files không đổi |
| `flutter analyze` | Pass; 0 finding |
| `./scripts/check_architecture.sh` | Pass |
| Application tests | Pass; 11 tests |
| `sli_common` scoped analysis | Pass; `lib/src`, `test`, và `example/lib` |
| `sli_common` tests | Pass; 3 tests |
| `git diff --check` | Pass |
| Scan signing/private-key đã tracked | Pass; không có artifact nhạy cảm khớp |
| Fresh recursive clone | Pass; checkout submodule, bootstrap, và analyze |

## Review kiến trúc

- Chiều dependency được enforce theo domain → data implementation →
  presentation, không còn shortcut presentation-to-data.
- `get_it` vẫn là runtime container, còn `injectable` sở hữu registration
  compile-time. Business class dùng constructor injection.
- Cubit là lựa chọn bình thường. `BaseBloc` sẵn sàng cho flow event-driven hoặc
  nặng concurrency mà không ép mọi feature thành BLoC.
- `BaseAppState + Equatable + copyWith` vẫn là contract state. Freezed,
  HydratedBloc, GraphQL, FCM, và deep links là optional capabilities.
- REST/Dio là transport mặc định. Network inspection bị cấm trong production và
  field nhạy cảm được redact trước khi capture.
- Shadcn được cô lập sau component `Sli*` ổn định để app không phụ thuộc trực
  tiếp vào API design bên thứ ba.

## Review bảo mật và delivery

- Đã xoá ba file `.mobileprovision` từng được tracked.
- Đã xoá provisioning profile name và UUID hard-coded khỏi Xcode project.
  Signing phải được cung cấp bởi Xcode automatic signing hoặc CI.
- Firebase flavor files vẫn giữ lại vì xoá ngay sẽ làm vỡ sample flavors hiện
  tại. Chúng là client configuration, không phải signing secret, nhưng phải được
  thay bởi workflow tạo app.

## Ưu tiên follow-up

1. Thêm test concurrent 401 refresh, refresh-failure, và offline interceptor để
   khóa contract network hiện có trước khi refactor tiếp.
2. Làm feature Cubit không phụ thuộc context và thay compatibility global
   handler bằng UI listener/effect tường minh.
3. Migrate duplicated app widget sang `sli_common` qua adapter và behavior
   matrix.
4. Thêm create/rename app an toàn có dry-run, rồi trung hoà sample branding,
   native identifier, Firebase config, và product slice.
5. Modernize thư viện lịch sử `sli_common` từng bước cho tới khi full analyzer
   thay thế clean public-surface gate hiện tại.

## Xác minh phạm vi follow-up

| Hạng mục | Kết luận | Evidence và phạm vi thật |
|---|---|---|
| Cubit độc lập UI | Đúng, có thể triển khai | Cubit không nhận `BuildContext` trực tiếp nhưng inject `AppController` để lấy context/l10n. `SignUpCubit`, `ResetPasswordCubit`, `SignInCubit`, `ConfirmInformationCubit`, và `SplashCubit` còn gọi l10n/navigation/dialog/global handler. Cần migrate theo feature sang typed validation + state/effect và `BlocListener`, không chỉ sửa hai Cubit được nêu ví dụ. |
| Concurrent 401 | Đúng, có thể triển khai và có khả năng lộ lỗi lifecycle thật | `SessionInterceptor` đã có `_singleFlightRefresh()`, refresh bằng Dio riêng và retry request, nhưng test suite chưa có interceptor test. Interceptor hiện tự `clearToken()` rồi gọi `onSessionExpired`, trong khi `ApiClient` truyền tiếp chính `tokenProvider.clearToken`; một failure có thể clear hai lần và nhiều request failure có thể phát expiry lặp. Cần cover nhiều 401 chỉ refresh một lần, request dùng token mới, refresh fail chỉ expire session một lần, skip refresh endpoint, và offline rejection. |
| Trung hòa branding | Đúng, triển khai sau create/rename foundation | `Giaohang247`/`DeliveryGo` còn trong Dart widget, ARB, Android application ID/flavor name, iOS bundle/display name, Firebase config và Fastlane artifact/key path. Search-replace đơn lẻ dễ làm vỡ native/Firebase; nên có rename dry-run, manifest thay đổi và smoke test clone trước. |

Thứ tự khuyến nghị là test interceptor trước để khóa contract network, migrate
UI effect theo từng feature nhỏ, sau đó mới trung hòa branding cùng workflow
create/rename. Ba hạng mục độc lập về code nhưng cùng phải cập nhật docs và
quality gate khi hoàn tất.

Source of truth có thứ tự vẫn là
[`docs/plan/2026-08-26-base-modernization.md`](../plan/2026-08-26-base-modernization.md).
