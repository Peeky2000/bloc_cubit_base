---
title: Component catalog và Dart Base CLI
source: approved component-catalog brainstorm and ADR-0007
scope: sli_common discoverability and reusable app creation workflow
date: 2026-08-28
---

# Plan: Component Catalog Và Dart Base CLI

## Bối cảnh và mục tiêu

Đợt này giải quyết hai trở ngại còn lại của base:

1. `sli_common` có nhiều widget nhưng chưa đủ dễ tìm, xem trước và đánh giá để
   dùng an toàn; vì vậy chưa được migrate widget app theo tên file.
2. Việc tạo/đổi tên app mới chưa có một workflow deterministic, testable và an
   toàn; developer vẫn phải nhớ nhiều điểm sửa thủ công.

Mục tiêu là tạo catalog làm “tờ hướng dẫn của hộp dụng cụ”, dùng BottomSheet làm
pilot, đồng thời tạo Dart Base CLI phía sau Derry với dry-run mặc định và
validation trước mutation.

## Quyết định và ràng buộc đã thống nhất

- README của `sli_common` là quick gallery; tài liệu chi tiết nằm trong
  `docs/catalog`; example app là showroom chạy được.
- Mỗi entry phải ghi category, maturity (`stable`, `legacy`, `experimental`,
  `deprecated`), public API, preview, usage, source và test liên quan.
- Chưa migrate `lib/core/widget` trước khi có compatibility/behavior matrix.
- BottomSheet là pilot để phân biệt content frame với modal presenter; chưa vội
  công bố `SliBottomSheet` stable nếu contract chưa được chứng minh.
- V2, `/Work/commons` và design-system-mobile là nguồn tham khảo, không phải
  source để copy nguyên dependency hoặc branding.
- `tool/base_cli.dart` là engine; Derry chỉ forward argument.
- `create` và `rename` dry-run mặc định, chỉ ghi khi có `--apply`.
- CLI validate input, source, destination, collision và replacement plan trước
  khi sửa file; Firebase/signing/secret nằm trong checklist thủ công.

## Ngoài phạm vi

- Bulk migration/deprecation toàn bộ widget trùng trong app.
- Đưa Widgetbook hoặc generator catalog vào ngay ở pilot.
- Copy `commons/base_ui` hoặc design system TTN nguyên khối.
- Tự sinh Firebase project, certificate, provisioning profile hoặc Store
  credential.
- GraphQL, FCM, deep link và AI/VIPER workflow nâng cao.

## Dependency và artifact tái sử dụng

- `lib/modules/sli_common/lib/sli_common.dart` — public export hiện tại.
- `lib/modules/sli_common/example` — showroom nền đã có.
- `lib/modules/sli_common/guide` — ảnh legacy hiện có.
- `lib/core/widget` và `lib/widget` — caller/behavior app cần đối chiếu.
- `/Users/long/Documents/Work/commons/packages/base_ui` — tham khảo anatomy.
- `derry.yaml`, `scripts/quality.sh`, `build.sh` — automation facade/gate hiện có.
- [Brainstorm component catalog](../brainstorm/2026-08-28-ui-component-catalog-and-migration.md).
- [ADR-0007](../adr/0007-dart-base-cli-behind-derry.md).

## Phase 1 — Chính thức hóa và inventory

- [ ] **[docs/plan]** *(coder)* — Đưa catalog-before-migration và Dart Base
  CLI/Derry/dry-run/validation vào roadmap chính. **Verify:** roadmap, ADR,
  status và mục lục link qua lại, không còn task create/rename mơ hồ.
- [ ] **[sli_common/docs/catalog]** *(coder)* — Lập inventory cho toàn bộ public
  export theo category và maturity, chỉ rõ stable surface với legacy surface.
  **Verify:** mọi export trong `lib/sli_common.dart` xuất hiện trong inventory.

## Phase 2 — Catalog skeleton và BottomSheet pilot

