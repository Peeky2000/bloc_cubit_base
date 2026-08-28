# ADR 0004: Dùng REST Mặc Định

- Trạng thái: Accepted
- Ngày: 2026-08-26

## Quyết định

REST/Dio là network stack mặc định. GraphQL là module tùy chọn, có thể gỡ bỏ,
chỉ thêm khi sản phẩm thật cần.

## Hệ quả

Base tránh dependency schema/codegen chưa dùng tới nhưng vẫn giữ extension point
được tài liệu hóa.
