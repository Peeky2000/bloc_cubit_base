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
import 'package:flutter/material.dart'; // in entity file — WRONG
```

## Cross-feature navigation

- Navigate via `SLIRouting` + `AppPage` constants — not by importing another feature's Cubit.
- Share logic through **UseCase** / **domain repositories**, not presentation-to-presentation imports.
