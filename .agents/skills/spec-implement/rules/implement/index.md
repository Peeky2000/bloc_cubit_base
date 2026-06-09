# Spec Implement Rules —

## Architecture

Follow `docs/prerequisites.md` and `project-convention`:

- Paths: `lib/domain/`, `lib/data/`, `lib/presentation/`, `lib/di/injection.dart`
- Cubit → UseCase → Repository → DataSource
- No `injectable`, no `@freezed` for state, no `go_router`

## Per checklist type

| Checklist | Skills to load |
|-----------|----------------|
| entity | flutter-model-entity |
| data-model | flutter-model-entity |
| repository | flutter-repository |
| api | flutter-datasource |
| bloc-cubit | flutter-bloc-cubit, flutter-di, flutter-error-handling |
| route | flutter-router |
| component | flutter-atomic-design |
| page | flutter-atomic-design, flutter-bloc-cubit |
| validation | project-convention (Cubit + constant.dart + l10n) |

## Quality

```bash
dart format lib/
flutter analyze
dart run build_runner build --delete-conflicting-outputs  # if models changed
```

## Memory

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
python3 .agents/skills/app-memory/scripts/mem_add.py  # after new artifacts
```
