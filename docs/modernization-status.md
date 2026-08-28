# Trạng Thái Modernization — 2026-08-28

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
- Sửa boundary domain thuần và kiểm tra presentation-to-data import.
- Cubit mặc định kèm hỗ trợ `BaseBloc`; base state immutable bằng Equatable.
- Alice inspector ngoài production có redaction, migration token storage an
  toàn, single-flight session refresh, và network layer không điều hướng UI.
- Git submodule `sli_common` thật với public API `Sli*`, tokens, themes và facade
  Shadcn.
- Component catalog cho 45/45 public export, maturity status, quick gallery,
  runnable showroom, BottomSheet pilot và golden preview tái tạo được.
- Dart Base CLI là source of truth cho `doctor/create/rename`, expose qua Derry,
  dry-run mặc định và validation trước mutation.
- Index kiến trúc, ADRs, contributor guides và AI agent/skill đã đồng bộ.
- Đã gỡ provisioning profile cá nhân và provisioning identifier hard-coded của
  iOS; signing material bị ignore và phải lấy từ local/CI secrets.

## Baseline đã verify

- Application quality: format 171 file, analyzer 0 finding, architecture gate
  pass và 18 tests pass.
- `sli_common`: scoped analyzer sạch và 5 tests pass.
- Catalog inventory gate xác nhận 45/45 public export có maturity entry.
- Derry facade forward được display name có khoảng trắng.
- Create smoke test với `catalog_smoke`:
  - recursive clone và bootstrap pass;
  - doctor pass, không còn warning `MainActivity` path;
  - package `catalog_smoke`, bundle `com.example.catalog_smoke` và native display
    name đồng bộ;
  - generated app quality pass với 18 tests;
  - submodule pin đúng revision `3604efd`;
  - không còn `package:bloc_cubit_base/` hoặc `com.giaohang247` ngoài submodule.

Evidence chi tiết nằm tại
[review 2026-08-28](reviews/2026-08-28-component-catalog-base-cli-review.md).

## Việc còn lại trước template zero-debt

1. Gỡ side effect `BuildContext`/navigation/dialog khỏi legacy feature Cubit và
   thay compatibility global handler bằng UI listener tường minh.
2. Thêm test concurrent 401 refresh/failure và offline interception.
3. Từ BottomSheet pilot, chốt stable presenter/frame contract và behavior
   matrix; sau đó mới migrate widget trùng trong `lib/core/widget` qua adapter.
4. Trung hòa product slice còn lại: `DeliveryGo`, copy/l10n `Giao Hàng 247`,
   Fastlane artifact/key path, icon/splash, Firebase client config và endpoint.
5. Burn down analyzer baseline của toàn bộ legacy `sli_common`, rồi mở rộng gate
   từ stable surface sang toàn historical package.

Base CLI đã xử lý deterministic identity, nhưng cố ý không đoán cách đổi class,
l10n key, Firebase project, signing hoặc Store credential. Vì vậy Phase 8
create/rename đã hoàn tất; Phase 8 neutral branding vẫn đang mở.

Automation delivery đã tái sử dụng `build.sh`/Fastlane qua Derry, có dry-run,
Store confirmation và Git tag opt-in. Chỉ dùng delivery thật sau khi hoàn thành
neutral branding/Firebase/signing ở mục 4.

Roadmap tổng nằm tại
[`docs/plan/2026-08-26-base-modernization.md`](plan/2026-08-26-base-modernization.md).
