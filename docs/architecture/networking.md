# Networking

REST qua Dio là transport mặc định. `ApiHandler` là adapter cho phía app sử
dụng, còn data source sở hữu việc parse response.

## Bảo mật và lifecycle

- Interceptor không bao giờ navigate, show dialog, hoặc đọc `BuildContext`.
- Authentication thêm credential qua token-store contract.
- Refresh là single-flight: nhiều response 401 đồng thời cùng chờ một refresh
  operation.
- Request refresh dùng Dio client riêng và không chạy đệ quy qua session
  interceptor.
- Chỉ 401 của first-party request có Bearer token mới được refresh. 403 là lỗi
  phân quyền mặc định; absolute/cross-origin request không bao giờ được gắn
  credential nội bộ khi retry.
- Một refresh wave chỉ commit nếu token revision vẫn khớp snapshot ban đầu;
  response cũ sau logout/login không được phục hồi hoặc ghi đè session mới.
- Refresh credential bị từ chối (400/401/403), thiếu refresh token hoặc retry
  vẫn 401 là terminal. Timeout/connection/5xx và retry 500 là transient, không
  được clear một session còn hợp lệ.
- Terminal expiry được coalesce tối đa một callback cho mỗi access-token
  generation. `SessionExpiryCoordinator` clear credential rồi phát typed event;
  `AppCubit` chuyển event thành state revision và `MainApp` phản ứng bằng
  `BlocListener`. Interceptor vẫn không điều hướng hoặc truy cập UI.
- Retry dùng request copy; `FormData` được clone và body dạng stream không được
  tự động replay.
- `NetworkInterceptor` chỉ reject khi `isConnected == false`, bằng
  `DioExceptionType.connectionError` chứa `NetworkIssueException`. Trạng thái
  `null` hoặc `true` được đi tiếp để transport quyết định.
- `NetworkChecker` là DI singleton có dispose callback. Repeated `init()` thay
  subscription cũ, `dispose()` idempotent và object đã dispose không được init
  lại; connectivity/reachability monitor có seam riêng để unit test không cần
  platform channel hoặc socket.
- Log request/response mặc định redact authorization, cookies, tokens,
  passwords, và các field PII phổ biến.
- Alice chỉ khả dụng ngoài production.

GraphQL là năng lực tùy chọn và không thêm cho tới khi sản phẩm cần.

Firebase Phone Auth của sample đi qua domain-owned `PhoneVerificationRepo`.
`FirebasePhoneVerificationRepo` ở data layer giữ SDK callback/verification ID,
map SDK exception thành `PhoneVerificationFailure` và bỏ qua callback của lần
request cũ. Domain UseCase không import Firebase SDK; việc tách Firebase Auth
thành optional product capability vẫn là quyết định riêng của Phase 8.
