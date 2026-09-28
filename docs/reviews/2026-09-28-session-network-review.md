# Review Session Và Network — 2026-09-28

## Kết luận

Phase 6 session refresh đã được gia cố và khóa bằng test deterministic. Nhiều
request 401 cùng token chỉ tạo một refresh operation; request được replay bằng
token mới mà không làm rò Bearer token sang cross-origin host. Terminal failure
được coalesce, còn lỗi transient/403/retry 500 không làm logout oan.

Typed session-expired event và lifecycle `NetworkChecker` cũng đã được nối và
test trong follow-up cùng ngày. UI side effect thuộc `MainApp` qua
`BlocListener`; network/data không import hoặc gọi navigation.

## Revision được review

| Repository | Revision | Phạm vi |
|---|---|---|
| `bloc_cubit_base` | `9b7e990` | Session refresh hardening, token revision và network/session tests |
| `bloc_cubit_base` | `d9f855e` | Typed session event, AppCubit listener contract và NetworkChecker lifecycle |

## Thay đổi chính

- `SessionInterceptor` dùng dedicated session Dio được inject thay vì tự tạo
  transport không kiểm soát.
- Chỉ first-party 401 có Bearer token mới được refresh; 403 và cross-origin 401
  được forward nguyên trạng.
- Refresh single-flight gắn với token snapshot/revision. Kết quả cũ sau
  logout/login không thể ghi đè session mới.
- Terminal refresh failure hoặc retry vẫn 401 chỉ gọi expiry callback một lần
  cho mỗi token generation.
- Refresh timeout/connection/5xx và retry 500 giữ nguyên credential.
- Retry tạo `RequestOptions` copy; clone `FormData`; không replay stream body.
- Token write/delete được serialize; `setTokenIfRevision` cung cấp
  compare-and-set cho refresh commit.
- Network offline contract được test qua in-memory Dio adapter, không dùng socket
  hoặc timer thật.
- `SessionExpiryCoordinator` sở hữu cleanup + publish; `AppCubit` nhận typed
  event; presentation điều hướng và thông báo qua `BlocListener`.
- Connectivity và internet reachability được bọc bằng monitor interface;
  repeated init/dispose được test mà không gọi platform channel.

## Evidence matrix

| Contract | Evidence |
|---|---|
| 8 response 401 đồng thời | Đúng 1 refresh, 8 replay và tất cả dùng token mới |
| Refresh credential bị từ chối | 1 refresh, 0 replay, clear/expiry đúng 1 lần cho cả wave |
| Refresh 500 transient | Session cũ được giữ, không clear/expiry |
| Retry 500 | Token mới được giữ, không clear/expiry |
| Retry vẫn 401 | Session mới expire đúng 1 lần, không loop |
| 403 permission denial | Không refresh và không expire |
| Login/signup/refresh/explicit opt-out | Không refresh hoặc replay |
| Absolute external 401 | Không gắn internal Bearer và không dùng session client |
| Request account cũ sau login account mới | Không replay bằng token account mới |
| Refresh account cũ trả về muộn | Không ghi đè token account mới |
| Refresh response không rotate refresh token | Giữ refresh token hợp lệ trước đó |
| Multipart retry | Clone `FormData` và rebuild content-type boundary |
| Offline `false` | Reject trước transport bằng connection error có `NetworkIssueException` |
| Connectivity `null/true` | Cho request đi tiếp tới transport |
| Token storage race | Secure-storage operation chạy tuần tự, stale revision không được persist |
| Typed terminal expiry | Cleanup chạy trước publish; event vẫn phát nếu secure delete báo lỗi |
| App session listener | Mỗi typed event tăng đúng một app-state revision; Cubit hủy subscription khi close |
| NetworkChecker lifecycle | Repeated init chỉ giữ một listener; transition dedupe; dispose idempotent và chặn re-init |

## Quality gates

| Gate | Kết quả |
|---|---|
| `./scripts/format.sh --check` | Pass; 181 Dart files, 0 changed |
| `flutter analyze` | Pass; 0 finding |
| `./scripts/check_architecture.sh` | Pass |
| `flutter test` | Pass; 44 tests |
| Focused session/network/token/lifecycle tests | Pass; 23 tests |
| `git diff --check` | Pass |

Full gate được chạy bằng `./scripts/quality.sh`; focused test dùng bảy file:

- `test/data/datasource/remote/interceptor/session_interceptor_test.dart`
- `test/data/datasource/remote/interceptor/network_interceptor_test.dart`
- `test/data/datasource/local/token_provider_test.dart`
- `test/data/datasource/local/session_expiry_coordinator_test.dart`
- `test/core/session/session_event_test.dart`
- `test/core/app/app_cubit_test.dart`
- `test/core/network/network_checker_test.dart`

## Debt còn lại

1. Auth endpoint policy hiện skip login/signup/refresh cùng explicit request
   flag; product mới phải khai báo rõ endpoint công khai khác nếu có.
2. Performance/network observability qua Firebase được hoãn tới future scope,
   sau khi core base và neutral template hoàn tất.

Roadmap và trạng thái sống được cập nhật tại
[modernization plan](../plan/2026-08-26-base-modernization.md) và
[modernization status](../modernization-status.md).
