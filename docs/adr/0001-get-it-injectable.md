# ADR 0001: Dùng GetIt với Injectable

- Trạng thái: Accepted
- Ngày: 2026-08-26

## Quyết định

Dùng GetIt làm container runtime và Injectable để sinh registration cho các class
thuộc quyền sở hữu của app. Việc chọn runtime environment và provider SDK bên
ngoài vẫn khai báo tường minh tại composition root. Mọi dependency của feature
được inject qua constructor.

## Hệ quả

Loại bỏ registration drift và các hàm setup thủ công quá lớn. Generated code
trở thành một phần của build pipeline, nên cần code generation và test giải
quyết object graph.
