# Validation Checklist — {form-name}

## Prerequisites

<!-- Note: Description: List the spec file and section validation rules come from. Output: Fill in the actual path below. -->

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.5 Validation` in `fe.md`

---

## Required Skills

Before implementing, read the following skills:

- [ ] `flutter-translations` skill — localization key conventions for error messages (`easy_localization`)

---

## 1. Validation Analysis

> Validators in Flutter are pure Dart functions with signature `String? Function(String?)`. They live in `lib/features/{feature}/presentation/validators/` or `lib/shared/presentation/validators/`.

<!-- Note: Description: Extract all form fields and their validation rules from spec §6.5. Output: Fill the table below. -->

| Field | Rules | i18n error key |
| ----- | ----- | -------------- |
| `{fieldName}` | required / minLength / maxLength / format / cross-field | `{scope}.{field}_{rule}` |

- [ ] **Reuse check:** run `search_memory.py --type validator` for each field — list validators to reuse vs create new:
  <!-- Note: Description: Avoid duplication — check existing validators via memory search. Output: List reused and new validators. -->
  - Reuse: `{existingValidator}` from `{actual_path}`
  - Create new: `{newField}`

---

## 2. Validator Functions

> One validator function per validation rule (or per field if simple). Follow `flutter-translations` skill for error message keys.

<!-- Note: Description: List all validator functions to create. Output: Fill in actual function names and file paths. -->

- [ ] Files to create:
  - `lib/features/{feature}/presentation/validators/{field_name}_validator.dart` — exports `{fieldName}Validator`
  - _(Shared)_ `lib/shared/presentation/validators/{field_name}_validator.dart`
- [ ] Each validator:
  - [ ] Signature: `String? {fieldName}Validator(String? value)`
  - [ ] Returns `null` for valid input
  - [ ] Returns localized error string via `'{scope}.{field}_{rule}'.tr()` for invalid input
  - [ ] Rule order: required → format → minLength / maxLength → custom rules
  - [ ] No side effects — pure function

---

## 3. Unit Tests

>

- [ ] **Test file:** `test/features/{feature}/presentation/validators/{field_name}_validator_test.dart`
- [ ] Test cases per validator:
  <!-- Note: Description: Plan test cases covering valid, empty/required, format error, length. Output: Replace with real test cases. -->
  - [ ] **Test case:** should return null when `{field}` is valid — Input: `"{valid value}"` | Expected: `null`
  - [ ] **Test case:** should return error key when `{field}` is empty — Input: `""` or `null` | Expected: `'{scope}.{field}_required'`
  - [ ] **Test case:** should return error key when `{field}` format is invalid — Input: `"{bad format}"` | Expected: `'{scope}.{field}_format'`
  - [ ] **Test case:** should return error key when `{field}` is too short — Input: `"{short value}"` | Expected: `'{scope}.{field}_min_length'`

---

_Instruction: The `<!-- Note: ... -->` lines guide the Agent in filling actual content. After filling the "Output", delete all Note lines before starting implementation._
