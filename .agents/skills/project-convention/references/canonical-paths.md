# Canonical Paths (specs, plans, AI)

Copy these paths into `fe.md`, plans, and checklists. **Do not use** `lib/features/` or `lib/shared/`.

| Artifact | Path pattern |
|----------|----------------|
| Entity | `lib/domain/entities/{domain}/{name}.dart` |
| Repo interface | `lib/domain/repositories/{name}_repo.dart` |
| UseCase | `lib/domain/use_case/{name}_use_case.dart` |
| Request model | `lib/data/model/request/{name}_request_model.dart` |
| Response model | `lib/data/model/response/{domain}/{name}_response_model.dart` |
| Remote DS | `lib/data/datasource/remote/{name}_remote_data_source.dart` |
| Local DS | `lib/data/datasource/local/{name}_local_data_source.dart` |
| Repo impl | `lib/data/repositories/{name}_repo_impl.dart` |
| Cubit | `lib/presentation/{feature}/cubit/{feature}_cubit.dart` |
| State | `lib/presentation/{feature}/cubit/{feature}_state.dart` (part file) |
| Screen | `lib/presentation/{feature}/view/{feature}_screen.dart` |
| Route table | `lib/core/common/route.dart` (`AppPage`) |
| DI | `lib/di/injection.dart` |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` |
| Shared widget | `lib/core/widget/` or `lib/widget/` |
| Validation regex | `lib/core/common/constant.dart` |
| API paths | `lib/data/datasource/remote/url_end_point.dart` |

**Imports:** use `package:<name>/...` where `<name>` is the `name:` field in `pubspec.yaml`.

**Data flow:** Screen → Cubit → UseCase → Repo → DataSource → ApiHandler
