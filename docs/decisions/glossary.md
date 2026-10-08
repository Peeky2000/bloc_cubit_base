# Thuật ngữ

Một khái niệm nghiệp vụ có đúng một tên trong code. Thêm dòng khi tài liệu mới
đưa ra từ mới; không đổi tên đã dùng nếu không có quyết định thay thế.

| Thuật ngữ trong tài liệu | Tên trong code | Ở đâu | Ghi chú |
|---|---|---|---|
| Tài khoản | `Account` | `lib/domain/entities/profile/account.dart` | Người dùng đã đăng nhập |
| Phiên đăng nhập | `SessionRepo` | `lib/domain/repositories/session_repo.dart` | Token và tài khoản đi cùng nhau |
| Xác thực số điện thoại | `PhoneVerificationRepo` | `lib/domain/repositories/phone_verification_repo.dart` | Kết quả `PhoneVerificationOutcome` |
| Ngôn ngữ ứng dụng | `AppLanguage` | `lib/domain/entities/common/app_enums.dart` | |
| Trạng thái tải | `LoadingStatus` | `lib/core/common/enum.dart` | `loadMore`, `noMoreData` dùng cho phân trang |
