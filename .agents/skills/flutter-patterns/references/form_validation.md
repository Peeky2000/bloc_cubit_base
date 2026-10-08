# Forms and validation

Decision: [D-0002](../../../../docs/decisions/D-0002-form-va-validation-co-kieu.md)
(proposed). Reference code: `test/patterns/form_validation_pattern_test.dart`.

## When to use

Screens where typed values are checked and sent: sign-up, profile, address,
checkout, create/edit. A search box is not a form; debounce it in the Cubit.

## Decision

Validation is pure Dart functions that return typed enum errors. The Cubit
holds the raw input, one immutable errors value and the set of edited fields,
and shows errors "reward early, punish late"; the Screen maps each enum to
l10n. No form package: `formz` 0.8.1 (VGV) gives the same pure/dirty idea, and
the base already has the enums and regexes.

## Files to create (feature `shop_form`)

| Layer | Path | Content |
|---|---|---|
| Entity, port | `lib/domain/entities/shop/shop_update.dart`, `repositories/shop_repo.dart` | `ShopUpdate` (trimmed, optional = null); `updateShop`; `ShopUpdateFailure{code}` |
| UseCase | `lib/domain/use_case/shop_use_case.dart` | normalizes once (`AuthUseCase.normalizePhone`, lower-case email) |
| Error enums | `lib/core/validation/shop_validation_error.dart` | `ShopNameInputError`, `ShopEmailInputError`, `ShopFormField`, `ShopFormErrors` |
| Validator | `lib/core/validation/shop_form_validator.dart` | `abstract final class ShopFormValidator` with static functions |
| Cubit | `lib/presentation/shop_form/cubit/shop_form_cubit.dart` | `onXChanged`, `onFieldUnfocused(field)`, `submit()` |
| State | `.../cubit/shop_form_state.dart` | `ShopFormInput`, state below |
| Effect | `.../cubit/shop_form_effect.dart` | `ShopFormSavedEffect`, `ShopFormFocusFieldEffect(field)`, `ShopFormShowErrorEffect{error, retryAction}` |
| Screen | `.../view/shop_form_screen.dart` | controllers, focus nodes, `AutofillGroup`, enum → l10n |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` | one key per enum value that says how to fix it |

Reuse the enums in `lib/core/validation/auth_validation_error.dart` and the
regexes in `Constant`; add a feature enum only for `tooLong`, `taken`, etc.

## State and effects

```dart
final ShopFormInput input;          // raw text as typed, Equatable
final ShopFormErrors errors;        // one immutable value, ShopFormErrors.none
final Set<ShopFormField> edited;    // fields the user changed
final UiEffect<ShopFormEffect>? effect;
bool get isSubmitting => loading == LoadingStatus.loading;
bool get canSubmit => !isSubmitting && loading != LoadingStatus.complete;
```

`errors.withFieldFrom(field, ShopFormValidator.validate(input))` replaces one
field's error; no `forceUpdateValidation` flag. Existing auth forms keep
their flag until they are touched.

## When errors show

| Moment | Validated | Flutter equivalent |
|---|---|---|
| Typing in a field without an error | nothing | — (no premature errors) |
| Leaving an edited field (`onFieldUnfocused`) | that field | `AutovalidateMode.onUnfocus` |
| Typing in a field that shows an error | that field, every change | `onUserInteractionIfError` |
| `submit()` | every field, untouched ones too | `FormState.validate()` |

## Flow

1. `submit()`: return unless `canSubmit`. Validate all. Invalid → errors +
   `ShopFormFocusFieldEffect(first invalid field)`; use case not called.
2. Valid: `loading`, `useCase.updateShop(input.toUpdate())`, `complete` +
   `ShopFormSavedEffect`. `canSubmit` stays false until the input changes, so
   a double tap or a tap during the pop sends once.
3. `ShopUpdateFailure` (server rejected a field): the enum goes on that field
   (`ShopEmailInputError.taken`) with a focus effect; editing it clears it.
4. Any other error (offline included): `error` +
   `ShopFormShowErrorEffect(retryAction: submit)`. Input and controllers stay
   as typed; nothing is cleared. Optional fields are valid when empty and are
   sent as `null`.

Live server checks ("email already used" while typing) are optional: run them
in `onFieldUnfocused`, or debounce 400 ms with a `Timer` in the Cubit plus a
generation counter so a stale answer is dropped; cancel the timer in
`close()`. The server answer on submit (step 3) stays the authority.

## Screen

```dart
// initState, one per FocusNode (all disposed in dispose()):
_emailFocus.addListener(() {
  if (!_emailFocus.hasFocus) _cubit.onFieldUnfocused(ShopFormField.email);
});
AutofillGroup(child: Column(children: [
  CommonTextField(controller: _email, focusNode: _emailFocus,
    onChange: _cubit.onEmailChanged,
    error: _emailError(context, state.errors.email), // exhaustive switch
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next), ...]));
// Listener: Saved → SLIRouting.back(); ShowError → handleErrorResponse,
// retry → cubit.submit(); FocusField → _focusInvalid(node, l10n text):
void _focusInvalid(FocusNode node, String? message) {
  node.requestFocus();
  if (message == null || !MediaQuery.supportsAnnounceOf(context)) return;
  final view = View.of(context);
  final direction = Directionality.of(context);
  Future<void>.delayed(const Duration(seconds: 1), () {   // as Form does
    if (!mounted) return;
    SemanticsService.sendAnnouncement(view, message, direction,
        assertiveness: Assertiveness.assertive);
  });
}
```

Checked with `flutter analyze` on 3.44.5. Submit stays enabled while fields
are invalid (tapping shows why) and shows progress while `isSubmitting`. The
exhaustive `switch` fails to compile until a new enum value has text.

## Accessibility

- Keep `CommonTextField`'s default `isUseDefaultError: true`: the error is
  `InputDecoration.errorText`, a live region on Android (lost with a custom
  `errorBuilder`). On iOS it is not; `_focusInvalid` announces it with
  `sendAnnouncement` (`SemanticsService.announce` is deprecated since 3.35).
- Keyboard `emailAddress`/`phone`/`number`; `textInputAction` next, done.
- Autofill: `AutofillHints.email`, `telephoneNumber`, `organizationName`,
  `newPassword`, `oneTimeCode` in one `AutofillGroup`. `CommonTextField` has
  no `autofillHints` yet; use `TextField` for those fields until it does.

## Security and performance

- No password or OTP in logs, `toString` or persisted form state.
- Client validation is UX only; the server validates again.
- Long forms: `buildWhen` per field (`previous.errors.email != current.errors.email`).

## Test checklist

- [ ] Each validator: empty, whitespace, too long, invalid, valid.
- [ ] Typing without an error shows nothing; leaving an edited field
      validates it, an untouched one does not.
- [ ] A field in error re-validates on each change and clears when fixed.
- [ ] Invalid submit: typed errors, focus on the first invalid field, use
      case not called.
- [ ] Valid submit trims, normalizes once, saves; saved effect.
- [ ] Double submit sends once; after a save, submit waits for a change.
- [ ] Server field error lands on that field and clears on edit.
- [ ] Other failure keeps input, error effect with retry; result after
      `close()` ignored.

## Nguồn

- Flutter: https://docs.flutter.dev/cookbook/forms/validation,
  https://api.flutter.dev/flutter/widgets/AutovalidateMode.html,
  https://api.flutter.dev/flutter/material/TextField/autofillHints.html,
  https://docs.flutter.dev/ui/accessibility; 3.44.5 source `widgets/form.dart`
  (announces the first error, 1 s on iOS), `material/input_decorator.dart`
- Packages: https://pub.dev/packages/formz,
  https://bloclibrary.dev/tutorials/flutter-login/,
  https://pub.dev/packages/flutter_form_builder, https://pub.dev/packages/reactive_forms
- Timing: https://baymard.com/research-articles/inline-form-validation,
  https://www.smashingmagazine.com/2022/09/inline-validation-web-forms-ux/,
  https://www.nngroup.com/articles/errors-forms-design-guidelines/,
  https://design-system.service.gov.uk/patterns/validation/
