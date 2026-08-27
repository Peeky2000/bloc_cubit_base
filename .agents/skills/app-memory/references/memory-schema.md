# App Memory Schema

Memory files under `.agents/memories/` index reusable artifacts; query and
mutate them only through the scripts documented in `app-memory/SKILL.md`.

Every item has a stable name, repository-relative `location`, concise
description, and optional domain/tags. Use these canonical locations:

| Artifact | Location pattern |
|---|---|
| feature | `lib/presentation/{feature}/` |
| Cubit/BLoC | `lib/presentation/{feature}/cubit|bloc/` |
| screen/widget | `lib/presentation/{feature}/view/` or `lib/core/widget/` |
| cross-product widget | `lib/modules/sli_common/` with public import name |
| entity | `lib/domain/entities/{domain}/` |
| repository contract | `lib/domain/repositories/` |
| UseCase | `lib/domain/use_case/` |
| model | `lib/data/model/request|response/` |
| DataSource | `lib/data/datasource/remote|local/` |
| repository impl | `lib/data/repositories/` |
| route | `lib/core/common/route.dart` |
| utility/extension | matching existing folder under `lib/core/` |

Do not index generated files, private implementation details, stale paths, or
third-party APIs hidden behind `sli_common`. Models are json_serializable DTOs;
entities are pure domain contracts; routes use AppPage/SLIPage; state owners use
Cubit/BLoC with injectable constructor dependencies.
