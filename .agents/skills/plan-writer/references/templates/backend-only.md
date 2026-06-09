# Template — Feature (Full Domain)

Use when adding a complete new domain: model + migration + schema + repository + service + controller. Typical examples: adding a Product, Order, Customer, or any new module from scratch.

---

## Sections to consider

### Phase 0 — Discovery
- Read related spec/brainstorm; confirm domain scope.
- Check which models already exist to avoid duplication.
- Identify relationships with other models.
- List required endpoints (CRUD + custom actions).
- Decide whether a migration is needed.

### Phase 1 — Model & Migration
- Create SQLAlchemy model extending `BaseModel`.
- Define columns, constraints, relationships.
- Generate Alembic migration (`--autogenerate`); review the generated file.
- Verify both `upgrade` and `downgrade` run cleanly.

### Phase 2 — Schemas
- Create folder `app/schemas/{domain}/`.
- `request.py`: `{Entity}CreateRequest`, `{Entity}UpdateRequest`, `{Entity}Response`.
- `schema.py`: internal schemas (e.g., `{Entity}Create` after transforming password → hash).
- `converters.py`: functions to convert `request → internal` and `model → response`.
- `__init__.py`: export all public symbols.

### Phase 3 — Repository
- Create `app/repositories/concrete/{domain}_repository.py`.
- Extend `FullRepositoryImpl[Model]`, initialized via `repository_factory`.
- Add custom methods only when base methods are insufficient.
- Do not pre-build unused methods — only what the service actually needs.

### Phase 4 — Service
- Create `app/services/{domain}_service.py`.
- Extend `BaseService[Model, Repository]`.
- Use base methods (`create`, `get_by_id`, `get_all`, `update`, `delete`) as much as possible.
- Add custom methods only when base methods are insufficient.
- Raise only `AppException` subclasses — never `HTTPException`.
- Use `get_trace_logger()` for logging.

### Phase 5 — Controller & Routes
- Create `app/controllers/{domain}_controller.py` with `APIRouter`.
- Use `ResponseBuilder.success()` / `ResponseBuilder.error()`.
- Use `response_model=SuccessResponse[SchemaType]`.
- Delegate all business logic to the service layer.
- Register router in `main.py`.

### Phase 6 — Tests
- `tests/controllers/test_{domain}_controller.py`: integration test for each endpoint.
- Cover: happy path, 400 bad input, 404 not found, 401/403 auth errors.
- Run `poetry run pytest tests/` to verify the full test suite.

### Phase 7 — Quality Gate
- `poetry run pre-commit run --all-files` passes.
- `poetry run mypy app/` passes (if type annotations were changed).

---

## Common task patterns

```markdown
## Phase 1 — Model & Migration

- [ ] **[app/models]** *(pos-backend)* — Add `{Entity}` model in `app/models/{entity}.py` extending `BaseModel`. Fields: {fields}. Relationships: {relationships}. **Verify:** `poetry run python -c "from app.models.{entity} import {Entity}"` no import error.
- [ ] **[alembic]** *(pos-backend)* — Run `poetry run alembic revision --autogenerate -m "add_{entity}s_table"`. Review generated file: check columns, constraints, indexes, and that `downgrade()` drops correctly. **Verify:** `poetry run alembic upgrade head && poetry run alembic downgrade -1 && poetry run alembic upgrade head` all succeed.

## Phase 2 — Schemas

- [ ] **[app/schemas]** *(pos-backend)* — Create `app/schemas/{domain}/request.py` with `{Entity}CreateRequest`, `{Entity}UpdateRequest`, `{Entity}Response`. Use Pydantic `Field()` for validation. **Verify:** `from app.schemas.{domain} import {Entity}Response` resolves without error.
- [ ] **[app/schemas]** *(pos-backend)* — Create `app/schemas/{domain}/schema.py` (internal), `converters.py`, and `__init__.py` exporting all public symbols. **Verify:** no missing exports; all expected names importable from `app.schemas.{domain}`.

## Phase 3 — Repository

- [ ] **[app/repositories]** *(pos-backend)* — Add `{Entity}Repository(FullRepositoryImpl[{Entity}])` in `app/repositories/concrete/{entity}_repository.py`. Initialize via `repository_factory.create_full_repository({Entity})`. Add custom methods only if needed. **Verify:** `poetry run python -c "from app.repositories.concrete.{entity}_repository import {Entity}Repository"` no error.

## Phase 4 — Service

- [ ] **[app/services]** *(pos-backend)* — Add `{Entity}Service(BaseService[{Entity}, {Entity}Repository])` in `app/services/{entity}_service.py`. Use base CRUD methods; add custom methods only when needed. All exceptions are `AppException` subclasses. **Verify:** `poetry run pytest tests/services/test_{entity}_service.py -v` passes (happy + error paths).

## Phase 5 — Controller & Routes

- [ ] **[app/controllers]** *(pos-backend)* — Add `app/controllers/{entity}_controller.py` with CRUD routes: `POST /`, `GET /`, `GET /{id}`, `PUT /{id}`, `DELETE /{id}`. Use `ResponseBuilder.success()` and `response_model=SuccessResponse[{Entity}Response]`. **Verify:** `curl -X POST /{entities}` returns 201; `curl /{entities}` returns paginated list; bad input returns 422.
- [ ] **[app/controllers]** *(pos-backend)* — Register `{entity}_router` in `main.py` under `/{entities}` prefix. **Verify:** `GET /docs` shows new endpoints; `/health` still returns 200.

## Phase 6 — Tests

- [ ] **[tests]** *(pos-backend)* — Add integration tests in `tests/controllers/test_{entity}_controller.py`. Cover: create, list, get by ID, update, delete, auth errors, validation errors. **Verify:** `poetry run pytest tests/controllers/test_{entity}_controller.py -v` all green.

## Phase 7 — Quality Gate

- [ ] **[pos-server]** *(pos-backend)* — Run `poetry run pre-commit run --all-files`. Fix any lint/format/type issues. **Verify:** command exits with code 0.
- [ ] **[pos-server]** *(reviewer)* — Review pass: SOLID principles, clean code, `ResponseBuilder` usage, exception handling, no business logic in controller. **Verify:** reviewer signs off in PR comment.
```

---

## Things people forget

- **Register router**: creating a new controller but forgetting to import and call `app.include_router()` in `main.py`.
- **`__init__.py` exports**: schema folder missing exports → `ImportError` elsewhere.
- **Down migration**: every `upgrade` needs a working `downgrade` — never leave it as `pass`.
- **Exception type**: services must not raise `HTTPException`, only `AppException` subclasses.
- **Async relationship loading**: SQLAlchemy async requires `selectinload` / `joinedload` — do not rely on default lazy loading.
- **Indexes**: columns used in `WHERE` / `ORDER BY` / `JOIN` need an index — declare it explicitly on the model.
- **Type hints**: all public functions need type annotations sufficient for mypy to pass.
- **`get_trace_logger()`**: use this pattern at every layer — do not use `print()` or `logging.getLogger()` directly.
