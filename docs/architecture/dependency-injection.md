# Dependency Injection

Base dùng `get_it` làm container runtime và `injectable` làm generator cho
registration.

## Quy tắc

- Thêm `@injectable`, `@lazySingleton`, hoặc `@singleton` cho class ở
  presentation/data/core khi đúng lifetime. Domain class thuần không mang
  annotation; đăng ký UseCase bằng provider `@lazySingleton` trong
  `lib/di/register_module.dart`.
- Bind repository/data-source implementation vào abstract contract bằng
  `@LazySingleton(as: Contract)`.
- Cubit và BLoC là factory (`@injectable`) trừ khi application lifetime được
  quyết định rõ bằng ADR.
- Dùng `@module` cho SDK class, plugin, async initialization, và factory cần
  runtime configuration; đây cũng là nơi bind domain UseCase thuần.
- Feature class không được gọi `Injector.getIt`.
- Entry point có thể truyền environment được chọn vào composition root. Đây là
  runtime registration có chủ ý duy nhất.

Sinh registration bằng `derry gen` hoặc `dart run build_runner build`.

## Reset trong test

`configureDependencies(config, reset: true)` dispose registration hiện tại
trước khi init graph mới. Unit test có thể truyền `initializeGraph` để đăng ký
test double thuần Dart mà không khởi tạo Firebase, secure storage hoặc platform
channel. Production không truyền tham số này và luôn dùng generated graph.
