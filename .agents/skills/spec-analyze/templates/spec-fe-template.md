# Frontend Spec

---

## 1. Overview

- **Feature / screen name:**
- **Short description:**
- **Created at:**
- **Spec type:** `New screen` | `New component` | `Fix` | `Refactor` | `Improvement`
- **Route (if known):**
- **Affected area:** *(for Fix / Refactor / Improvement — list screens, components, or files impacted)*
- **Requirement source:** (check all that apply)
  - [ ] Figma
  - [ ] Screenshot
  - [ ] Documentation
  - [ ] Description
  - [ ] Stitch

### 1.1 Input

- **Figma link:**
- **Screenshot:** (path or description)
- **Stitch Screen ID:**
- **Reference documentation:**
- **Design notes:**

---

## 2. Analysis

### 2.0 UI Mock

*(Draw ASCII wireframes for each screen state and each major dialog/overlay. Annotate every block with the widget name and atomic layer. Include a widget hierarchy tree at the end.)*

#### *(ScreenName)* Page — `*(PageWidget)*`

```
┌──────────────────────────────────────────────────────────────────┐
│  Scaffold                                                        │
│  └─ ...                                                          │
│                                                                  │
│     ┌──────────────────────────────────────────────────────┐     │
│     │  OrganismWidget  [organism]                          │     │
│     │                                                      │     │
│     │  ┌────────────────────────────────────────────────┐  │     │
│     │  │  MoleculeWidget  [molecule]                    │  │     │
│     │  │  ┌──────────────────┐  ┌──────────────────┐   │  │     │
│     │  │  │  AtomWidget[atom]│  │  AtomWidget[atom]│   │  │     │
│     │  │  └──────────────────┘  └──────────────────┘   │  │     │
│     │  └────────────────────────────────────────────────┘  │     │
│     │                                                      │     │
│     └──────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

*(Add more states: Loading / Error / Empty as needed. Add separate blocks for dialogs/modals.)*

#### Widget hierarchy

```
PageWidget
└─ BlocProvider<XxxBloc>
   └─ BlocListener / BlocBuilder
      └─ Scaffold
         └─ OrganismWidget  [organism]
            ├─ MoleculeWidget  [molecule]
            │  ├─ AtomWidget  [atom]
            │  └─ AtomWidget  [atom]
            └─ AtomWidget  [atom]
