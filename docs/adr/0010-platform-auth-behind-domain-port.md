# ADR 0010: Firebase Phone Auth Nằm Sau Domain Port

- Trạng thái: Accepted
- Ngày: 2026-10-01

## Bối cảnh

`AuthUseCase` trước đây import `firebase_auth`, giữ verification ID và gọi SDK
trực tiếp. Điều này trái với rule `presentation → domain ← data`, khiến domain
khó unit-test và làm optional Firebase trong tương lai khó tách.

## Quyết định

- Domain sở hữu `PhoneVerificationRepo` và `PhoneVerificationFailure` không phụ
  thuộc Flutter/Firebase.
- Data sở hữu `FirebasePhoneVerificationRepo`: SDK callback, verification ID,
  map SDK exception thành failure có code và bỏ qua callback của request cũ.
- `AuthUseCase` chỉ format số điện thoại và gọi domain port. DI module tạo
  UseCase bằng provider `@lazySingleton`; domain source không import Injectable.
- Architecture gate chặn Firebase, Flutter, Dio, GetIt và Injectable import
  trong `lib/domain`.

## Hệ quả

- Cubit/UseCase test không cần Firebase plugin; một app khác có thể thay adapter
  qua DI mà không sửa domain contract.
- Sample hiện **vẫn** dùng Firebase Auth và `Firebase.initializeApp()` ở
  bootstrap. ADR này không biến Firebase thành optional module ngay.
- Error code từ SDK được giữ dưới dạng domain failure để UI có thể map sang
  l10n sau này; không truyền nguyên SDK exception qua domain.
