# Base Modernization Baseline

Date: 2026-08-26

## Commands

- `flutter pub get`: passed; lockfile resolved with Flutter 3.44.5 / Dart 3.12.2.
- `flutter analyze`: failed with 162 issues.
- `flutter test`: not reached because the chained analyze command failed.

## Main existing issue groups

- Invalid legacy package identifier `bloc_cubit_base` and product-specific naming.
- Missing `.env` asset and mutable string-keyed environment configuration.
- Deprecated Flutter APIs and legacy naming lints.
- Manual service-locator access throughout presentation and network interceptors.
- Domain-to-data and presentation-to-data boundary violations.
- Empty embedded `lib/modules/sli_common` tree instead of a Git submodule.

This file records pre-migration debt. New work must reduce the count and must not hide
issues through analyzer exclusions or disabled lint rules.
