# Utility Checklist — {util-name}

## Prerequisites

<!-- Note: Description: List the spec file this utility is derived from. Output: Fill in the actual path below. -->

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.6 Utility` in `fe.md`

---

## Required Skills

Before implementing, read the following skills:


---

## 1. Utility Definition

> Utility functions are pure Dart helpers. No framework dependency (no `BuildContext`, no `Widget`).

<!-- Note: Description: Identify the function name, purpose, signature, location, and call sites. Output: Fill in the actual values below. -->

- [ ] **Function name:** `{utilName}` (lowerCamelCase — e.g. `formatDisplayDate`, `mapApiStatusToLabel`)
- [ ] **Purpose:** `{one-sentence description of what this function does}`
- [ ] **Location:**
  - Feature-specific: `lib/features/{feature}/utils/{util_name}.dart`
  - Shared (reusable across features): `lib/shared/utils/{util_name}.dart`
- [ ] **File:** `{util_name}.dart` (snake_case)
- [ ] **Signature:**
  <!-- Note: Description: List all parameters with name and Dart type, and the return type. Output: Replace with real signature. -->
  - Parameters: `{paramName}: {DartType}, ...`
  - Returns: `{DartType}`
- [ ] **Pure function:** yes / no — _(if no, document side effects)_
- [ ] **Used in:**
  <!-- Note: Description: List which widgets, blocs, or other utils will call this function. Output: Replace with real call sites. -->
  - `{WidgetName | BlocName | OtherUtil}`
- [ ] Edge cases handled:
  <!-- Note: Description: List null/empty/invalid input behaviors per spec. Output: Replace with real cases. -->
  - `{input}` → `{expected behavior}`

---

## 2. Unit Tests

>

- [ ] **Test file:** `test/features/{feature}/utils/{util_name}_test.dart`
  - _(Shared)_ `test/shared/utils/{util_name}_test.dart`
- [ ] Test cases:
  <!-- Note: Description: Plan test cases covering happy path, edge cases (null, empty, invalid). Output: Replace with real cases. -->
  - [ ] **Test case:** should return `{expected}` when given valid input — Input: `{valid input}` | Expected: `{result}`
  - [ ] **Test case:** should return `{fallback}` when input is empty or null — Input: `''` or `null` | Expected: `{fallback value}`
  - [ ] **Test case:** should handle `{edge case}` correctly — Input: `{edge value}` | Expected: `{behavior}`

---

_Instruction: The `<!-- Note: ... -->` lines guide the Agent in filling actual content. After filling the "Output", delete all Note lines before starting implementation._
