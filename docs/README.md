# Mục Lục Tài Liệu — Bắt Đầu Tại Đây

Đây là cửa vào trung tâm cho toàn bộ tài liệu của `bloc_cubit_base`. Người mới
không cần đọc tất cả ngay; hãy chọn đúng mục tiêu trong bảng dưới đây rồi đi theo
đường dẫn được đề xuất.

## Tôi muốn làm gì?

| Mục tiêu | Đọc theo thứ tự |
|---|---|
| Bắt đầu làm quen với base | [README gốc](../README.md) → [điều kiện dự án](prerequisites.md) → [tổng quan kiến trúc](architecture/README.md) → [trạng thái hiện tại](modernization-status.md) |
| Cài project và chạy lần đầu | [Điều kiện dự án](prerequisites.md) → [Derry/build/Fastlane](guides/use-derry-and-build.md) |
| Tạo app mới từ base | [Tạo app từ base](guides/create-app-from-base.md) → [trạng thái hiện tại](modernization-status.md) |
| Thêm feature mới | [Thêm feature](guides/add-feature.md) → [quy tắc dependency](architecture/dependency-rules.md) → [chọn Cubit/BLoC](guides/choose-cubit-or-bloc.md) |
| Thêm hoặc sửa DI | [Kiến trúc DI](architecture/dependency-injection.md) → [ADR Injectable](adr/0001-get-it-injectable.md) |
| Làm Cubit/BLoC hoặc state | [Quản lý state](architecture/state-management.md) → [chọn Cubit/BLoC](guides/choose-cubit-or-bloc.md) |
| Làm API, Dio hoặc token | [Networking](architecture/networking.md) → [quy tắc dependency](architecture/dependency-rules.md) |
| Làm widget/design system | [UI toolkit](architecture/ui-toolkit.md) → [dùng sli_common](guides/use-sli-common.md) |
| Thêm môi trường/flavor | [Environment và bootstrap](architecture/environment-bootstrap.md) → [thêm môi trường](guides/add-environment.md) |
| Build APK/AAB/IPA | [Derry/build/Fastlane](guides/use-derry-and-build.md) |
| Phân phối Firebase hoặc Store | [Derry/build/Fastlane](guides/use-derry-and-build.md) → [Android Fastlane](../android/fastlane/README.md) / [iOS Fastlane](../ios/fastlane/README.md) |
| Xem vì sao chọn công nghệ hiện tại | [Danh sách ADR](adr/README.md) |
| Xem việc đã làm và việc còn lại | [Trạng thái modernization](modernization-status.md) → [roadmap](plan/2026-08-26-base-modernization.md) |
| Xem bằng chứng review/quality gate | [Review mới nhất](reviews/2026-08-28-component-catalog-base-cli-review.md) |
| Làm việc cùng AI agent | [Quy trình AI](../ai-process.md) → [AGENTS.md](../AGENTS.md) |

## Lộ trình onboarding khuyến nghị

Người mới vào project nên hoàn thành theo thứ tự:

1. Đọc [README gốc](../README.md) để hiểu mục tiêu và stack của base.
2. Đọc [điều kiện dự án](prerequisites.md) và cài đúng Flutter/Derry/submodule.
3. Chạy `derry bootstrap`, sau đó chạy `derry quality` để xác nhận máy local.
4. Đọc [tổng quan kiến trúc](architecture/README.md) và
   [quy tắc dependency](architecture/dependency-rules.md).
5. Đọc [trạng thái modernization](modernization-status.md) để không nhầm phần
   foundation đã hoàn tất với legacy debt đang chờ xử lý.
6. Chọn guide đúng với task chuẩn bị làm.

## Vòng đời tài liệu

```text
Brainstorm / Spec
        ↓
Quyết định được duyệt / ADR
        ↓
Implementation plan / Checklist
        ↓
Code + tests + quality gates
        ↓
Review
        ↓
Modernization status + Changelog
```

| Loại tài liệu | Trả lời câu hỏi | Vị trí |
|---|---|---|
| Brainstorm | Vấn đề là gì, có những phương án và rủi ro nào? | [`docs/brainstorm/`](brainstorm/) |
| Spec | Feature phải làm gì và contract là gì? | [`docs/specs/`](specs/) |
| ADR | Vì sao team chấp nhận một quyết định kiến trúc? | [`docs/adr/`](adr/) |
| Architecture | Kiến trúc và convention hiện hành là gì? | [`docs/architecture/`](architecture/) |
| Plan | Triển khai theo thứ tự nào, file nào và verify ra sao? | [`docs/plan/`](plan/) |
| Guide | Thực hiện một công việc cụ thể như thế nào? | [`docs/guides/`](guides/) |
| Review | Code hiện tại đúng/sai ở đâu và đã verify gì? | [`docs/reviews/`](reviews/) |
| Status | Foundation nào đã xong, debt nào còn lại? | [modernization-status.md](modernization-status.md) |
| Changelog | Release hoặc đợt thay đổi đã mang lại điều gì? | [CHANGELOG.md](../CHANGELOG.md) |

## Source of truth và thứ tự ưu tiên

Khi hai tài liệu có vẻ mâu thuẫn, dùng thứ tự sau:

