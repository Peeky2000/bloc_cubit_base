# Thêm Feature

Chỉ thêm layer mà feature thật sự cần, đồng thời giữ đúng thứ tự dependency:

```text
Entity → Model → DataSource → Repository → UseCase → Cubit/BLoC → Screen
```

## Checklist

1. Tìm trong app-memory, `sli_common`, routes, và domain code tương tự.
2. Định nghĩa domain value/contract thuần; không expose JSON model.
3. Thêm request/response model bằng `json_serializable` trong data.
4. Thêm abstract data source và implementation có injectable quanh `ApiHandler`
   hoặc local storage abstraction.
5. Thêm domain repository contract và bind `RepoImpl` bằng
   `@LazySingleton(as: Repo)`.
6. Thêm UseCase inject qua constructor để orchestration.
7. Chọn Cubit hoặc BLoC theo [guide quyết định](choose-cubit-or-bloc.md), gắn
   `@injectable`, và unit-test transition.
8. Tạo một screen mỏng. Resolve owner của state một lần trong builder và
   localize mọi text hiển thị cho user.
9. Register `AppPage`/`SLIPage`, cập nhật ARB, và tái sử dụng component `Sli*`.
10. Chạy `derry gen`, `derry quality`, và cập nhật app-memory/docs.

Không đặt `BuildContext`, navigation, localization, Dio, hoặc service-locator
call trong domain/business logic.
