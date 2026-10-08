# Sổ quyết định kỹ thuật

Trang này được sinh bởi `python3 tool/decisions/decisions.py index`. Không sửa
tay phần bảng; sửa file quyết định rồi chạy lại lệnh.

Trước khi chọn một cách làm, tìm quyết định cũ:

```bash
python3 tool/decisions/decisions.py search "phân trang"
```

Quyết định cấp tính năng nằm trong thư mục này (`D-NNNN`). Quyết định ảnh
hưởng toàn dự án là ADR trong `docs/adr/`. Cách viết và vòng đời ở
[HOW-TO.md](HOW-TO.md).

## Đang áp dụng

| Mã | Quyết định | Trạng thái | Phạm vi | Tags | Ngày |
|---|---|---|---|---|---|
| [ADR-0001](../adr/0001-get-it-injectable.md) | Dùng GetIt với Injectable | accepted | project |  | 2026-08-26 |
| [ADR-0002](../adr/0002-cubit-default-bloc-supported.md) | Dùng Cubit Mặc Định và Hỗ Trợ BLoC | accepted | project |  | 2026-08-26 |
| [ADR-0003](../adr/0003-equatable-state.md) | Giữ State Ứng Dụng Bằng Equatable | accepted | project |  | 2026-08-26 |
| [ADR-0004](../adr/0004-rest-default.md) | Dùng REST Mặc Định | accepted | project |  | 2026-08-26 |
| [ADR-0005](../adr/0005-keep-sli-routing.md) | Giữ SLIRouting | accepted | project |  | 2026-08-26 |
| [ADR-0006](../adr/0006-ui-toolkit-now-defer-product-capabilities.md) | Xây UI Toolkit Trước và Hoãn Năng Lực Sản Phẩm | accepted | project |  | 2026-08-26 |
| [ADR-0007](../adr/0007-dart-base-cli-behind-derry.md) | Dart Base CLI Phía Sau Derry Facade | accepted | project |  | 2026-08-28 |
| [ADR-0008](../adr/0008-mobile-engineering-skills-no-viper.md) | Skill Tập Trung Flutter/Mobile, Không Adopt VIPER | accepted | project |  | 2026-09-28 |
| [ADR-0009](../adr/0009-typed-ui-effects-at-presentation-boundary.md) | Typed UI Effect Tại Presentation Boundary | accepted | project |  | 2026-09-28 |
| [ADR-0010](../adr/0010-platform-auth-behind-domain-port.md) | Firebase Phone Auth Nằm Sau Domain Port | accepted | project |  | 2026-10-01 |

## Đang chờ duyệt

Chưa có.

## Đã thay thế hoặc bị từ chối

Chưa có.

## Thuật ngữ

Tên dùng thống nhất trong code nằm ở [glossary.md](glossary.md).
