# Entity — Migration Note

Entities have been **merged with Models**. There is no longer a separate Entity class
in `domain/entities/`. The unified Model class in `shared/models/{domain}/` serves
both domain and data purposes.

See `references/model.md` for the current pattern.

## What changed

| Before | After |
|---|---|
| Entity in `domain/entities/` (pure Dart, no JSON) | Merged into Model |
| Model in `data/models/` (has fromJson + toEntity) | Model in `shared/models/{domain}/` (has fromJson, no toEntity) |
| `toEntity()` conversion in Repository | No conversion needed -- Model is used directly |
| Two classes per concept (e.g. `User` + `UserModel`) | One class per concept (e.g. `User`) |
