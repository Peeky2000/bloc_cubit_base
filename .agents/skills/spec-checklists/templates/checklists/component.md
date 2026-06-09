# Widget Checklist — {widget-name}

## Prerequisites

<!-- Note: Description: List the spec file this widget is derived from. Output: Fill in the actual path below. -->

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.7 Widget` in `fe.md`

---

## Required Skills

Before implementing, read the following skills:

- [ ] `flutter-atomic-design` skill — Atom / Molecule / Organism classification, placement rules, naming

---

## 1. Widget Definition

> Follow `flutter-atomic-design` skill — classification and placement rules.

<!-- Note: Description: Identify widget name, atomic layer, file path, and constructor parameters from spec §6.7. Output: Fill in the actual values below. -->

- [ ] **Widget name:** `{WidgetName}` (PascalCase — e.g. `UserAvatarAtom`, `LoginFormMolecule`)
- [ ] **Atomic layer:** `{Atom | Molecule | Organism}` — justification: `{why this layer}`
- [ ] **Location:**
  - Shared UI: `lib/shared/presentation/widgets/{layer}/{widget_name}/{widget_name}.dart`
  - Feature-specific: `lib/features/{feature}/presentation/widgets/{widget_name}/{widget_name}.dart`
- [ ] **Constructor parameters:**
  <!-- Note: Description: List all constructor params with name, Dart type, required/optional, and purpose. Output: Replace with real params. -->
  - `{paramName}`: `{DartType}` — `{required | optional}` — `{purpose}`
- [ ] Uses `const` constructor where possible
- [ ] No direct BLoC access inside Atoms or Molecules — data passed via constructor
- [ ] Organism may read BLoC/Cubit via `context.read()` / `BlocBuilder`

---

## 2. Visual States

<!-- Note: Description: List all visual states this widget must handle per spec §6.7 and design. Output: Replace with real states. -->

- [ ] Default / normal state
- [ ] `{loading | error | empty | disabled | selected}` state — UI behavior: `{description}`

---

## 3. Widget Tests

>

- [ ] **Test file:** `test/features/{feature}/presentation/widgets/{widget_name}_test.dart`
  - _(Shared)_ `test/shared/presentation/widgets/{widget_name}_test.dart`
- [ ] Test cases:
  <!-- Note: Description: Plan widget test cases covering render, props, callbacks, and visual states. Output: Replace with real cases. -->
  - [ ] **Test case:** should render correctly with default props — Input: default constructor params | Expected: key elements visible in widget tree
  - [ ] **Test case:** should call `{callbackParam}` when `{interaction}` — Input: pump widget, trigger `{tap/input}` | Expected: callback invoked with correct args
  - [ ] **Test case:** should render `{state}` state correctly — Input: `{param}={value}` | Expected: `{visible change in widget tree}`

---

_Instruction: The `<!-- Note: ... -->` lines guide the Agent in filling actual content. After filling the "Output", delete all Note lines before starting implementation._
