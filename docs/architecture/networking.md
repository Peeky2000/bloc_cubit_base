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
- Session expiry được emit qua session contract và xử lý ở presentation.
- Log request/response mặc định redact authorization, cookies, tokens,
  passwords, và các field PII phổ biến.
- Alice chỉ khả dụng ngoài production.

GraphQL là năng lực tùy chọn và không thêm cho tới khi sản phẩm cần.
