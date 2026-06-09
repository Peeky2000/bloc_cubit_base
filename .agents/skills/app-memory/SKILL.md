---
name: app-memory
description: >
  Indexed metadata about widgets, models, routes, blocs, etc. in .agents/memories/.
  Use mem_search.py before creating duplicates. Paths follow layout
  (presentation/, domain/, data/, core/) — NOT lib/features/ or lib/shared/.
---

# App Memory

## Scripts

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
python3 .agents/skills/app-memory/scripts/mem_add.py ...
python3 .agents/skills/app-memory/scripts/mem_update.py ...
```

## Path conventions for `location` field

| Artifact | Example path |
|----------|----------------|
| Cubit | `lib/presentation/sign_in/cubit/sign_in_cubit.dart` |
| Screen | `lib/presentation/sign_in/view/sign_in_screen.dart` |
| Entity | `lib/domain/entities/auth/login.dart` |
| Model | `lib/data/model/response/auth/login_response_model.dart` |
| Repo | `lib/domain/repositories/auth_repo.dart` |
| DataSource | `lib/data/datasource/remote/auth_remote_data_source.dart` |
| Route | `lib/core/common/route.dart` |
| Widget | `lib/core/widget/dialog_util.dart` |

## Rules

- Never read `.agents/memories/*.json` directly — query via `mem_search.py` only
- After creating artifacts, run `mem_add.py` with correct base paths
- Do not use paths from other projects (`lib/features/`, `lib/shared/`)
