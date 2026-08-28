# Trạng Thái Modernization — 2026-08-27

Tài liệu này tách rõ phần kiến trúc đã hoàn thành và phần cleanup legacy còn
lại. “Đã implement” nghĩa là đã có code và gate liên quan; không có nghĩa mọi
analyzer debt lịch sử đều đã biến mất.

## Đã implement

- Cấu hình local/development/staging/production có kiểu rõ ràng và bootstrap tập
  trung.
- FVM/Derry scripts, CI skeleton, code generation, architecture boundary gate,
  test app, và command delivery phân tách rõ build/Firebase/Store.
- `get_it + injectable`, generated graph, runtime module, và constructor
  injection trên dependency graph feature hiện tại.
- Sửa boundary domain thuần và kiểm tra presentation-to-data import.
- Cubit mặc định kèm hỗ trợ `BaseBloc`; base state immutable bằng Equatable.
- Alice inspector ngoài production có redaction, migration token storage an
  toàn, single-flight session refresh, và network layer không điều hướng UI.
- Git submodule `sli_common` thật với public API `Sli*`, tokens, themes, facade
  Shadcn, docs package, example, và tests.
- Index kiến trúc, ADRs, contributor guides, và đồng bộ AI agent/skill.
- Đã gỡ provisioning profile cá nhân và provisioning identifier hard-coded của
  iOS; signing material giờ bị ignore và phải lấy từ máy local hoặc CI secrets.

## Baseline đã verify

- Application tests: 11 passing.
- `sli_common` tests: 3 passing.
- Script kiểm tra architecture boundary: passing tại thời điểm migration.
- Source/test/example mới của `sli_common`: analyzer clean.
- Application analyzer giảm từ 162 findings xuống 0; gate analyzer toàn app đã
  pass.
- Full legacy analyzer của `sli_common` vẫn còn issue lịch sử ngoài scope mới
  `lib/src`, test, và example.

## Việc còn lại trước bản template zero-debt

1. Gỡ side effect `BuildContext`/navigation/dialog khỏi legacy feature Cubit và
   thay compatibility global handler bằng UI listener tường minh.
2. Thêm test cho concurrent 401 refresh/failure và offline interception.
3. Migrate component trùng trong `lib/core/widget` sang `sli_common` bằng
   compatibility adapter và behavior matrix.
4. Trung hoà branding DeliveryGo/mOrder còn lại, native identifiers, Firebase
   sample configuration, endpoints, và sample product slices.
5. Thêm script create/rename app có dry-run an toàn và validate clone sinh ra.
6. Burn down analyzer baseline còn lại của legacy `sli_common`, rồi mở rộng clean
   gate từ public surface sang toàn bộ historical package.

Automation delivery đã tái sử dụng `build.sh`/Fastlane qua Derry, có dry-run,
Store confirmation và Git tag opt-in. Fastlane vẫn còn branding/credential path
của sample nên chỉ dùng delivery thật sau khi hoàn thành mục 4 và 5.

Các việc này được track trong
[`docs/plan/2026-08-26-base-modernization.md`](plan/2026-08-26-base-modernization.md).
