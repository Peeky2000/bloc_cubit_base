# Spec Implement Rules —

## Architecture

Follow `docs/prerequisites.md` and `project-convention`:

- Paths: `lib/domain/`, `lib/data/`, `lib/presentation/`, `lib/di/injection.dart`
- Cubit → UseCase → Repository → DataSource
- Injectable constructor DI; no service locator in feature logic
- No `@freezed` requirement for state; use BaseAppState + Equatable + copyWith
- Use `SLIRouting` / `AppPage`

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
derry gen  # if models or DI annotations changed
derry quality
```

## Memory

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
python3 .agents/skills/app-memory/scripts/mem_add.py  # after new artifacts
```