- [ ] **[sli_common/README.md]** *(coder)* — Biến README thành quick-start và
  quick gallery có status, ảnh và link usage. **Verify:** người mới tìm được
  button, surface và bottom sheet mà không đọc source.
- [ ] **[sli_common/docs/catalog]** *(coder)* — Thêm template component cùng
  tài liệu cho `SliButton`, `SliSurface` và legacy `BottomSheetWidget`.
  **Verify:** mỗi trang có when-to-use, API, example, status, source và test.
- [ ] **[sli_common/example]** *(coder)* — Mở rộng example thành showroom tối
  thiểu cho ba component pilot. **Verify:** example analyze và render được.
- [ ] **[sli_common/test]** *(coder)* — Thêm preview/golden hoặc widget coverage
  tái tạo ảnh catalog. **Verify:** test pass; ảnh preview được tạo từ code thật.

## Phase 3 — Dart Base CLI và Derry facade

- [ ] **[tool/base_cli.dart]** *(coder)* — Implement parser/validator/planner cho
  `doctor`, `rename`, `create`; giữ dry-run mặc định và chỉ mutate với `--apply`.
  **Verify:** invalid identifiers, destination collision và incomplete template
  fail trước mutation.
- [ ] **[derry.yaml]** *(coder)* — Expose `derry base`, `derry create` và
  `derry rename` như facade mỏng. **Verify:** help/dry-run forward đầy đủ
  argument và không duplicate replacement logic.
- [ ] **[test/tool]** *(coder)* — Test validator, dry-run, apply trên fixture và
  guard destination. **Verify:** test chứng minh dry-run không đổi filesystem và
  invalid input không tạo partial result.
- [ ] **[docs/guides]** *(coder)* — Viết workflow create/rename/doctor, phần nào
  tự động và phần Firebase/signing phải làm tay. **Verify:** guide command khớp
  `--help` và Derry catalog.

## Phase 4 — Đồng bộ và verification

- [ ] **[docs]** *(coder)* — Cập nhật `docs/README.md`, modernization status,
  roadmap, review và changelog. **Verify:** toàn bộ artifact được truy vết từ
  mục lục trung tâm.
- [ ] **[sli_common]** *(coder)* — Chạy analyzer/test/example gate, commit và
  cập nhật submodule revision. **Verify:** submodule sạch ở revision có thể
  clone được.
- [ ] **[root]** *(reviewer)* — Chạy `derry quality`, CLI tests và create smoke
  test vào temporary directory. **Verify:** generated clone `pub get` và analyze
  pass hoặc debt/giới hạn được ghi bằng evidence thật.

## Rủi ro và giảm thiểu

- **Catalog drift khỏi code:** preview/test sinh từ component thật và entry dẫn
  trực tiếp tới source/test.
- **Gắn nhãn legacy như stable:** inventory bắt buộc maturity; chỉ `Sli*` contract
  đã test mới được đánh dấu stable.
- **CLI sửa dở project:** validate toàn plan trước write, dry-run mặc định và
  test invalid path/input.
- **Clone mang credential cá nhân:** template không chứa signing secret; CLI
  xuất post-create checklist thay vì tự đoán Firebase/signing.
- **Logic trùng giữa Derry/shell/Dart:** Derry chỉ facade; create/rename không
  được implement lại trong `build.sh`.

## Definition of Done

- [ ] Roadmap/ADR/status/guide/catalog cùng mô tả một workflow.
- [ ] Mọi public export `sli_common` có inventory và maturity status.
- [ ] Ba component pilot có docs, runnable demo và preview/test phù hợp.
- [ ] `create`/`rename` dry-run mặc định; `--apply` validate trước mutation.
- [ ] `derry quality` pass và generated DI hiện hành.
- [ ] Architecture boundary gate pass.
- [ ] Analyzer/test/example gate của `sli_common` pass.
- [ ] Smoke clone/create có submodule đúng và không chứa signing secret mới.
- [ ] Docs/changelog/review ghi đúng bằng chứng, không che giấu debt còn lại.
