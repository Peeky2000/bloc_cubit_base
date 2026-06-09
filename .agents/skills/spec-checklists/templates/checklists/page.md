# Page Checklist — {page-name}

## Prerequisites

<!-- Note: Description: List the spec file this page is derived from. Output: Fill in the actual path below. -->

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.9 Page` in `fe.md`

---

## Required Skills

Before implementing, read the following skills:

- [ ] `flutter-bloc-cubit` skill — consuming BLoC/Cubit via `BlocBuilder`/`BlocListener`
- [ ] `flutter-atomic-design` skill — Page layer: composes Organisms, no direct API calls

---

## 1. Page Definition

> Page composes Organisms and wires BLoC/Cubit state to UI. No business logic in the Page.

<!-- Note: Description: Identify page name, location, route params, and widget composition from spec §6.9. Output: Fill in the actual values below. -->

- [ ] **Page name:** `{FeatureName}Page` (PascalCase, `Page` suffix — e.g. `UserListPage`, `LoginPage`)
- [ ] **Location:** `lib/features/{feature}/presentation/pages/{feature_name}_page.dart`
- [ ] **Route params:** `{none | list params this page receives from go_router}`
- [ ] **Widgets composed:**
  <!-- Note: Description: List all Organisms/Molecules assembled in this page. Output: Replace with real widget names and import paths. -->
  - `{WidgetName}` from `{import path}` — role: `{what it renders}`
- [ ] **BLoC/Cubit used:**
  <!-- Note: Description: List each BLoC/Cubit and how its state drives the UI. Output: Replace with real entries. -->
  - `{BlocName}` — state drives: `{loading indicator | data list | error message}`
- [ ] Triggers initial data load in `initState` or via `BlocProvider` + `add(InitEvent)`
- [ ] Handles all screen states from spec §6.9:
  - [ ] Loading state → `{how: e.g. CircularProgressIndicator, skeleton}`
  - [ ] Error state → `{how: e.g. error message widget, retry button}`
  - [ ] Empty state → `{how: e.g. empty illustration, prompt text}`
  - [ ] Success / data-loaded state → `{how: main content rendered}`

---

## 2. Page Widget Tests

>

- [ ] **Test file:** `test/features/{feature}/presentation/pages/{feature_name}_page_test.dart`
- [ ] Test cases:
  <!-- Note: Description: Plan page-level test cases. Cover: render per BLoC state (loading/error/success), user interactions. Output: Replace with real cases. -->
  - [ ] **Test case:** should show loading indicator when BLoC emits loading state — Input: BLoC stub emits `loading()` | Expected: loading widget visible
  - [ ] **Test case:** should render data when BLoC emits success state — Input: BLoC stub emits `success(data: ...)` | Expected: key data widgets visible
  - [ ] **Test case:** should show error UI when BLoC emits error state — Input: BLoC stub emits `error(message: '...')` | Expected: error widget visible
  - [ ] **Test case:** should navigate to `{TargetPage}` when `{action}` — Input: pump page, trigger `{tap/event}` | Expected: navigation called with correct route

---

_Instruction: The `<!-- Note: ... -->` lines guide the Agent in filling actual content. After filling the "Output", delete all Note lines before starting implementation._
