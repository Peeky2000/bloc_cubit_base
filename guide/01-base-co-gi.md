# 1. Base có gì

Base Flutter cho app mobile mới. Ý tưởng chính (ADR-0012): base giữ **luật**,
**hạ tầng** và **bộ kiểm định**; màn hình của sản phẩm do agent sinh từ spec,
không chép từ màn mẫu.

## Có sẵn

| Phần | Nội dung | Ở đâu |
|---|---|---|
| Hạ tầng app | Bootstrap 4 môi trường (local, dev, staging, prod), DI `get_it + injectable`, Dio qua `ApiHandler` với refresh token, phiên đăng nhập, routing `SLIRouting`, l10n | `lib/core/`, `lib/di/`, `lib/data/` |
| Luồng mẫu | splash → đăng nhập → Tài khoản → đăng xuất, đủ để chạy thử hạ tầng. Màn Tài khoản được sinh từ spec `docs/specs/001-account/`, xem như ví dụ spec → code | `lib/presentation/` |
| UI toolkit | Submodule `sli_common`: token khoảng cách/bo góc, theme, `SliButton`, `SliSurface`, bottom sheet, `SliIcons` (Lucide), vài widget form | `lib/modules/sli_common/` |
| Luật code | Kiến trúc, ADR, sổ quyết định, convention kiểm tra tự động | `docs/architecture/`, `docs/adr/`, `docs/decisions/`, `test/convention/` |
| AI | 6 agent, 26 skill, 6 lệnh `/` cho Claude Code | `.agents/`, `.claude/commands/` |
| Bộ kiểm định | 8 mẫu kỹ thuật (phân trang, form, cache, upload ảnh, realtime, deep link, push, xin quyền) dạng test chạy được, dùng để so code agent sinh ra | `test/patterns/` |
| Công cụ | Sinh khung feature, gate kiến trúc, review plan, đo hiệu năng trên máy thật, tạo app mới từ base | `tool/`, `scripts/`, `derry.yaml` |
| Theo dõi phiên bản | Khung báo lỗi, analytics, đo hiệu năng, feature flag; mặc định tắt | `lib/core/observability/` |
| Build, phát hành | Derry, Fastlane, Firebase App Distribution, Store | `build.sh`, `ios/fastlane`, `android/fastlane` |

## Cố ý không có

- Màn đăng ký, quên mật khẩu, OTP, danh sách mẫu, widget "sưu tầm". Cần thì
  viết theo spec; bản cũ còn trong lịch sử git (ADR-0012).
- `go_router`, Freezed, Retrofit, GraphQL, HydratedBloc. Thêm khi sản phẩm cần
  và có quyết định ghi lại.

## Phiên bản

Flutter 3.50.1 (Dart 3.14, SDK `^3.14.0`), `material_ui`, Android AGP 9 /
Gradle 9.5 / Kotlin 2.4 / `compileSdk 37`, iOS 15 qua Swift Package Manager.
Chi tiết: [điều kiện dự án](../docs/prerequisites.md).

Tiếp: [Cài và chạy](02-cai-va-chay.md).
