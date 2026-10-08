# D-0002: Form và validation có kiểu

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: form,validation
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Form xuất hiện ở đăng ký, hồ sơ, địa chỉ, thanh toán. Base đã có enum lỗi có
kiểu (`lib/core/validation/auth_validation_error.dart`), regex trong
`Constant`, và ADR-0009 yêu cầu Screen dịch lỗi. Nhưng các Cubit auth tự viết
hàm validate riêng và dùng cờ `forceUpdateValidation` trong `copyWith`; chưa
có quy tắc khi nào hiện lỗi, focus field nào, và lỗi field từ server nằm đâu.

## Quyết định

Validation là hàm Dart thuần trả enum lỗi; Cubit giữ input thô và một giá trị
lỗi bất biến, validate khi submit rồi validate trực tiếp sau lần submit đầu, và
Screen map enum sang l10n.

- Enum lỗi tại `lib/core/validation/<feature>_validation_error.dart`; tái dùng
  `PhoneInputError`, `EmailInputError`, `PasswordInputError` khi phù hợp.
- Validator `abstract final class <Feature>FormValidator` tại
  `lib/core/validation/<feature>_form_validator.dart`, dùng regex của
  `Constant`.
- State: `<Feature>FormInput input`, `<Feature>FormErrors errors` (thay cả
  giá trị, không cần `forceUpdateValidation`), `bool submitted`, effect.
- Effect: `<Feature>FocusFieldEffect(field)`, `<Feature>SavedEffect`,
  `<Feature>ShowErrorEffect{error, retryAction}`.
- Lỗi field từ server là failure có kiểu ở domain (`<Feature>Failure{code}`)
  và được gắn vào đúng field.
- Chuẩn hoá (trim, số điện thoại, email) làm một lần trong UseCase.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `formz` | Thêm package; enum + hàm thuần đủ dùng và đã có trong base |
| `reactive_forms` / `flutter_form_builder` | Đưa state form vào widget tree, Cubit không test được, khó dịch lỗi theo ADR-0009 |
| `Form` + `TextFormField.validator` trả chuỗi | Validate trong widget, trả chuỗi đã dịch, không unit-test được |
| Giữ `forceUpdateValidation` cho form mới | Dễ quên cờ làm lỗi cũ không xoá; một giá trị `errors` bất biến đơn giản hơn |

## Hệ quả

- Form mới làm theo hình dạng này; form auth cũ giữ nguyên tới khi được sửa.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/form_validation.md`.
- Code mẫu và test bảo vệ: `test/patterns/form_validation_pattern_test.dart`
  (12 test: validator, không hiện lỗi trước submit, focus field lỗi đầu tiên,
  validate trực tiếp, chống submit đôi, lỗi field từ server, retry).
