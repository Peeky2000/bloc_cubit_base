# Dependency Injection

Base dùng `get_it` làm container runtime và `injectable` làm generator cho
registration.

## Quy tắc

- Thêm `@injectable`, `@lazySingleton`, hoặc `@singleton` cho class do app sở
  hữu.
- Bind repository/data-source implementation vào abstract contract bằng
  `@LazySingleton(as: Contract)`.
- Cubit và BLoC là factory (`@injectable`) trừ khi application lifetime được
  quyết định rõ bằng ADR.
- Dùng `@module` cho SDK class, plugin, async initialization, và factory cần
  runtime configuration.
- Feature class không được gọi `Injector.getIt`.
- Entry point có thể truyền environment được chọn vào composition root. Đây là
  runtime registration có chủ ý duy nhất.

Sinh registration bằng `derry gen` hoặc `dart run build_runner build`.
