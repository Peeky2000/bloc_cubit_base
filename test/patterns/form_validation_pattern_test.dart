// Reference implementation: forms and validation.
//
// Pattern: .agents/skills/flutter-patterns/references/form_validation.md
// Decision: docs/decisions/D-0002-form-va-validation-co-kieu.md
//
// Each section is one file of a real feature ("edit shop"). The Cubit owns
// the input values, typed field errors and when they show ("reward early,
// punish late"); the Screen owns the TextEditingControllers, FocusNodes and
// the l10n text of each error.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/shop/shop_update.dart
// ---------------------------------------------------------------------------

/// What the use case receives: already trimmed, optional values as null.
final class ShopUpdate extends Equatable {
  const ShopUpdate({required this.shopName, required this.email, this.phone});

  final String shopName;
  final String email;
  final String? phone;

  @override
  List<Object?> get props => [shopName, email, phone];
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/shop_repo.dart
// ---------------------------------------------------------------------------

abstract class ShopRepo {
  /// Throws [ShopUpdateFailure] when the server rejects a field; other
  /// transport failures are thrown unchanged.
  Future<void> updateShop(ShopUpdate update);
}

enum ShopUpdateFailureCode { emailTaken }

/// Field-level rejection from the server, mapped in the repository impl from
/// the API error code (for example HTTP 409 + `EMAIL_TAKEN`).
final class ShopUpdateFailure implements Exception {
  const ShopUpdateFailure(this.code);

  final ShopUpdateFailureCode code;

  @override
  String toString() => 'ShopUpdateFailure($code)';
}

// ---------------------------------------------------------------------------
// lib/domain/use_case/shop_use_case.dart
// ---------------------------------------------------------------------------

class ShopUseCase {
  ShopUseCase(this._repo);

  final ShopRepo _repo;

  /// Normalizes once, in the domain, with the existing normalizer.
  Future<void> updateShop(ShopUpdate update) => _repo.updateShop(
    ShopUpdate(
      shopName: update.shopName,
      email: update.email.toLowerCase(),
      phone: update.phone == null
          ? null
          : AuthUseCase.normalizePhone(update.phone!),
    ),
  );
}

// ---------------------------------------------------------------------------
// lib/core/validation/shop_validation_error.dart
// Reuse the enums in auth_validation_error.dart when they fit (phone here);
// add a feature enum only for a reason they do not have.
// ---------------------------------------------------------------------------

enum ShopNameInputError { required, tooLong }

enum ShopEmailInputError { required, invalid, taken }

/// Fields in screen order; the first invalid one receives focus.
enum ShopFormField { shopName, email, phone }

/// Every field error of the form as one immutable value. Replacing the whole
/// value avoids the `forceUpdateValidation` flag that nullable fields in
/// `copyWith` would otherwise need.
final class ShopFormErrors extends Equatable {
  const ShopFormErrors({this.shopName, this.email, this.phone});

  static const none = ShopFormErrors();

  final ShopNameInputError? shopName;
  final ShopEmailInputError? email;
  final PhoneInputError? phone;

  bool get isValid => firstInvalidField == null;

  ShopFormField? get firstInvalidField {
    if (shopName != null) return ShopFormField.shopName;
    if (email != null) return ShopFormField.email;
    if (phone != null) return ShopFormField.phone;
    return null;
  }

  bool has(ShopFormField field) => switch (field) {
    ShopFormField.shopName => shopName != null,
    ShopFormField.email => email != null,
    ShopFormField.phone => phone != null,
  };

  /// This value with the error of [field] taken from [other].
  ShopFormErrors withFieldFrom(ShopFormField field, ShopFormErrors other) =>
      ShopFormErrors(
        shopName: field == ShopFormField.shopName ? other.shopName : shopName,
        email: field == ShopFormField.email ? other.email : email,
        phone: field == ShopFormField.phone ? other.phone : phone,
      );

  @override
  List<Object?> get props => [shopName, email, phone];
}

// ---------------------------------------------------------------------------
// lib/core/validation/shop_form_validator.dart
// Pure functions: no Flutter, no l10n, no I/O. Regexes come from Constant.
// ---------------------------------------------------------------------------

abstract final class ShopFormValidator {
  static const int shopNameMaxLength = 100;

  static ShopNameInputError? shopName(String value) {
    final text = value.trim();
    if (text.isEmpty) return ShopNameInputError.required;
    if (text.length > shopNameMaxLength) return ShopNameInputError.tooLong;
    return null;
  }

  static ShopEmailInputError? email(String value) {
    final text = value.trim();
    if (text.isEmpty) return ShopEmailInputError.required;
    if (!Constant.emailRegexp.hasMatch(text)) {
      return ShopEmailInputError.invalid;
    }
    return null;
  }

