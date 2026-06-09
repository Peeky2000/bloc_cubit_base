# API Design Analysis —

Design REST endpoints for a screen/feature using **Dio + ApiHandler + UrlEndPoint**.

Reference: `lib/data/datasource/remote/auth_remote_data_source.dart`, `url_end_point.dart`, `docs/prerequisites.md`.

## Pre-reading

1. Existing models in `lib/data/model/response/`
2. Entities in `lib/domain/entities/`
3. Current `UrlEndPoint` groups
4. Cubit/UseCase that will consume the API

## Questions

1. Screens in scope and user actions?
2. Read vs write operations per screen?
3. Endpoint list: method, path, auth, body, response model name?
4. Field mapping: JSON key → model field (`@JsonKey`)?
5. Error cases and how `ErrorMapper` should surface them?
6. App-side changes: models, remote DS, repo, use case, cubit?

## Output

Save to `docs/brainstorm/YYYY-MM-DD-{topic}-api.md` with endpoint table + per-endpoint request/response JSON examples.

## App implementation list (section 11)

- `lib/data/model/...`
- `lib/data/datasource/remote/...`
- `lib/domain/repositories/` + `lib/data/repositories/`
- `lib/domain/use_case/`
- `lib/presentation/.../cubit/`

Do **not** reference `lib/shared/api`, Retrofit, or Drift unless added to this project later.