1. Architecture hiện hành và ADR đã được chấp nhận.
2. `prerequisites.md` cùng quality gate chạy được trong repository.
3. Guide triển khai hiện hành.
4. Plan và modernization status.
5. Review tại thời điểm cụ thể.
6. Brainstorm — chỉ là phân tích đầu vào, không tự động trở thành quyết định.

Nếu code khác architecture/ADR, không mặc định coi code là chuẩn. Hãy xác định
đó là legacy debt hay tài liệu đã lỗi thời, sau đó cập nhật code và tài liệu
trong cùng thay đổi.

## Mục lục kiến trúc

| Chủ đề | Tài liệu |
|---|---|
| Tổng quan và dependency flow | [architecture/README.md](architecture/README.md) |
| Quy tắc import/layer | [dependency-rules.md](architecture/dependency-rules.md) |
| GetIt + Injectable | [dependency-injection.md](architecture/dependency-injection.md) |
| Cubit/BLoC và state contract | [state-management.md](architecture/state-management.md) |
| Flavor, config và bootstrap | [environment-bootstrap.md](architecture/environment-bootstrap.md) |
| Dio, token, refresh 401 và inspector | [networking.md](architecture/networking.md) |
| `sli_common`, Shadcn và ownership UI | [ui-toolkit.md](architecture/ui-toolkit.md) |
| GraphQL/FCM/deep link và phần tùy chọn | [optional-capabilities.md](architecture/optional-capabilities.md) |

## Mục lục hướng dẫn

| Công việc | Tài liệu |
|---|---|
| Tạo application từ base | [create-app-from-base.md](guides/create-app-from-base.md) |
| Thêm feature Clean Architecture | [add-feature.md](guides/add-feature.md) |
| Chọn Cubit hay BLoC | [choose-cubit-or-bloc.md](guides/choose-cubit-or-bloc.md) |
| Thêm environment/flavor | [add-environment.md](guides/add-environment.md) |
| Dùng UI toolkit cá nhân | [use-sli-common.md](guides/use-sli-common.md) |
| Tra hình/API/maturity của component | [`sli_common` catalog](../lib/modules/sli_common/docs/catalog/README.md) |
| Dùng Derry, build và delivery | [use-derry-and-build.md](guides/use-derry-and-build.md) |

## Mục lục quyết định kiến trúc

| Quyết định | ADR |
|---|---|
| DI dùng GetIt + Injectable | [ADR-0001](adr/0001-get-it-injectable.md) |
| Cubit mặc định, BLoC vẫn được hỗ trợ | [ADR-0002](adr/0002-cubit-default-bloc-supported.md) |
| State dùng Equatable + copyWith | [ADR-0003](adr/0003-equatable-state.md) |
| REST mặc định, GraphQL tùy chọn | [ADR-0004](adr/0004-rest-default.md) |
| Giữ SLIRouting/AppPage | [ADR-0005](adr/0005-keep-sli-routing.md) |
| Xây UI toolkit trước, capability sản phẩm thêm sau | [ADR-0006](adr/0006-ui-toolkit-now-defer-product-capabilities.md) |
| Dart Base CLI phía sau Derry facade | [ADR-0007](adr/0007-dart-base-cli-behind-derry.md) |

## Truy vết modernization hiện tại

| Artifact | Vai trò |
|---|---|
| [Baseline review](reviews/2026-08-26-base-modernization-baseline.md) | Trạng thái trước modernization |
| [Roadmap modernization](plan/2026-08-26-base-modernization.md) | Checklist tổng và Definition of Done |
| [Review modernization mới nhất](reviews/2026-08-27-base-modernization-review.md) | Evidence, quality gate và follow-up đã xác minh |
| [Review catalog + Base CLI](reviews/2026-08-28-component-catalog-base-cli-review.md) | Evidence inventory, safety gates và create smoke test |
| [Trạng thái modernization](modernization-status.md) | Bản tóm tắt sống về phần đã xong/chưa xong |
| [Brainstorm Derry/build](brainstorm/2026-08-27-derry-build-automation.md) | Lý do tách build, distribute và release |
| [Brainstorm component catalog](brainstorm/2026-08-28-ui-component-catalog-and-migration.md) | Inventory baseline và lý do phải catalog trước khi migrate widget |
| [Plan catalog + Base CLI](plan/2026-08-28-component-catalog-and-base-cli.md) | Checklist triển khai đã duyệt cho toolbox docs và create/rename workflow |

## Quy tắc duy trì mục lục

- Tài liệu mới phải được link từ file mục lục này hoặc từ một index con.
- Thay đổi kiến trúc phải cập nhật architecture, ADR liên quan, guide và status
  trong cùng pull request/commit.
- Brainstorm, plan và review phải có ngày trong tên file để truy vết theo thời
  gian.
- Review phải ghi rõ command đã chạy, kết quả thật và debt còn lại.
- Không đánh dấu roadmap hoàn tất chỉ vì code compile; Definition of Done và
  quality gate tương ứng phải pass.
- Khi một tài liệu bị thay thế, ghi link tới tài liệu mới thay vì để hai source
  of truth cạnh tranh nhau.

Quy trình đầy đủ dành cho AI và contributor nằm tại
[ai-process.md](../ai-process.md).
