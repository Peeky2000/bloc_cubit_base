# Review — Phone verification boundary (2026-10-01)

## Vấn đề

`AuthUseCase` import `firebase_auth`, gọi `verifyPhoneNumber` và giữ
verification ID. Điều này mâu thuẫn với quy tắc domain thuần trong
`docs/architecture/dependency-rules.md`; architecture gate cũ không bắt SDK
import ngoài `package:bloc_cubit_base/data`.

## Thay đổi

- `PhoneVerificationRepo`/`PhoneVerificationFailure` là contract domain.
- `FirebasePhoneVerificationRepo` giữ SDK callback và verification ID ở data,
  map exception theo code, bỏ qua callback từ request cũ.
- `AuthUseCase` chỉ normalize số, delegate và giữ method public cũ cho Cubit.
- `AppUseCase`/`AuthUseCase` không còn import Injectable; registration chuyển
  vào `RegisterModule`, generated graph được sinh lại bằng `derry gen`.
- Architecture gate chặn `firebase_*`, Flutter, Dio, GetIt, Injectable trong
  `lib/domain`.

## Evidence

- Focused tests: normalize/callback, typed failure, OTP delegation, failure
  mapping từ callback/throw, stale code-sent callback, stale request failure
  và Cubit lifecycle: **12/12 pass**.
- `derry gen` pass; generated DI bind `PhoneVerificationRepo` vào Firebase
  adapter và UseCase providers trong module.
- `derry quality` pass: app format 199 file, analyzer 0, architecture gate
  pass, **73 tests**; `sli_common` analyzer 0, **20 tests**.
- `rg` import trong `lib/domain` không còn Flutter/Firebase/HTTP/DI package.

## Giới hạn

Chưa chạy device-level Firebase SMS flow vì cần Firebase project, số test,
native client config và thiết bị; không tuyên bố E2E pass. Bootstrap sample
vẫn gọi `Firebase.initializeApp()`. Việc biến Firebase thành optional capability
và thay client config/branding thuộc Phase 8 riêng.
