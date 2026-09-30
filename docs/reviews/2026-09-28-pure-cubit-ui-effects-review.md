# Review Pure Cubit Và Typed UI Effect — 2026-09-28

## Kết luận

Legacy auth/startup state managers đã được tách hoàn toàn khỏi widget tree.
`SignInCubit`, `SignUpCubit`, `ResetPasswordCubit`,
`ConfirmInformationCubit` và `SplashCubit` không còn giữ `AppController`, đọc
route argument, dịch ARB, mở dialog hoặc gọi `SLIRouting`.

Screen hiện sở hữu route/dialog/localization qua typed `UiEffect`; validation
business dùng enum có kiểu. Phase 4 task “gỡ BuildContext/service locator khỏi
feature state manager” đã hoàn tất.

## Thay đổi chính

- Thêm `UiEffect<T>` revisioned vào `BaseCubit` và `BaseBloc`.
- Thêm `listenWhen` cho `LoadingScreen` để one-shot effect không bị phát lại do
  state render khác thay đổi.
- Chuyển năm flow auth/startup sang effect sealed class riêng.
- Chuyển phone/email/password/required validation từ localized `String` sang
  enum trong `core/validation`.
- `ErrorMapper` trở thành hàm thuần, không đọc GetIt/context và không phụ thuộc
  data model.
- `handleErrorResponse` nhận `BuildContext` tường minh tại Screen.
- Route argument của confirm phone được đọc tại Screen rồi truyền vào Cubit qua
  `initialize`.
- Timer OTP chỉ khởi động/reset khi Firebase gọi `codeSent`; callback tới sau
  khi Cubit đóng được bỏ qua.
- Resend OTP của reset-password đã được nối vào Cubit thay vì callback rỗng.
- Architecture gate cấm UI/routing/l10n/`BuildContext` trong thư mục Cubit.

## Evidence

| Contract | Evidence |
|---|---|
| Không còn UI coupling trong Cubit | `rg` trên `presentation/**/cubit` sạch và architecture gate pass |
| Repeated one-shot command | Hai effect cùng loại có revision khác nhau |
| Validation không cần l10n | Sign-in invalid input test bằng typed enum |
| Login success/error | Test navigation intent và retryable error intent |
| OTP send callback | Test success, failure và callback sau `close()` |
| Pure error mapping | Test network/general/server/fallback không cần context |
| Generated DI | `derry gen` pass sau khi bỏ `AppController` khỏi constructor |

## Quality gates

| Gate | Kết quả |
|---|---|
| `derry gen` | Pass; generated Injectable graph được cập nhật |
| `./scripts/format.sh --check` | Pass; 191 Dart files, 0 changed |
| `flutter analyze` | Pass; 0 finding |
| `./scripts/check_architecture.sh` | Pass, gồm pure-Cubit rule mới |
| `flutter test` | Pass; 54 tests |
| Focused UI-effect/error/auth tests | Pass; 10 tests |

## Debt còn lại

1. Phase 4 base-state task vẫn mở: cần concrete `BaseBloc` representative và
   test đủ initial/loading/success/failure trước khi đánh dấu hoàn tất toàn phase.
2. `AuthUseCase` còn bọc Firebase Auth trực tiếp trong domain-oriented API; đây
   là boundary cleanup riêng, không làm Cubit phụ thuộc UI.
3. UI compatibility migration sang `sli_common`, neutral branding và full
   historical analyzer của `sli_common` vẫn theo roadmap.
4. Version Health/Firebase Observability vẫn là future scope cuối cùng.