```

### 2.1 Layout blocks

| Block name | Structure (what's inside) | Layout | Spacing | Responsive | Component(s) (→ 6.5) |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

### 2.2 Table (columns)

*(Omit if no table.)*

| Column key | Header label | Cell type | Sortable? | Width / align | Component(s) (→ 6.5) |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

**Cell type** — `text` | `avatar + text` | `badge` | `link` | `actions` | `custom`

### 2.3 Form (fields)

*(Omit if no form.)*

| Field key | Label | Input type | Required? | Options / placeholder | Validation | Component(s) (→ 6.5) |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

**Input type** — `text` | `number` | `email` | `password` | `tel` | `textarea` | `select` | `multiselect` | `date` | `datetime` | `checkbox` | `radio` | `file` | `money`

### 2.4 Other elements

*(Buttons, cards, modals, badges, alerts, etc. Omit if none.)*

| Element | Layout | Spacing | Typography | Colors | States | Responsive | Component(s) (→ 6.5) |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

### 2.5 Logic analysis

*(Describe business logic flows: how user actions connect to validation, data processing, and API calls. One row per flow. Omit if purely UI with no logic.)*

| # | Trigger / user action | Logic steps | Validator (→ 6.5) | Utility (→ 6.6) | API (→ 6.4) | Outcome |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

---

## 3. In scope / Out of scope

- **In scope:**
  -
  -
- **Out of scope:**
  -
  -

---

## 4. Questions for requester

**QA1**
- **Question:**
- **Answer:**

---

## 5. Functional requirements

### 5.1 User stories / Use cases

-

### 5.2 Main business flows

- Step 1:
- Step 2:
- Step 3:

### 5.3 Validation / edge conditions

**Field-level validation:**

| Field | Required | Type / format | Min / max | Allowed values | Error message |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

**Error handling (non-field):**

| Scenario | Message / behavior | User action |
|---|---|---|
| Invalid input (client-side) | Show message near field or toast | Fix field, resubmit |
| Permission denied (403) | "You don't have permission…" | Go back / contact admin |
| Network / server error (5xx) | "Something went wrong. Please try again." | Retry button or go back |
| Not found (404) | "Item not found" | Go back to list |

---

## 6. Detail analysis

### 6.1 Entity

*(Domain layer — pure Dart objects that BLoC/Cubit works with. No JSON serialization. Omit if no domain entities needed.)*

| Entity name | Used in (BLoC / Widget) | Location |
|---|---|---|
|  |  |  |

#### 6.1.1 *(EntityName)*

- **Represents:** *(what real-world concept this entity describes, e.g. "a single user account")*
- **Used for:** *(which BLoC / Cubit / Widget consumes it)*
- **Name:** *(PascalCase, no suffix — e.g. `User`, `OrderItem`)*
- **Location:** *(e.g. `lib/features/auth/domain/entities/user.dart` or `lib/shared/domain/entities/user.dart`)*
- **Fields:**

| Field | Dart type | Note |
|---|---|---|
|  |  |  |

#### 6.1.2 *(EntityName — add more as needed)*

- **Represents:**
- **Used for:**
- **Name:**
- **Location:**
- **Fields:**

| Field | Dart type | Note |
|---|---|---|
|  |  |  |

---

### 6.2 Model

*(Data layer — API response classes. Must have `fromJson` / `toJson` and `toEntity()`. Omit if no API calls.)*

| Model name | Mapped from entity | Location |
|---|---|---|
|  |  |  |

#### 6.2.1 *(ModelName — typically `{Entity}Model`)*

- **Maps to entity:** *(entity name from §6.1)*
- **Name:** *(PascalCase with `Model` suffix — e.g. `UserModel`, `OrderItemModel`)*
- **Location:** *(e.g. `lib/features/auth/data/models/user_model.dart` or `lib/shared/data/models/user_model.dart`)*
- **Fields:**

| Field | Dart type | JSON key | Note |
|---|---|---|---|
|  |  |  |  |

#### 6.2.2 *(ModelName — add more as needed)*

- **Maps to entity:**
- **Name:**
- **Location:**
- **Fields:**

| Field | Dart type | JSON key | Note |
|---|---|---|---|
|  |  |  |  |

---

### 6.3 Repository

*(Domain contract between BLoC and DataSource. Abstract interface in domain layer; implementation in data layer. Omit if no data operations.)*

| Repository | Interface location | Impl location |
|---|---|---|
|  |  |  |

#### 6.3.1 *(RepositoryName)*

- **Name:** *(PascalCase with `Repository` suffix — e.g. `AuthRepository`)*
- **Interface location:** *(e.g. `lib/features/auth/domain/repositories/auth_repository.dart`)*
- **Impl location:** *(e.g. `lib/features/auth/data/repositories/auth_repository_impl.dart`)*
- **Methods:**

| Method signature | Returns | Description |
|---|---|---|
|  |  |  |

---

### 6.4 API

*(Retrofit endpoints. Only list APIs this screen actually calls.)*

- **State management:** *(e.g. list data → Cubit; form state → local Cubit; auth token → SecureStorage)*

| API (purpose) | Method | URL | Used for |
|---|---|---|---|
|  |  |  |  |

#### 6.4.1 *(API name)*

- **URL:**
- **Param:**

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Query:**

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Body:** *(POST / PUT / PATCH only)*

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Response:** *(Model name from §6.2)*

#### 6.4.2 *(API name — add more as needed)*

- **URL:**
- **Param:**

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Query:**

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Body:**

| Name | Dart type | Note |
|---|---|---|
|  |  |  |

- **Response:**

---

### 6.5 Validation

*(Omit if no form or validation logic.)*

| Validator | Status | Purpose | Validates | Error message | i18n key | Location |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

**Status** — `Reuse` | `Create new`  
**i18n key** — easy_localization key, e.g. `auth.validation.email_invalid`  
**Location** — `lib/shared/validators/{name}_validator.dart` (shared) or `lib/features/{f}/validators/{name}_validator.dart` (feature-specific)

---

### 6.6 Utility

*(Omit if none.)*

| Utility (function) | Status | Purpose | Inputs | Output | Used in | Location |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

**Status** — `Reuse` | `Create new`  
**Location** — `lib/features/{f}/utils/{name}.dart` (feature-specific) or `lib/shared/utils/{name}.dart` (shared) or `lib/core/utils/{name}.dart` (infrastructure)

---

### 6.7 Widget

*(Flutter widgets following Atomic Design. Run app-memory search before each entry. Keep the summary table, then add one subsection per widget.)*

| Widget | Type | Status | Design ref (→ 2) | Note | Location |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

**Type** — `atom` | `molecule` | `organism`  
**Status** — `Reuse` | `Create new`  
**Location** — `lib/shared/presentation/design_system/{layer}/{widget_name}/{widget_name}.dart` (shared) or `lib/features/{f}/presentation/widgets/{widget_name}.dart` (feature-specific)

---

#### 6.7.1 *(WidgetName)*

- **Type:** `atom` | `molecule` | `organism`
- **Status:** `Create new` | `Reuse`
- **Location:** `lib/.../{widget_name}.dart`
- **Description:** *(What this widget does and how it renders. Include key behavior, variants, and any interaction.)*
- **Props:**

```dart
class WidgetNameProps extends StatelessWidget {
  // final propName: DartType;
}
```

- **Mock:**

```
 State label:
 ┌──────────────────────────────────────┐
 │                                      │
 │   (ASCII art preview of widget)      │
 │                                      │
 └──────────────────────────────────────┘
  layout: ...
  states: ● active  ○ inactive  ░ loading  ┌─ ─┐ dashed/placeholder
