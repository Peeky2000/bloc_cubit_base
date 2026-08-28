---
name: Flutter base modernization
source: approved architecture decisions in Codex task
scope: migration-heavy
date: 2026-08-26
---

# Plan: Modernize Flutter Base

## Bối cảnh

Modernize `bloc_cubit_base` thành base Flutter cá nhân có thể tái sử dụng và
biến `sli_common` thành UI toolkit thật, version độc lập. Cách làm học những ý
tưởng đã chứng minh hiệu quả từ `base_flutter_project_v2` và
`/Users/long/Documents/Work/commons`, nhưng không copy độ phức tạp phụ thuộc
sản phẩm hoặc technical debt đã biết của chúng.

Đích đến vẫn giữ Clean Architecture, `SLIRouting`, REST/Dio, Cubit làm mặc định,
BLoC cổ điển là lựa chọn được hỗ trợ, và `BaseAppState + Equatable + copyWith`.
Base bổ sung typed environments, bootstrap deterministic, `get_it + injectable`,
automation, network inspection bắt buộc redaction, Git submodule `sli_common`
thật, và design layer có Shadcn phía sau. Documentation và AI instructions phải
được version cùng mọi thay đổi kiến trúc.

## Ngoài phạm vi

- GraphQL runtime và generated operations; chỉ giữ extension contract trong docs.
- Firebase Messaging và deep-link implementation.
- HydratedBloc và migrate state sang Freezed.
- Adopt toàn bộ quy trình VIPER và automation AI nâng cao.
- Product-specific backend endpoints hoặc business feature.

## Phụ thuộc

- Flutter/FVM toolchain có sẵn local.
- Có quyền Git tới `https://github.com/Peeky2000/sli_common.git`.
- Thay đổi `sli_common` phải được commit trước khi `bloc_cubit_base` pin
  submodule revision mới.

## Phase 0 — Baseline và source of truth kiến trúc

- [x] **[docs]** *(coder)* — Ghi lại architecture decision, dependency rules,
  scope, migration strategy, và baseline hiện tại. **Verify:** mọi quyết định
  accepted đều có ADR và link từ architecture index.
- [x] **[tests]** *(coder)* — Chạy và ghi nhận `flutter pub get`,
  `flutter analyze`, và `flutter test` trước migration. **Verify:** failure có
  sẵn được tách khỏi regression mới.

## Phase 1 — Toolchain và automation tái lập được

- [x] **[infra]** *(coder)* — Pin Flutter bằng `.fvmrc`, thêm `derry.yaml`, và
  implement script an toàn cho bootstrap, generation, formatting, analysis, và
  tests. **Verify:** mọi script fail fast và chạy được từ mọi working directory.
- [x] **[infra]** *(coder)* — Thêm CI cho submodules, dependencies, code
  generation, formatting, static analysis, và tests. **Verify:** workflow không
  chứa secret hoặc product credential và dùng phiên bản Flutter được pin.
- [x] **[infra]** *(coder)* — Chuẩn hóa command catalog Derry và tận dụng lại
  `build.sh`/Fastlane theo ba mức `build` local, `distribute` Firebase và
  `release` Store. Store cần xác nhận; delivery hỗ trợ dry-run và Git tag là
  opt-in. **Verify:** Derry list đúng command, shell/Ruby syntax pass, dry-run
  map đúng platform/environment/audience và không sửa `.env`.

## Phase 2 — Typed environment và deterministic bootstrap

- [x] **[lib/core/config]** *(coder)* — Thay cấu hình enum mutable bằng
  `AppEnvironment` immutable có kiểu và `AppEnvironmentConfig` được validate.
  **Verify:** base URL HTTP(S) không hợp lệ fail trước `runApp`.
- [x] **[lib/bootstrap.dart]** *(coder)* — Làm bootstrap order tường minh, được
  guard, và testable; entrypoint chỉ chọn environment. **Verify:** cả bốn
  entrypoint đều delegate tới cùng bootstrap pipeline.

## Phase 3 — Injectable dependency injection

- [x] **[lib/di]** *(coder)* — Thêm Injectable configuration và module cho
  dependency async/external. **Verify:** `build_runner` sinh
  `injection.config.dart` có graph resolve được.
- [x] **[lib]** *(coder)* — Annotate dependency app và chuyển Cubit/BLoC, use
  case, repository, data source sang constructor injection. **Verify:** không
  có constructor business-layer nào đọc `Injector.getIt`.
- [ ] **[tests]** *(coder)* — Thêm test DI/bootstrap resettable. **Verify:**
  repeated test setup không leak registration.

## Phase 4 — Convention Cubit/BLoC và state

- [ ] **[lib/core/base_component]** *(coder)* — Gia cố `BaseAppState`
  immutable, failure data có kiểu, và convention Cubit/BLoC mà không đưa Freezed
  hoặc HydratedBloc vào. **Verify:** test Cubit và BLoC đại diện cover
  initial/loading/success/failure.
- [ ] **[lib/presentation]** *(coder)* — Gỡ `BuildContext` và service-locator
  access khỏi feature state manager; expose UI effect bằng state hoặc
  presentation event. **Verify:** presentation logic unit-test được mà không cần
  widget tree.

## Phase 5 — Sửa boundary Clean Architecture

