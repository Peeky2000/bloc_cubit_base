# Kiến Trúc

`bloc_cubit_base` là base Flutter tái sử dụng, xây quanh Clean Architecture.
Thư mục này là source of truth cho các quyết định cấu trúc; code, tests,
automation, và hướng dẫn `.agents` phải thống nhất với nó.

## Quyết định lõi

- [Quy tắc dependency](dependency-rules.md)
- [Dependency injection](dependency-injection.md)
- [Quản lý state](state-management.md)
- [Môi trường và bootstrap](environment-bootstrap.md)
- [Networking](networking.md)
- [UI toolkit](ui-toolkit.md)
- [Năng lực tùy chọn](optional-capabilities.md)

## Chiều dependency

```text
presentation -> domain <- data
      |            ^        |
      +---------- core -----+
```

Flow feature là `UI -> Cubit/BLoC -> UseCase -> Repository -> DataSource`.
Composition chỉ diễn ra trong `lib/di`. Runtime infrastructure có thể phụ thuộc
contract trong `core`, nhưng domain code không bao giờ import data hoặc
presentation code.

## Bản ghi quyết định

Xem [`docs/adr`](../adr/README.md). Quyết định kiến trúc làm thay đổi hành vi
cần có ADR trước khi implement.
