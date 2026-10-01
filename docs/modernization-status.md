# Trạng Thái Modernization — 2026-10-01

Tài liệu này tách rõ foundation đã hoàn thành và cleanup legacy còn lại. “Đã
implement” nghĩa là có code cùng gate liên quan; không có nghĩa sample product
đã trung lập hoàn toàn.

## Đã implement

- Cấu hình local/development/staging/production có kiểu rõ ràng và bootstrap tập
  trung.
- FVM/Derry scripts, CI skeleton, code generation, architecture boundary gate,
  test app, và command delivery phân tách build/Firebase/Store.
- `get_it + injectable`, generated graph, runtime module, và constructor
  injection trên dependency graph feature hiện tại.
- DI reset/dispose lifecycle có test seam; repeated setup không leak
  registration.
- Sửa boundary domain thuần và kiểm tra presentation-to-data import.
- Cubit mặc định kèm hỗ trợ `BaseBloc`; base state immutable bằng Equatable.
- `BaseAppState` hỗ trợ generic typed failure; Cubit và BLoC đại diện đã cover
  initial/loading/success/failure.
- Năm legacy auth/startup Cubit đã độc lập widget tree: validation có kiểu,
  one-shot `UiEffect` revisioned, route/dialog/l10n thuộc Screen và pure-Cubit
  rule được khóa trong architecture gate.
- Alice inspector ngoài production có redaction; token storage serialize write
  và dùng revision guard; session refresh single-flight, retry an toàn và network
  layer không điều hướng UI.
- Contract session/network đã có test cho concurrent 401, terminal/transient
  refresh failure, stale account race, cross-origin bearer protection,
  multipart replay, 403, retry 500 và offline pass/reject.
- Terminal expiry đi qua `SessionExpiryCoordinator` để clear credential rồi
  phát typed event; `AppCubit` chuyển event thành app-state revision và
  `MainApp` xử lý bằng `BlocListener` tại presentation boundary.
- `NetworkChecker` có monitor seam, repeated-init guard, idempotent dispose và
  singleton disposal qua generated DI.
- Git submodule `sli_common` thật với public API `Sli*`, tokens, themes và facade
  Shadcn đã khóa variant/size, touch target, semantics và golden light/dark.
- Component catalog cho 46/46 public export, maturity status, quick gallery và
  runnable showroom. BottomSheet đã đi từ pilot thành stable typed
  presenter/frame contract; selection callers dùng API shared trực tiếp và
  app-local API cũ là adapter deprecated.
- `ExpandedWidget` đã đồng bộ behavior hai trục, có test mở/đóng trong toolkit,
  app-local API là adapter deprecated và caller nội bộ dùng public shared API.
- Analyzer toàn bộ historical `sli_common` đã sạch; Derry quality và CI kiểm
  tra cả package, không còn gate chỉ giới hạn ở stable surface.
- Dart Base CLI là source of truth cho `doctor/create/rename`, expose qua Derry,
  dry-run mặc định và validation trước mutation.
- Index kiến trúc, ADRs, contributor guides và agent/skill Flutter đã đồng bộ.
- Sáu skill quality Flutter/mobile đã có workflow evidence-first và bản đồ chọn
  skill cho người mới; frontmatter được kiểm tra bằng YAML parser. Chưa có eval
  agent độc lập về tỉ lệ trigger, nên không tuyên bố đã tối ưu trigger.
- Đã gỡ provisioning profile cá nhân và provisioning identifier hard-coded của
  iOS; signing material bị ignore và phải lấy từ local/CI secrets.
- Fastlane không còn dùng tên artifact/key path `Giaohang247`; Store lane yêu
  cầu package/key qua environment và kiểm tra key file tồn tại.

## Baseline đã verify

- Application quality: format 195 file, analyzer 0 finding, architecture gate
  pass và 65 tests pass.
- `sli_common`: full-package analyzer 0 finding và 20 tests pass.
- Catalog inventory gate xác nhận 46/46 public export có maturity entry.
- Baseline 241 analyzer finding lịch sử đã được xử lý. Tên enum và async back
  API legacy được giữ bằng ngoại lệ lint có chú thích tại source.
- Derry facade forward được display name có khoảng trắng.
- Create smoke test với `catalog_smoke`:
  - recursive clone và bootstrap pass;
  - doctor pass, không còn warning `MainActivity` path;
  - package `catalog_smoke`, bundle `com.example.catalog_smoke` và native display
    name đồng bộ;
  - generated app quality pass với 18 tests;
  - submodule pin đúng revision `3604efd`;
  - không còn Dart package cũ trong import code hoặc application ID cũ trong
    native/runtime config;
  - `xcodebuild -list` đọc được project và đủ 9 build configurations/3 schemes.

Evidence mới nhất nằm tại
[review ExpandedWidget migration 2026-10-01](reviews/2026-10-01-expanded-widget-migration-review.md)
và
[review full analyzer 2026-10-01](reviews/2026-10-01-sli-common-full-analyzer-review.md).
Shadcn/BottomSheet có snapshot riêng tại
[review Shadcn/BottomSheet 2026-09-30](reviews/2026-09-30-shadcn-bottom-sheet-review.md).
State/DI completion có snapshot riêng tại
[review state/DI completion 2026-09-30](reviews/2026-09-30-state-di-completion-review.md).
Pure Cubit/UI effect có snapshot riêng tại
[review pure Cubit/UI effect 2026-09-28](reviews/2026-09-28-pure-cubit-ui-effects-review.md).
Session/network có snapshot riêng tại
[review session/network 2026-09-28](reviews/2026-09-28-session-network-review.md).
Catalog và Base CLI vẫn có snapshot riêng tại
[review 2026-08-28](reviews/2026-08-28-component-catalog-base-cli-review.md).

## Việc còn lại trước template zero-debt

1. Tiếp tục migration theo family cho 9 file trùng còn lại: dialog, form/input,
   button/action và display; matrix hiện tại đã chỉ ra khác biệt và gate của
   từng loại tại [widget family matrix](plan/2026-10-01-widget-family-migration-matrix.md).
2. Trung hòa product slice còn lại: `DeliveryGo`, copy/l10n `Giao Hàng 247`,
   native identity, icon/splash, Firebase client config và endpoint. Fastlane
   artifact/key path đã tách khỏi sample.
3. Chạy eval độc lập cho skill Flutter/mobile trên task thật để đánh giá
   trigger/output và tinh chỉnh nếu cần; sáu skill cùng guide đã có thể dùng.

Base CLI đã xử lý deterministic identity, nhưng cố ý không đoán cách đổi class,
l10n key, Firebase project, signing hoặc Store credential. Vì vậy Phase 8
create/rename đã hoàn tất; Phase 8 neutral branding vẫn đang mở.

Automation delivery đã tái sử dụng `build.sh`/Fastlane qua Derry, có dry-run,
Store confirmation và Git tag opt-in. Chỉ dùng delivery thật sau khi hoàn thành
neutral branding/Firebase/signing ở mục 2.

Version Health dựa trên Analytics, Crashlytics, Firebase Performance và Remote
Config được giữ ở future scope. Phần này chỉ bắt đầu sau các mục zero-debt bên
trên và không chặn modernization hiện tại.

Roadmap tổng nằm tại
[`docs/plan/2026-08-26-base-modernization.md`](plan/2026-08-26-base-modernization.md).