- [x] **[lib/domain]** *(coder)* — Gỡ mọi import từ `data` và Flutter/UI layer.
  **Verify:** boundary check tự động báo 0 domain violation.
- [x] **[lib/presentation]** *(coder)* — Phụ thuộc domain entity/use case thay
  vì data model/data source. **Verify:** boundary check tự động báo 0 import
  trực tiếp presentation-to-data.

## Phase 6 — REST, session security, và network inspection

- [ ] **[lib/data]** *(coder)* — Refactor Dio/session interceptor để tránh
  navigation hoặc dialog, serialize token refresh, và retry request an toàn.
  **Verify:** test cover concurrent 401, refresh failure, và offline behavior.
- [x] **[lib/core/network]** *(coder)* — Thêm Alice inspection ngoài production
  với redaction mặc định cho authorization, cookies, tokens, passwords, và PII
  phổ biến. **Verify:** production config không thể bật inspector và redaction
  tests pass.
- [x] **[lib/data/local]** *(coder)* — Thêm secure token storage abstraction và
  migration path từ preferences. **Verify:** access/refresh token không mới được
  lưu plain preferences.

## Phase 7 — `sli_common` và Shadcn design toolkit

- [x] **[sli_common]** *(coder)* — Thiết lập public API package ổn định, source
  layout, semantic design tokens, light/dark theme extension, license,
  changelog, và docs. **Verify:** consumer chỉ import public barrel và package
  analysis pass.
- [ ] **[sli_common]** *(coder)* — Thêm Shadcn như chi tiết triển khai phía sau
  wrapper `Sli*` ổn định, gồm accessibility và variant contract. **Verify:**
  example, widget tests, và golden tests cover component lõi và cả hai theme.
- [x] **[lib/modules]** *(coder)* — Thay embedded tree rỗng bằng Git submodule
  thật và thêm path dependency từ app. **Verify:** fresh recursive clone resolve
  `sli_common` và build không cần copied widget imports.
- [ ] **[sli_common/docs/catalog]** *(coder)* — Inventory toàn bộ public export,
  gắn maturity status và xây quick gallery + per-component docs + runnable
  showroom; dùng BottomSheet làm pilot. **Verify:** mọi export được catalog và
  component pilot có preview/usage/source/test truy được từ README.
- [ ] **[lib/core/widget]** *(coder)* — Migrate widget trùng qua compatibility
  adapter/deprecation, chỉ bắt đầu sau catalog và behavior matrix. **Verify:**
  không bulk migration gây vỡ behavior và drift được track bằng compatibility
  matrix.

## Phase 8 — Cleanup template tái sử dụng

- [ ] **[app]** *(coder)* — Gỡ hoặc parameterize branding mOrder/Giaohang247,
  signing artifact, credential, endpoint ví dụ, và residue sinh mã. **Verify:**
  secret scan sạch và rename smoke test pass.
- [ ] **[tool + scripts]** *(coder)* — Cung cấp Dart Base CLI làm source of
  truth cho `doctor/create/rename`; expose qua Derry facade, dry-run mặc định và
  validate toàn plan trước `--apply`. **Verify:** invalid input không mutation;
  app tạm được generate pass `flutter pub get` và analyze.

## Phase 9 — Đồng bộ tài liệu và hướng dẫn AI

- [x] **[docs]** *(coder)* — Cập nhật README, prerequisites, architecture, DI,
  state, networking, UI toolkit, environment, và contributor guides. **Verify:**
  mọi command/path tồn tại và docs không dạy pattern đã retired.
- [x] **[.agents]** *(coder)* — Viết lại agents, skills, checklists, và memory
  metadata để khớp Injectable, constructor injection, chọn Cubit/BLoC, và vị trí
  `sli_common`. **Verify:** search toàn repo không còn yêu cầu manual DI mâu
  thuẫn.

## Rủi ro & giảm thiểu

- **Risk:** một migration lớn che giấu regression. **Mitigation:** giữ từng
  phase có thể analyze/test độc lập và dùng compatibility adapter khi migrate UI.
- **Risk:** generated DI trở nên khó hiểu. **Mitigation:** giữ external provider
  trong module nhỏ có docs và thêm graph-resolution test.
- **Risk:** API Shadcn leak vào application. **Mitigation:** expose wrapper
  `Sli*` ổn định và cấm direct app import trừ escape hatch có tài liệu.
- **Risk:** submodule revision không thể trỏ tới work `sli_common` chưa commit.
  **Mitigation:** hoàn tất và verify package trước, rồi commit/pin rõ ràng.
- **Risk:** credential hoặc product file cũ còn sót trong template cleanup.
  **Mitigation:** thêm secret scanning và release checklist; không bao giờ in
  nội dung credential.

## Definition of Done

- [ ] Tất cả task ở trên được check hoặc được chuyển rõ sang follow-up plan kèm
  lý do.
- [x] `./scripts/format.sh --check` pass.
- [x] `flutter analyze` pass không có finding.
- [x] `flutter test` pass cho application và `sli_common`.
- [x] `derry gen` reproducible.
- [x] Fresh recursive clone bootstrap được bằng command trong docs.
- [x] Documentation, ADRs, AI agents, skills, và implementation dạy cùng một
  bộ quy tắc.