  /// Optional field: empty is valid, anything else must be a phone number.
  static PhoneInputError? phone(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    if (!Constant.phoneRegexp.hasMatch(text)) return PhoneInputError.invalid;
    return null;
  }

  static ShopFormErrors validate(ShopFormInput input) => ShopFormErrors(
    shopName: shopName(input.shopName),
    email: email(input.email),
    phone: phone(input.phone),
  );
}

// ---------------------------------------------------------------------------
// lib/presentation/shop_form/cubit/shop_form_effect.dart  (part file)
// ---------------------------------------------------------------------------

enum ShopFormRetryAction { submit }

sealed class ShopFormEffect {
  const ShopFormEffect();
}

final class ShopFormSavedEffect extends ShopFormEffect {
  const ShopFormSavedEffect();
}

/// The Screen calls `FocusNode.requestFocus()` on that field.
final class ShopFormFocusFieldEffect extends ShopFormEffect {
  const ShopFormFocusFieldEffect(this.field);

  final ShopFormField field;
}

final class ShopFormShowErrorEffect extends ShopFormEffect {
  const ShopFormShowErrorEffect({
    required this.error,
    required this.retryAction,
  });

  final Object error;
  final ShopFormRetryAction retryAction;
}

// ---------------------------------------------------------------------------
// lib/presentation/shop_form/cubit/shop_form_state.dart  (part file)
// ---------------------------------------------------------------------------

/// Raw text exactly as typed. Trimming happens in [toUpdate].
final class ShopFormInput extends Equatable {
  const ShopFormInput({this.shopName = '', this.email = '', this.phone = ''});

  final String shopName;
  final String email;
  final String phone;

  ShopFormInput copyWith({String? shopName, String? email, String? phone}) =>
      ShopFormInput(
        shopName: shopName ?? this.shopName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );

  ShopUpdate toUpdate() {
    final phone = this.phone.trim();
    return ShopUpdate(
      shopName: shopName.trim(),
      email: email.trim(),
      phone: phone.isEmpty ? null : phone,
    );
  }

  @override
  List<Object?> get props => [shopName, email, phone];
}

class ShopFormState extends BaseAppState<Object> {
  const ShopFormState({
    required super.loading,
    super.error,
    required this.input,
    required this.errors,
    this.edited = const {},
    this.effect,
  });

  /// Edit forms pass the stored values; the Screen copies them into its
  /// controllers once.
  factory ShopFormState.initial({
    ShopFormInput input = const ShopFormInput(),
  }) => ShopFormState(
    loading: LoadingStatus.initial,
    input: input,
    errors: ShopFormErrors.none,
  );

  final ShopFormInput input;

  /// What the Screen shows under each field.
  final ShopFormErrors errors;

  /// Fields the user changed. Losing focus validates only these, so tabbing
  /// through an untouched form shows nothing.
  final Set<ShopFormField> edited;

  final UiEffect<ShopFormEffect>? effect;

  bool get isSubmitting => loading == LoadingStatus.loading;

  /// False while saving and after a save until the input changes, so a
  /// double tap or a tap during the pop sends once.
  bool get canSubmit => !isSubmitting && loading != LoadingStatus.complete;

