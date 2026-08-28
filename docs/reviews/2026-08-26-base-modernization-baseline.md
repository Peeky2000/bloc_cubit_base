# Baseline Trước Modernization

Ngày: 2026-08-26

## Commands

- `flutter pub get`: pass; lockfile resolve với Flutter 3.44.5 / Dart 3.12.2.
- `flutter analyze`: fail với 162 issues.
- `flutter test`: chưa chạy tới vì command analyze trong chuỗi đã fail.

## Nhóm issue có sẵn chính

- Package identifier legacy `bloc_cubit_base` không hợp lệ và naming phụ thuộc
  sản phẩm.
- Thiếu asset `.env` và cấu hình môi trường mutable dùng string key.
- Flutter API deprecated và lint naming legacy.
- Service-locator access thủ công trong presentation và network interceptor.
- Vi phạm boundary domain-to-data và presentation-to-data.
- Cây `lib/modules/sli_common` nhúng rỗng thay vì Git submodule.

File này ghi lại debt trước migration. Work mới phải giảm số lượng issue và
không được che issue bằng analyzer exclusion hoặc tắt lint rule.
