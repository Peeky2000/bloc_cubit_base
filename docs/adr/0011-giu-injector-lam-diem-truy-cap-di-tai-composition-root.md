# ADR 0011: Giữ Injector làm điểm truy cập DI tại composition root

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: project
- Tags: di, injector, getit, composition-root
- Tính năng:
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Review kiến trúc ngày 2026-10-08 (mục 4) đề xuất bỏ lớp `Injector` trong
`lib/di/injection.dart` vì nó chỉ chuyển tiếp sang `GetIt.instance`. Đề xuất
đó đã được làm rồi hoàn tác. PM (chủ base) quyết định giữ `Injector`: đây là
điểm truy cập DI quen thuộc của app và của các app fork từ base.

## Quyết định

Giữ `Injector` làm điểm truy cập DI chính thức của app. Composition root lấy
dependency bằng `Injector.getIt.get<T>()`. Feature class không dùng nó.

| Nơi | Được dùng `Injector` |
|---|---|
| Route builder (`xxxScreenBuilder()`), `MainApp`, `bootstrap`, DI module | Có |
| Cubit/BLoC, use case, repository, data source, widget | Không, nhận qua constructor |

`derry scaffold` sinh route builder theo đúng mẫu này.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Bỏ `Injector`, dùng biến `getIt` trực tiếp ở composition root | Mất điểm truy cập quen thuộc và đồng nhất giữa các app; lợi ích chỉ là bớt một lớp mỏng |
| Cho mọi class tự gọi `Injector` | Phá constructor injection, khó test; đã cấm từ ADR-0001 |

## Hệ quả

- Không đề xuất bỏ `Injector` trong review sau, trừ khi có ADR mới thay thế.
- Quy tắc constructor injection của ADR-0001 giữ nguyên. Gate kiến trúc và luật
  convention tiếp tục chặn `Injector`, `getIt` và `GetIt.instance` trong
  Cubit/BLoC, domain và data.
- Code mẫu: `lib/di/injection.dart`, `lib/presentation/sign_in/view/sign_in_screen.dart`,
  `tool/scaffold/scaffold.dart`.
