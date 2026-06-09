# Project Prerequisites (AI / specs)

Cập nhật khi fork base sang dự án mới. Đọc `pubspec.yaml` để lấy tên package thực tế.

---

## 1. Application

| Field | Value |
|-------|--------|
| Package name | `pubspec.yaml` → field `name:` |
| Import prefix | `package:<name>/...` |
| Platforms | Android, iOS |
| Entry | `lib/main_*.dart` (env variants) |

---

## 2. Architecture

**Clean Architecture** — presentation → domain → data → core:

```
lib/presentation/   # UI + Cubit
lib/domain/         # entities, repositories (abstract), use_case
lib/data/           # models, datasources, repository impl
lib/core/           # routing, errors, shared widgets, app config
lib/di/             # Injector (get_it)
```

**Luồng bắt buộc:** `Cubit → UseCase → Repository → DataSource`

Chi tiết: [project-convention](../.agents/skills/project-convention/SKILL.md) · [canonical-paths](../.agents/skills/project-convention/references/canonical-paths.md)

---

## 3. Tech stack

| Concern | Implementation |
|---------|----------------|
| State | `flutter_bloc`, `BaseCubit`, `BaseAppState`, `LoadingStatus` |
| DI | `get_it`, `lib/di/injection.dart` |
| HTTP | `dio`, `ApiHandler` / `ApiClient` |
| Serialization | `json_serializable` + `build_runner` |
| Navigation | `SLIRouting`, `AppPage` |
| Localization | gen-l10n — `lib/l10n/arb/` |
| Errors | `handleErrorResponse`, `ErrorMapper` |

**Không dùng trong base:** `go_router`, `injectable`, `freezed`, `retrofit`, `easy_localization`, `lib/features/`, `lib/shared/`.

---

## 4. Layer order (feature mới)

Entity → Model → DataSource → Repository → UseCase → Cubit → Screen → Route → ARB → DI

---

## 5. AI workflow

| Artifact | Path |
|----------|------|
| Process | `/ai-process.md` |
| Brainstorm | `docs/brainstorm/` |
| Spec | `docs/specs/{NNN}-{name}/fe.md` |
| Plan | `docs/plan/` |
| Review | `docs/reviews/` |

---

## 6. Quality commands

```bash
flutter pub get
dart format lib/
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```

---

## 7. App memory

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
```
