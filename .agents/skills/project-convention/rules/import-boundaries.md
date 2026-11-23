# Import Boundaries

Package: `package:<app>/...`

## Rules

```
presentation/*     →  domain, core, di, l10n, widget
presentation/*     →  NEVER data/*

domain/*           →  domain only (+ SDK, firebase if needed in use case)
domain/*           →  NEVER data, presentation, core

data/*             →  domain (entities, repo interfaces), core
data/*             →  NEVER presentation

core/*             →  SDK + pub packages only
core/*             →  NEVER presentation, data, domain
```

## Design libraries (Flutter 3.50)

- Import `package:material_ui/material_ui.dart` and
  `package:cupertino_ui/cupertino_ui.dart`. `package:flutter/material.dart`,
  `package:flutter/cupertino.dart` and `flutter_localizations` are deprecated
  and fail `flutter analyze`.
- Localization delegates: `...GlobalMaterialLocalizations.delegates` from
  `material_ui` (Material, Cupertino and Widgets in one list).
- A pub package still on the old libraries keeps working under the
  `MaterialUiCompatibilityBridge` in `MainApp`. If it also needs a legacy
  `Material` ancestor, wrap it once in `lib/widget/` with a `legacy`-prefixed
  import; never in a screen.

## Examples

```dart
// ✅ Cubit → UseCase (domain)
import 'package:<app>/domain/use_case/auth_use_case.dart';

// ✅ Repo impl → domain interface + data sources
import 'package:<app>/domain/repositories/auth_repo.dart';
import 'package:<app>/data/datasource/remote/auth_remote_data_source.dart';

// ✅ Model implements entity
import 'package:<app>/domain/entities/auth/login.dart';

// ❌ Cubit importing data layer
import 'package:<app>/data/model/response/auth/login_response_model.dart';

// ❌ Cubit importing repo impl
import 'package:<app>/data/repositories/auth_repo_impl.dart';

// ❌ Domain importing Flutter widgets
import 'package:material_ui/material_ui.dart'; // in entity file — WRONG
```

## Cross-feature navigation

- Navigate via `SLIRouting` + `AppPage` constants — not by importing another feature's Cubit.
- Share logic through **UseCase** / **domain repositories**, not presentation-to-presentation imports.