  ShopFormState copyWith({
    LoadingStatus? loading,
    Object? error,
    ShopFormInput? input,
    ShopFormErrors? errors,
    Set<ShopFormField>? edited,
    UiEffect<ShopFormEffect>? effect,
  }) {
    return ShopFormState(
      loading: loading ?? this.loading,
      error: error,
      input: input ?? this.input,
      errors: errors ?? this.errors,
      edited: edited ?? this.edited,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, input, errors, edited, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/shop_form/cubit/shop_form_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class ShopFormCubit extends BaseCubit<ShopFormState> {
  ShopFormCubit(this._useCase) : super(ShopFormState.initial());

  final ShopUseCase _useCase;

  void onShopNameChanged(String value) =>
      _onInput(ShopFormField.shopName, state.input.copyWith(shopName: value));

  void onEmailChanged(String value) =>
      _onInput(ShopFormField.email, state.input.copyWith(email: value));

  void onPhoneChanged(String value) =>
      _onInput(ShopFormField.phone, state.input.copyWith(phone: value));

  /// Reward early: a field that shows an error is re-validated on every
  /// change, so the error goes away as soon as the value is fixed. A field
  /// without an error stays quiet while the user is still typing.
  void _onInput(ShopFormField field, ShopFormInput input) {
    emit(
      state.copyWith(
        input: input,
        edited: {...state.edited, field},
        errors: state.errors.has(field)
            ? state.errors.withFieldFrom(
                field,
                ShopFormValidator.validate(input),
              )
            : null,
        // After a save, a change makes the form submittable again.
        loading: state.loading == LoadingStatus.complete
            ? LoadingStatus.initial
            : null,
      ),
    );
  }

  /// Punish late: the Screen calls this when a field loses focus. Only a
  /// field the user changed is validated.
  void onFieldUnfocused(ShopFormField field) {
    if (!state.edited.contains(field)) return;
    final errors = state.errors.withFieldFrom(
      field,
      ShopFormValidator.validate(state.input),
    );
    if (errors != state.errors) emit(state.copyWith(errors: errors));
  }

  /// Validates every field, including untouched required ones.
  Future<void> submit() async {
    if (!state.canSubmit) return;
    final errors = ShopFormValidator.validate(state.input);
    emit(state.copyWith(errors: errors));
    final invalid = errors.firstInvalidField;
    if (invalid != null) {
      _emitEffect(ShopFormFocusFieldEffect(invalid));
      return;
    }

    emit(state.copyWith(loading: LoadingStatus.loading));
    try {
      await _useCase.updateShop(state.input.toUpdate());
      if (isClosed) return;
      emit(state.copyWith(loading: LoadingStatus.complete));
      _emitEffect(const ShopFormSavedEffect());
    } on ShopUpdateFailure catch (failure) {
      if (isClosed) return;
      switch (failure.code) {
        case ShopUpdateFailureCode.emailTaken:
          emit(
            state.copyWith(
              loading: LoadingStatus.error,
              errors: state.errors.withFieldFrom(
                ShopFormField.email,
                const ShopFormErrors(email: ShopEmailInputError.taken),
              ),
            ),
          );
          _emitEffect(const ShopFormFocusFieldEffect(ShopFormField.email));
      }
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(
        ShopFormShowErrorEffect(
          error: error,
          retryAction: ShopFormRetryAction.submit,
        ),
      );
    }
  }

  void _emitEffect(ShopFormEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/shop_form/view/shop_form_screen.dart  (excerpt)
//
//   String? _shopNameError(BuildContext context, ShopNameInputError? e) =>
//       switch (e) {
//         ShopNameInputError.required => context.l10n.shopNameIsRequired,
//         ShopNameInputError.tooLong => context.l10n.shopNameIsTooLong,
//         null => null,
//       };
//
//   // initState: one listener per FocusNode
//   _shopNameFocus.addListener(() {
//     if (!_shopNameFocus.hasFocus) {
//       _cubit.onFieldUnfocused(ShopFormField.shopName);
//     }
//   });
//
// The full Screen wiring (AutofillGroup, CommonTextField, focus and the iOS
// announcement on ShopFormFocusFieldEffect) is in
// references/form_validation.md and was checked with `flutter analyze`.
// ---------------------------------------------------------------------------

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  group('ShopFormValidator', () {
    test('shop name is required, trimmed and length-limited', () {
      expect(ShopFormValidator.shopName(''), ShopNameInputError.required);
      expect(ShopFormValidator.shopName('   '), ShopNameInputError.required);
      expect(ShopFormValidator.shopName('a' * 101), ShopNameInputError.tooLong);
      expect(ShopFormValidator.shopName('  Shop A  '), isNull);
    });

    test('email uses the shared regex', () {
      expect(ShopFormValidator.email(''), ShopEmailInputError.required);
      expect(ShopFormValidator.email('a@b'), ShopEmailInputError.invalid);
      expect(ShopFormValidator.email(' shop@example.com '), isNull);
    });

    test('optional phone is valid when empty', () {
      expect(ShopFormValidator.phone(''), isNull);
      expect(ShopFormValidator.phone('12'), PhoneInputError.invalid);
      expect(ShopFormValidator.phone('0912345678'), isNull);
    });

    test('firstInvalidField follows screen order', () {
      const errors = ShopFormErrors(
        email: ShopEmailInputError.invalid,
        phone: PhoneInputError.invalid,
      );

      expect(errors.firstInvalidField, ShopFormField.email);
      expect(errors.isValid, isFalse);
      expect(ShopFormErrors.none.isValid, isTrue);
    });
  });

  group('ShopFormCubit', () {
    late _FakeShopRepo repo;
    late ShopFormCubit cubit;

    setUp(() {
      repo = _FakeShopRepo();
      cubit = ShopFormCubit(ShopUseCase(repo));
    });

    tearDown(() => cubit.close());

    void fillValid() {
      cubit
        ..onShopNameChanged('  Shop A ')
        ..onEmailChanged(' Shop@Example.com ')
        ..onPhoneChanged('0912345678');
    }

    test('typing shows no errors while the field has none', () {
      cubit.onEmailChanged('not-an-email');

      expect(cubit.state.errors, ShopFormErrors.none);
      expect(cubit.state.input.email, 'not-an-email');
    });

    test('leaving an edited field validates it; untouched stays quiet', () {
      cubit
        ..onFieldUnfocused(ShopFormField.shopName)
        ..onEmailChanged('shop@')
        ..onFieldUnfocused(ShopFormField.email);

      expect(cubit.state.errors.shopName, isNull);
      expect(cubit.state.errors.email, ShopEmailInputError.invalid);
    });

    test('a field in error re-validates on every change', () {
      cubit
        ..onEmailChanged('shop@')
        ..onFieldUnfocused(ShopFormField.email)
        ..onEmailChanged('');
      expect(cubit.state.errors.email, ShopEmailInputError.required);

      cubit.onEmailChanged('shop@example.com');
      expect(cubit.state.errors.email, isNull);

      cubit.onEmailChanged('shop@');
      expect(cubit.state.errors.email, isNull, reason: 'punish late');
    });

    test('invalid submit shows typed errors, focuses, sends nothing', () async {
      await cubit.submit();

      expect(cubit.state.errors.shopName, ShopNameInputError.required);
      expect(cubit.state.errors.email, ShopEmailInputError.required);
      expect(cubit.state.errors.phone, isNull);
      final effect = cubit.state.effect!.value as ShopFormFocusFieldEffect;
      expect(effect.field, ShopFormField.shopName);
      expect(repo.updates, isEmpty);
    });

    test('after a submit, fields in error clear as they are fixed', () async {
      await cubit.submit();

      cubit.onShopNameChanged('Shop A');
      expect(cubit.state.errors.shopName, isNull);
      expect(cubit.state.errors.email, ShopEmailInputError.required);

      cubit.onEmailChanged('bad');
      expect(cubit.state.errors.email, ShopEmailInputError.invalid);
    });

    test('valid submit trims, normalizes once and saves', () async {
      fillValid();
      final statuses = <LoadingStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.loading));

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(
        repo.updates.single,
        const ShopUpdate(
          shopName: 'Shop A',
          email: 'shop@example.com',
          phone: '+84912345678',
        ),
      );
      expect(statuses, contains(LoadingStatus.loading));
      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.effect!.value, isA<ShopFormSavedEffect>());
    });

    test('a second submit while saving sends nothing', () async {
      fillValid();
      repo.hold = Completer<void>();

      final first = cubit.submit();
      final second = cubit.submit();
      repo.hold!.complete();
      await Future.wait([first, second]);

      expect(repo.updates, hasLength(1));
    });

    test(
      'after a save, submit sends nothing until the input changes',
      () async {
        fillValid();
        await cubit.submit();
        await cubit.submit();
        expect(repo.updates, hasLength(1));
        expect(cubit.state.canSubmit, isFalse);

        cubit.onShopNameChanged('Shop B');
        expect(cubit.state.canSubmit, isTrue);
        await cubit.submit();
        expect(repo.updates, hasLength(2));
      },
    );

    test('a server field error lands on that field', () async {
      fillValid();
      repo.failNext = const ShopUpdateFailure(ShopUpdateFailureCode.emailTaken);

      await cubit.submit();

      expect(cubit.state.errors.email, ShopEmailInputError.taken);
      final effect = cubit.state.effect!.value as ShopFormFocusFieldEffect;
      expect(effect.field, ShopFormField.email);

      cubit.onEmailChanged('other@example.com');
      expect(cubit.state.errors.email, isNull);
    });

    test('any other failure keeps the input and offers retry', () async {
      fillValid();
      final error = StateError('offline');
      repo.failNext = error;

      await cubit.submit();

      expect(cubit.state.loading, LoadingStatus.error);
      expect(cubit.state.input.shopName, '  Shop A ');
      final effect = cubit.state.effect!.value as ShopFormShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, ShopFormRetryAction.submit);

      await cubit.submit();
      expect(cubit.state.effect!.value, isA<ShopFormSavedEffect>());
      expect(repo.updates, hasLength(2));
    });

    test('a result that arrives after close is ignored', () async {
      fillValid();
      repo.hold = Completer<void>();

      final submitting = cubit.submit();
      await cubit.close();
      repo.hold!.complete();

      await expectLater(submitting, completes);
    });
  });
}

class _FakeShopRepo implements ShopRepo {
  final List<ShopUpdate> updates = [];
  Object? failNext;
  Completer<void>? hold;

  @override
  Future<void> updateShop(ShopUpdate update) async {
    updates.add(update);
    await hold?.future;
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
  }
}
