# Forms and validation

Decision: [D-0002](../../../../docs/decisions/D-0002-form-va-validation-co-kieu.md)
(proposed). Reference code: `test/patterns/form_validation_pattern_test.dart`.

## When to use

Any screen where the user types values that are checked and sent: sign-up,
profile, address, checkout, create/edit forms. A single search box is not a
form; debounce it in the Cubit instead.

## Decision

Validation is pure Dart functions that return typed enum errors; the Cubit
holds the raw input and one immutable errors value, validates on submit and
then live after the first submit, and the Screen maps each enum to l10n.

## Files to create (feature `shop_form`)

| Layer | Path | Content |
|---|---|---|
| Entity | `lib/domain/entities/shop/shop_update.dart` | `ShopUpdate` (trimmed values, optional = null) |
| Repo port | `lib/domain/repositories/shop_repo.dart` | `Future<void> updateShop(ShopUpdate)`; `ShopUpdateFailure{code}` for field rejections |
| UseCase | `lib/domain/use_case/shop_use_case.dart` | normalizes once (`AuthUseCase.normalizePhone`, lower-case email) |
| Error enums | `lib/core/validation/shop_validation_error.dart` | `ShopNameInputError`, `ShopEmailInputError`, `ShopFormField` |
| Validator | `lib/core/validation/shop_form_validator.dart` | `abstract final class ShopFormValidator` with static functions |
| Cubit | `lib/presentation/shop_form/cubit/shop_form_cubit.dart` | `onShopNameChanged`, `onEmailChanged`, `onPhoneChanged`, `submit()` |
| State | `.../cubit/shop_form_state.dart` | `ShopFormInput`, `ShopFormErrors` (may live here or in core/validation) |
| Effect | `.../cubit/shop_form_effect.dart` | `ShopFormSavedEffect`, `ShopFormFocusFieldEffect(field)`, `ShopFormShowErrorEffect{error, retryAction}` |
| Screen | `.../view/shop_form_screen.dart` | controllers, focus nodes, enum → l10n |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` | one key per enum value, e.g. `shopNameIsTooLong` |

Reuse the enums in `lib/core/validation/auth_validation_error.dart`
(`PhoneInputError`, `EmailInputError`, `PasswordInputError`) and the regexes
in `Constant` before adding new ones. Add a feature enum only for a reason
those do not have (`tooLong`, `taken`).

## State and effects

```dart
final ShopFormInput input;     // raw text as typed, Equatable
final ShopFormErrors errors;   // one immutable value, ShopFormErrors.none
final bool submitted;          // false until the first submit
final UiEffect<ShopFormEffect>? effect;
bool get isSubmitting => loading == LoadingStatus.loading;
```

Replacing `errors` as a whole value avoids the `forceUpdateValidation` flag
that `SignInState.copyWith` needs to clear nullable fields. New forms use the
errors value; existing auth forms keep their flag until they are touched.

## Flow

1. `onXChanged(value)`: store the raw value. Before the first submit, show no
   errors. After it, re-validate on every change so errors disappear as the
   user fixes them.
2. `submit()`: ignore while submitting. Validate everything, set
   `submitted = true`. If invalid, emit `ShopFormFocusFieldEffect(first
   invalid field)` and stop; the use case is not called.
3. Valid: `loading`, call the use case with `input.toUpdate()` (trimmed),
   `complete` + `ShopFormSavedEffect`.
4. `ShopUpdateFailure` (server rejected a field): put the enum on that field
   (`ShopEmailInputError.taken`) and focus it.
5. Any other error: `error` + `ShopFormShowErrorEffect(retryAction: submit)`.
   The input stays.

## Screen

```dart
// controllers + focus nodes in State, disposed in dispose()
CommonTextField(controller: _shopName, focusNode: _shopNameFocus,
  onChanged: cubit.onShopNameChanged,
  errorText: switch (state.errors.shopName) {
    ShopNameInputError.required => context.l10n.shopNameIsRequired,
    ShopNameInputError.tooLong => context.l10n.shopNameIsTooLong,
    null => null,
  });
// listener: FocusField → requestFocus(); Saved → SLIRouting.back();
// ShowError → handleErrorResponse(context, error), retry → cubit.submit()
```

The submit button is disabled while `state.isSubmitting`. Exhaustive
`switch` on each enum means a new enum value fails to compile until it has
text.

## Error, empty, offline

Optional fields are valid when empty and are sent as `null`. Offline submit
is a normal error effect with retry; the typed input stays in state.

## Security and performance

- Never put a password or OTP in logs or in `toString`. Do not persist form
  state that contains secrets.
- Client validation is for UX only; the server validates again.
- `buildWhen` per field (`previous.errors.email != current.errors.email`)
  for long forms.

## Test checklist

- [ ] Each validator: empty, whitespace, too long, invalid, valid.
- [ ] Typing before submit shows no errors.
- [ ] Invalid submit: typed errors, focus effect on the first invalid field,
      use case not called.
- [ ] After a submit, changes re-validate live.
- [ ] Valid submit trims, normalizes once and saves; saved effect.
- [ ] Double submit sends once.
- [ ] Server field error lands on that field and clears on edit.
- [ ] Other failure keeps input, error effect with retry.
- [ ] Result after `close()` ignored.

Reference code: `test/patterns/form_validation_pattern_test.dart`
