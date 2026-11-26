# 3. Kiến trúc

```text
Screen ─▶ Cubit/BLoC ─▶ UseCase ─▶ Repository (interface)
                                         ▲
                     RepositoryImpl ─────┘ ─▶ DataSource ─▶ Dio / SDK

presentation ─▶ domain ◀─ data
```

## Thư mục

```text
lib/
  core/           cấu hình app, bootstrap, mạng, routing, observability
  data/           model JSON, data source, repository impl
  domain/         entity, repository interface, use case (Dart thuần)
  presentation/   <feature>/cubit + <feature>/view
  widget/         widget riêng của app (dùng sli_common trước)
  di/             Injector và cấu hình get_it sinh ra
  l10n/           chuỗi dịch ARB
  modules/        sli_common (submodule)
```

## Luật bị kiểm tra tự động

`derry quality` (và CI) chặn khi vi phạm:

1. **Thứ tự tầng:** Entity → Model → DataSource → Repository → UseCase →
   Cubit/BLoC → Screen → Route → l10n → DI.
2. **Domain thuần Dart:** không import Flutter, data, SDK hay DI.
3. **Constructor injection:** chỉ route builder, `MainApp`, `bootstrap` và DI
   module được gọi `Injector.getIt.get<T>()`.
4. **Cubit không biết UI:** không `BuildContext`, không điều hướng, không chuỗi
   dịch. Việc một lần (điều hướng, dialog) đi qua `UiEffect<T>` có kiểu, Screen
   xử lý (ADR-0009).
5. **Không sửa `lib/di/injection.config.dart`:** gắn annotation rồi `derry gen`.
6. **UI dùng token:** khoảng cách, bo góc lấy `SliSpacing`/`SliRadii`; icon lấy
   `SliIcons`; chữ hiển thị lấy từ l10n.

## Đọc thêm khi cần

| Chủ đề | Tài liệu |
|---|---|
| Luật dependency đầy đủ | [dependency-rules](../docs/architecture/dependency-rules.md) |
| State, Cubit hay BLoC | [state-management](../docs/architecture/state-management.md) · [UI effect](../docs/guides/handle-ui-effects.md) |
| DI | [dependency-injection](../docs/architecture/dependency-injection.md) |
| Gọi API, token, refresh | [networking](../docs/architecture/networking.md) |
| Widget và `sli_common` | [ui-toolkit](../docs/architecture/ui-toolkit.md) · [dùng sli_common](../docs/guides/use-sli-common.md) |
| Vì sao chọn vậy | [ADR](../docs/adr/README.md) · [sổ quyết định](../docs/decisions/README.md) |

Tiếp: [Làm một tính năng](04-lam-mot-tinh-nang.md).
