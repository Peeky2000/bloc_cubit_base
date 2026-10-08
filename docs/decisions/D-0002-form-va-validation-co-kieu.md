# D-0002: Form và validation có kiểu

- Trạng thái: accepted
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
có quy tắc khi nào hiện lỗi, focus field nào, lỗi field từ server nằm đâu, và
trình đọc màn hình được báo lỗi thế nào.

## Quyết định

Validation là hàm Dart thuần trả enum lỗi; Cubit giữ input thô, một giá trị
lỗi bất biến và tập field đã sửa, hiện lỗi theo "reward early, punish late";
Screen map enum sang l10n. Không thêm package form.

- Thời điểm hiện lỗi: gõ ở field chưa lỗi thì không báo; rời một field đã sửa
  (`onFieldUnfocused`) thì validate field đó; field đang lỗi validate lại mỗi
  lần gõ để lỗi biến mất ngay khi sửa đúng; `submit()` validate mọi field.
  Tương đương `AutovalidateMode.onUnfocus` + `onUserInteractionIfError` +
  `FormState.validate()` của Flutter.
- Enum lỗi tại `lib/core/validation/<feature>_validation_error.dart`; tái dùng
  `PhoneInputError`, `EmailInputError`, `PasswordInputError` khi phù hợp.
- Validator `abstract final class <Feature>FormValidator` tại
  `lib/core/validation/<feature>_form_validator.dart`, dùng regex của
  `Constant`.
- State: `<Feature>FormInput input`, `<Feature>FormErrors errors` (thay một
  field bằng `withFieldFrom`, không cần `forceUpdateValidation`),
  `Set<<Feature>FormField> edited`, effect; `canSubmit` sai khi đang lưu và
  sau khi lưu xong cho tới khi input đổi (chống submit đôi).
- Effect: `<Feature>FocusFieldEffect(field)`, `<Feature>SavedEffect`,
  `<Feature>ShowErrorEffect{error, retryAction}`. Lỗi không xoá input.
- Lỗi field từ server là failure có kiểu ở domain (`<Feature>Failure{code}`),
  gắn vào đúng field, focus field đó, xoá khi người dùng sửa field.
- Kiểm tra phía server khi đang nhập là tuỳ chọn: chạy ở `onFieldUnfocused`
  hoặc debounce 400 ms bằng `Timer` + generation trong Cubit; kết quả khi
  submit vẫn là chuẩn.
- Chuẩn hoá (trim, số điện thoại, email) làm một lần trong UseCase.
- Screen: listener `FocusNode` gọi `onFieldUnfocused`; `AutofillGroup` +
  `autofillHints`; `keyboardType`, `textInputAction`; lỗi qua
  `CommonTextField.error` (thành `errorText`, live region trên Android);
  `FocusFieldEffect` → `requestFocus()` và trên iOS
  `SemanticsService.sendAnnouncement` lỗi đầu tiên sau 1 giây, như
  `Form.validate()`. Nút submit không bị disable khi form chưa hợp lệ.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `formz` 0.8.1 (Very Good Ventures, phát hành 08/2026, Dart ≥3.12) | Cùng ý tưởng enum lỗi + pure/dirty, được duy trì tốt; nhưng thêm package và một lớp `FormzInput` mỗi field trong khi base đã có enum và regex; `displayError` hiện ngay khi dirty (lúc đang gõ), vẫn phải tự thêm "rời field". Có thể đổi sang sau mà Screen không đổi |
| `flutter_form_builder` 11.0.0 | State nằm trong `GlobalKey<FormBuilderState>` của widget tree, validator trả chuỗi đã dịch (trái ADR-0009), Cubit không test được; 11.0 chuyển sang package `material_ui` |
| `reactive_forms` 18.2.2 | Uploader chưa xác minh, bản cuối 9 tháng trước; message map theo key chuỗi nên thêm lỗi mới không bị compiler bắt |
| `Form` + `TextFormField.validator` + `AutovalidateMode.onUnfocus` | Cách chuẩn của Flutter docs nhưng validate trong widget, trả chuỗi, không unit-test được; lỗi server phải qua `forceErrorText`. Ta giữ cùng thời điểm hiện lỗi và cách announce của nó |
| Validate trực tiếp mọi field sau lần submit đầu (bản trước) | Trước submit rời field không có phản hồi; sau submit field đúng đang sửa bị báo lỗi giữa chừng (Baymard, NN/g: premature validation) |
| Disable nút submit khi form chưa hợp lệ (tutorial bloc) | Người dùng không biết vì sao không bấm được; Smashing, GOV.UK khuyên để nút bật và chỉ lỗi khi bấm |
| Giữ `forceUpdateValidation` cho form mới | Dễ quên cờ làm lỗi cũ không xoá; một giá trị `errors` bất biến đơn giản hơn |

## Hệ quả

- Form mới làm theo hình dạng này; form auth cũ giữ nguyên tới khi được sửa.
- `sli_common` nên thêm `autofillHints` vào `CommonTextField`; tới lúc đó
  field cần autofill dùng `TextField`.
- Hướng dẫn và nguồn: `.agents/skills/flutter-patterns/references/form_validation.md`.
- Code mẫu và test bảo vệ: `test/patterns/form_validation_pattern_test.dart`
  (15 test: validator, không báo lỗi khi đang gõ, rời field đã sửa, field lỗi
  validate lại khi gõ, focus field lỗi đầu tiên, chống submit đôi và sau khi
  lưu, lỗi field từ server, retry, kết quả sau `close()`). Đoạn Screen
  (focus, announce, `CommonTextField`) đã chạy `flutter analyze` trên 3.44.5.

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Khi áp dụng lần đầu: thêm tham số `autofillHints` cho `CommonTextField` trong `sli_common`.
