# Lint & Analysis Rules

## Base Config

`analysis_options.yaml` extends `package:very_good_analysis/analysis_options.yaml` — the strictest Flutter lint ruleset.

## Excluded from Analysis

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"                          # json_serializable / retrofit generated
    - "**/*.freezed.dart"                    # freezed generated
    - lib/core/di/injection.config.dart      # injectable generated
```

Never manually edit generated files. Regenerate with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Disabled Rules (intentional relaxations)

| Rule | Why disabled |
|------|-------------|
| `public_member_api_docs` | No doc comments required — keep code clean |
| `always_use_package_imports` | Allow relative imports for easier refactoring |
| `avoid_redundant_argument_values` | Allows explicit defaults for clarity |
| `sort_pub_dependencies` | No forced alphabetical order in pubspec |
| `lines_longer_than_80_chars` | Not enforced — use judgment |
| `unnecessary_lambdas` | Allow lambdas for readability in callbacks |

## Enforced by very_good_analysis (key ones)

- No unused imports or variables
- Prefer `const` constructors where possible
- No `print()` — use proper logging
- Prefer `final` for local variables
- No implicit `dynamic`
- Prefer named parameters for boolean arguments
- Always declare return types

## Code Formatting

```bash
dart format lib/        # format all Dart files
flutter analyze         # run analyzer
```

- Line length: no hard limit, but keep readable (aim for ~100 chars)
- Trailing commas: always add on multi-line argument lists (enables better formatting)

## Build Runner

Run after any change to files with `@freezed`, `@injectable`, `@RestApi`, or `@JsonSerializable`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode during development:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```
