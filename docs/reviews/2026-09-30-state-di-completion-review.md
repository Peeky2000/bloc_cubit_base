# Review Hoàn Tất State Convention Và DI Reset — 2026-09-30

## Kết luận

Hai checklist còn mở của Phase 3 và Phase 4 đã được đóng bằng implementation
và test. Dependency graph có thể reset/dispose deterministic trong test mà
không cần khởi tạo plugin platform. State base hỗ trợ failure generic có kiểu;
cả Cubit và BLoC đại diện đều cover initial/loading/success/failure.

## Thay đổi chính

- `configureDependencies` nhận optional `DependencyGraphInitializer` để test
  composition lifecycle; production vẫn mặc định gọi generated `getIt.init()`.
- `reset: true` dispose graph cũ trước khi tạo graph mới.
- `BaseAppState<Failure extends Object>` cho phép feature chọn failure type cụ
  thể trong khi legacy state tiếp tục dùng `Object` rõ ràng.
- `BaseCubit` và `BaseBloc` dùng chung contract state generic.
- Page transition của SignUp/ResetPassword cũng được chuyển thành typed effect,
  loại bỏ transient navigation state và nguy cơ xử lý lại effect cũ.

## Evidence

| Contract | Test |
|---|---|
| Repeated DI setup không leak registration | Graph 1 được dispose trước khi graph 2 register |
| Composition root identity | Initializer populate và trả đúng singleton GetIt root |
| Cubit state lifecycle | Initial, loading, complete và typed failure |
| BLoC state lifecycle | Named event tạo loading, complete và typed failure |
| One-shot page transition | SignUp/ResetPassword dùng revisioned effect, listener lọc effect change |

## Quality gate

Full gate cuối cùng: `derry gen` reproducible; 193 Dart files format sạch;
analyzer 0 finding; architecture gate pass; 62 tests pass. Focused gate cho
state/DI/auth effect có 16 test pass và `git diff --check` pass.

## Debt còn lại

Phase 3 và Phase 4 không còn checklist mở. Các phase còn lại tập trung vào
`sli_common`/Shadcn, compatibility migration, neutral branding và mobile
engineering skills. Version Health vẫn là future scope cuối cùng.
