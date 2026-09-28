# Review Session Và Network — 2026-09-28

## Kết luận

Phase 6 session refresh đã được gia cố và khóa bằng test deterministic. Nhiều
request 401 cùng token chỉ tạo một refresh operation; request được replay bằng
token mới mà không làm rò Bearer token sang cross-origin host. Terminal failure
được coalesce, còn lỗi transient/403/retry 500 không làm logout oan.

Review này **không** tuyên bố app đã có typed session-expired event hoặc
`NetworkChecker` đã được test toàn bộ lifecycle init/dispose. Hai phần đó vẫn
được track riêng trong roadmap.

## Revision được review

| Repository | Revision | Phạm vi |
|---|---|---|
| `bloc_cubit_base` | `9b7e990` | Session refresh hardening, token revision và network/session tests |

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

## Quality gates

| Gate | Kết quả |
|---|---|
| `./scripts/format.sh --check` | Pass; 174 Dart files, 0 changed |
| `flutter analyze` | Pass; 0 finding |
| `./scripts/check_architecture.sh` | Pass |
| `flutter test` | Pass; 36 tests |
| Focused session/network/token tests | Pass; 18 tests |
| `git diff --check` | Pass |

Full gate được chạy bằng `./scripts/quality.sh`; focused test dùng ba file:

- `test/data/datasource/remote/interceptor/session_interceptor_test.dart`
- `test/data/datasource/remote/interceptor/network_interceptor_test.dart`
- `test/data/datasource/local/token_provider_test.dart`

## Debt còn lại

1. `ApiClient` hiện truyền `tokenProvider.clearToken` làm terminal callback.
   Cần một typed session coordinator để vừa cleanup credential vừa phát đúng
   một app-level event cho presentation listener.
2. `NetworkChecker` chưa có seam để test repeated init/dispose và transition
   giữa connectivity signal với internet reachability.
3. Auth endpoint policy hiện skip login/signup/refresh cùng explicit request
   flag; product mới phải khai báo rõ endpoint công khai khác nếu có.
4. Performance/network observability qua Firebase được hoãn tới future scope,
   sau khi core base và neutral template hoàn tất.

Roadmap và trạng thái sống được cập nhật tại
[modernization plan](../plan/2026-08-26-base-modernization.md) và
[modernization status](../modernization-status.md).