```

- **Sub-components:** *(list child widgets if molecule/organism, else omit)*
- **File structure:**

```
lib/.../{widget_name}/
├── {widget_name}.dart
└── {widget_name}_test.dart
```

*(Repeat 6.7.2, 6.7.3 … for each widget in the summary table above.)*

---

### 6.8 BLoC / Cubit

*(State management for this screen.)*

- **Type:** `Cubit` | `BLoC`
- **Name:** *(PascalCase — e.g. `UserListCubit`, `AuthBloc`)*
- **State class:** *(e.g. `UserListState` — sealed `@freezed` class)*
- **Location:** *(e.g. `lib/features/auth/presentation/bloc/auth_bloc.dart`)*

**States:**

| State variant | When emitted | Key fields |
|---|---|---|
| loading |  |  |
| success |  |  |
| error |  |  |

**Methods / Events:**

| Method (Cubit) or Event (BLoC) | Triggers | Description |
|---|---|---|
|  |  |  |

---

### 6.9 Page

- **Location:** *(e.g. `lib/features/{feature}/presentation/pages/{name}_page.dart`)*
- **Main sections:**
  -
  -
- **Screen states:**
  - **Loading:**
  - **Empty:**
  - **Error:**
  - **Success:**
- **User actions:**
  -
  -

---

### 6.10 Route

- **Type:** `New screen` | `New section` | *(describe if fix/refactor)*
- **Pattern:** `List/Table` | `Form` | `Wizard` | `Tabbed Form` | `Detail` | `Dashboard`
- **Parent route / shell:** *(e.g. `MainShell`, `AuthShell`, `BottomNavShell`, top-level)*
- **Path:** *(e.g. `/users`, `/users/:id/edit`)*
- **Route key:** *(camelCase constant name — e.g. `userList`, `createOrder`)*
- **Params:** *(Dart type — `void` if none, or `({String id})` for named params)*
- **GoRoute location:** *(file path — e.g. `lib/core/router/app_router.dart` or `lib/features/{f}/router.dart`)*

---

## 7. UI/UX guidelines

- **Style / pattern:**
- **Accessibility:**
- **Responsive:**
- **Loading / error UI:**

---

## 8. Open questions / constraints

- **Technical constraints:**
- **Other open points:**

---

## 9. Acceptance criteria

- [ ]
- [ ]
- [ ]

---

## 10. Attachments

- Figma link:
- Documentation link:
- Screenshot / files:
- Stitch Screen ID:
