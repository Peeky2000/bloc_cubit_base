# Memory Schema

App memory stores indexed metadata about the codebase in `.agents/memory/`.

**Contraindication:** Agent must never read files in `.agents/memories/`. Use `mem_search.py` only to query.

---

## Storage

- **Path**: `.agents/memories/` (project root)
- **Files**: One file per type (see table below)
- **Format**: JSON array per file

| Type      | File              |
|-----------|-------------------|
| widget    | widgets.json      |
| validator | validators.json   |
| feature   | features.json     |
| utility   | utilities.json    |
| icon      | icons.json        |
| model     | models.json       |
| entity    | entities.json     |
| api       | apis.json         |
| route     | routes.json       |
| bloc      | blocs.json        |
| extension | extensions.json   |

---

## Memory Types

### Widget

Covers two locations:
- **Design system** — atoms/molecules/organisms in `lib/shared/presentation/design_system/` (`scope: shared`)
- **Feature widgets** — widgets inside `lib/features/*/presentation/widgets/` (`scope: <feature-name>`)

```json
{
  "type": "widget",
  "name": "AppButton",
  "description": "Primary button with loading state and disabled style",
  "props": ["label", "onPressed", "isLoading", "isDisabled"],
  "keywords": ["button", "cta", "primary", "loading"],
  "location": "lib/shared/presentation/design_system/atoms/app_button/app_button.dart",
  "group": "atoms",
  "scope": "shared"
}
```

```json
{
  "type": "widget",
  "name": "LoginForm",
  "description": "Login form with email/password fields and submit button",
  "props": ["onSubmit", "isLoading"],
  "keywords": ["login", "form", "auth", "email", "password"],
  "location": "lib/features/auth/presentation/widgets/login_form.dart",
  "scope": "auth"
}
```

| Field       | Required | Description                                                                  |
|-------------|----------|------------------------------------------------------------------------------|
| type        | Yes      | `"widget"`                                                                   |
| name        | Yes      | PascalCase widget name                                                       |
| description | Yes      | What it does, when to use                                                    |
| props       | No       | Array of constructor parameter names                                         |
| keywords    | No       | Extra search terms (usage, behavior)                                         |
| location    | Yes      | File path relative to project root                                           |
| group       | No       | `atoms` \| `molecules` \| `organisms` — only for design_system widgets       |
| scope       | No       | `shared` for design_system; or feature name (e.g. `auth`, `product`, `cart`) |

---

### Validator

Validation functions or classes in `lib/core/utils/` or `lib/features/*/`.

```json
{
  "type": "validator",
  "name": "emailValidator",
  "description": "Validates email format — returns error string or null",
  "keywords": ["email", "validation", "format", "form"],
  "location": "lib/core/utils/validators/email_validator.dart"
}
```

---

### Feature

Feature modules in `lib/features/`.

```json
{
  "type": "feature",
  "name": "auth",
  "description": "Authentication — login, logout, token refresh, session guard",
  "keywords": ["auth", "login", "logout", "token", "session"],
  "location": "lib/features/auth/"
}
```

---

### Utility

Pure helper functions in `lib/core/utils/`.

```json
{
  "type": "utility",
  "name": "formatDate",
  "description": "Formats a DateTime to display string (dd MMM yyyy)",
  "keywords": ["date", "format", "display", "datetime"],
  "location": "lib/core/utils/format_date.dart"
}
```

---

### Icon

Widget icons (SVG or custom painter) in `lib/shared/presentation/design_system/atoms/`.

```json
{
  "type": "icon",
  "name": "ArrowForwardIcon",
  "description": "Arrow forward icon for primary CTA buttons",
  "props": ["color", "size"],
  "keywords": ["arrow", "forward", "icon", "cta"],
  "location": "lib/shared/presentation/design_system/atoms/icons/arrow_forward_icon.dart"
}
```

---

### Model

Freezed data classes (Data layer) with `fromJson` / `toJson`. Located in `lib/features/*/data/models/` or `lib/shared/data/models/`.

```json
{
  "type": "model",
  "name": "AuthTokenModel",
  "description": "Auth token response from server — accessToken, refreshToken, expiresIn",
  "model_type": "class",
  "keywords": ["auth", "token", "login", "response"],
  "location": "lib/features/auth/data/models/auth_token_model.dart"
}
```

| Field       | Required | Description                                                        |
|-------------|----------|--------------------------------------------------------------------|
| type        | Yes      | `"model"`                                                          |
| name        | Yes      | PascalCase class name ending with `Model`                          |
| description | Yes      | What API response/request this model represents                    |
| model_type  | No       | `class` \| `interface` \| `type`                                   |
| keywords    | No       | Extra search terms (resource, domain, endpoint)                    |
| location    | Yes      | File path in `lib/features/*/data/models/` or `lib/shared/data/models/` |

---

### Entity

Freezed domain classes (Domain layer) — no JSON, pure Dart. Located in `lib/features/*/domain/entities/` or `lib/shared/domain/entities/`.

```json
{
  "type": "entity",
  "name": "UserEntity",
  "description": "Domain entity representing a user account",
  "fields": ["id", "email", "name", "avatar"],
  "scope": "shared",
  "keywords": ["user", "account", "domain", "profile"],
  "location": "lib/shared/domain/entities/user.dart"
}
```

| Field       | Required | Description                                                               |
|-------------|----------|---------------------------------------------------------------------------|
| type        | Yes      | `"entity"`                                                                |
| name        | Yes      | PascalCase class name ending with `Entity`                                |
| description | Yes      | Domain concept this entity represents                                     |
| fields      | No       | Array of field names                                                      |
| scope       | No       | `shared` — shared across features; or feature name (e.g. `auth`)         |
| keywords    | No       | Extra search terms (domain concept, usage)                                |
| location    | Yes      | File path in `lib/*/domain/entities/`                                     |

---

### API

Retrofit datasource method definitions in `lib/features/*/data/datasources/`.

```json
{
  "type": "api",
  "name": "loginApi",
  "description": "POST login with email/password — returns AuthTokenModel",
  "method": "POST",
  "endpoint": "/api/auth/login",
  "feature": "auth",
  "keywords": ["auth", "login", "token", "post"],
  "location": "lib/features/auth/data/datasources/auth_remote_datasource.dart"
}
```

| Field       | Required | Description                                        |
|-------------|----------|----------------------------------------------------|
| type        | Yes      | `"api"`                                            |
| name        | Yes      | camelCase method name                              |
| description | Yes      | What the endpoint does                             |
| method      | Yes      | `GET` \| `POST` \| `PUT` \| `PATCH` \| `DELETE`   |
| endpoint    | No       | URL path (e.g. `/api/users/:id`)                   |
| feature     | No       | Feature module that owns this datasource           |
| keywords    | No       | Extra search terms (resource, action, domain)      |
| location    | Yes      | File path in `lib/features/*/data/datasources/`    |

---

### Route

go_router route definitions. Route names are in `lib/features/*/` or `lib/core/router/`.

```json
{
  "type": "route",
  "name": "loginRoute",
  "description": "Login screen — entry point for unauthenticated users",
  "path": "/login",
  "params": [],
  "feature": "auth",
  "keywords": ["auth", "login", "nav", "route"],
  "location": "lib/features/auth/auth_router.dart"
}
```

| Field       | Required | Description                                               |
|-------------|----------|-----------------------------------------------------------|
| type        | Yes      | `"route"`                                                 |
| name        | Yes      | camelCase route name constant (e.g. `loginRoute`)         |
| description | Yes      | What screen this leads to, when used                      |
| path        | No       | URL path (e.g. `/profile/:id`)                            |
| params      | No       | Path parameters (e.g. `["id"]`)                           |
| feature     | No       | Feature module this route belongs to                      |
| keywords    | No       | Extra search terms (screen name, action)                  |
| location    | Yes      | File path defining the route                              |

---

### BLoC / Cubit

BLoC or Cubit state management classes in `lib/features/*/presentation/bloc/`.

```json
{
  "type": "bloc",
  "name": "AuthBloc",
  "description": "Manages auth state — login, logout, session check, token refresh",
  "bloc_type": "bloc",
  "state": "AuthState",
  "events": ["LoginEvent", "LogoutEvent", "TokenRefreshEvent"],
  "feature": "auth",
  "keywords": ["auth", "state", "login", "logout", "bloc"],
  "location": "lib/features/auth/presentation/bloc/auth_bloc.dart"
}
```

| Field       | Required | Description                                                         |
|-------------|----------|---------------------------------------------------------------------|
| type        | Yes      | `"bloc"`                                                            |
| name        | Yes      | PascalCase class name (e.g. `AuthBloc`, `ProductCubit`)             |
| description | Yes      | What state/flow this manages                                        |
| bloc_type   | No       | `bloc` \| `cubit` — default `cubit`                                 |
| state       | No       | State class name (e.g. `AuthState`)                                 |
| events      | No       | Event class names — only for BLoC (empty for Cubit)                 |
| feature     | No       | Feature module this bloc belongs to                                 |
| keywords    | No       | Extra search terms (domain, actions)                                |
| location    | Yes      | File path of the BLoC/Cubit class                                   |

---

### Extension

Dart extension methods on built-in or custom types.

```json
{
  "type": "extension",
  "name": "StringExtension",
  "description": "Extensions on String — isValidEmail, capitalize, truncate",
  "on": "String",
  "keywords": ["string", "email", "validate", "capitalize", "truncate"],
  "location": "lib/core/utils/string_extension.dart"
}
```

| Field       | Required | Description                                             |
|-------------|----------|---------------------------------------------------------|
| type        | Yes      | `"extension"`                                           |
| name        | Yes      | PascalCase extension name                               |
| description | Yes      | What methods this extension provides                    |
| on          | Yes      | The type being extended (e.g. `String`, `BuildContext`) |
| keywords    | No       | Extra search terms (method names, use cases)            |
| location    | Yes      | File path                                               |

---

## Scripts

| Script          | Purpose                                                                        |
|-----------------|--------------------------------------------------------------------------------|
| `mem_search.py` | Tokenize query → score each entry → return ranked results                      |
| `mem_add.py`    | Add new entry (supports all 11 types)                                          |
| `mem_update.py` | Update existing entry (match by --location or --name, merge provided fields)   |
