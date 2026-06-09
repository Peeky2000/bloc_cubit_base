# Template — API-only Plan

Use when adding or modifying endpoints on an existing domain — no new model or migration required. Typical examples: adding a search endpoint, bulk action, export endpoint, or changing input validation logic.

---

## Sections to consider

### Phase 0 — Discovery
- Identify the domain being modified: which controller, service, and repository are involved.
- Read existing code to avoid duplicating logic.
- Determine what new request/response shapes need to be added to the schema.
- Check whether the required service method already exists or needs to be added.

### Phase 1 — Schema Update
- Add `{Entity}{Action}Request` / `{Entity}{Action}Response` to `app/schemas/{domain}/request.py`.
- Update `__init__.py` if new symbols need to be exported.
- Add new converter functions to `converters.py` if needed.

### Phase 2 — Service Logic
- Add a new method to the service if base methods are insufficient.
- Keep exception pattern: raise only `AppException` subclasses.
- Log using `get_trace_logger()`.

### Phase 3 — Controller / Route
- Add the new route handler to the existing controller.
- Use `ResponseBuilder.success()`, `response_model=SuccessResponse[Schema]`.
- No need to register a new router if the controller is already wired in `main.py`.

### Phase 4 — Tests
- Add test cases to the existing `tests/controllers/test_{domain}_controller.py`.
- Cover: happy path + edge cases specific to the new endpoint.

### Phase 5 — Quality Gate
- `poetry run pre-commit run --all-files` passes.

---

## Common task patterns

```markdown
## Phase 1 — Schema Update

- [ ] **[app/schemas]** *(pos-backend)* — Add `{Entity}{Action}Request` and `{Entity}{Action}Response` to `app/schemas/{domain}/request.py`. Update `__init__.py` if new exports are needed. **Verify:** `from app.schemas.{domain} import {Entity}{Action}Request` resolves; Pydantic validation works as expected.

## Phase 2 — Service Logic

- [ ] **[app/services]** *(pos-backend)* — Add `{entity_service}.{action}()` method in `app/services/{domain}_service.py`. Use existing repository base methods where possible. **Verify:** `poetry run pytest tests/services/test_{domain}_service.py -v` covers the new method (happy + error paths).

## Phase 3 — Controller / Route

- [ ] **[app/controllers]** *(pos-backend)* — Add `{METHOD} /{path}` route to `app/controllers/{domain}_controller.py`. Use `ResponseBuilder.success()` and the correct `response_model`. **Verify:** `curl {METHOD} /{entities}/{path}` returns expected payload; bad input returns 422.

## Phase 4 — Tests

- [ ] **[tests]** *(pos-backend)* — Add test cases in `tests/controllers/test_{domain}_controller.py` for the new endpoint. Cover: success, validation error, auth error, edge cases. **Verify:** `poetry run pytest tests/controllers/test_{domain}_controller.py -v` all green.

## Phase 5 — Quality Gate

- [ ] **[pos-server]** *(pos-backend)* — Run `poetry run pre-commit run --all-files`. **Verify:** exits with code 0.
- [ ] **[pos-server]** *(reviewer)* — Review pass: logic correctness, no business logic leaking into controller, ResponseBuilder usage. **Verify:** reviewer signs off.
```

---

## Things people forget

- **`response_model` annotation**: adding a new endpoint but forgetting `response_model=` → Swagger docs are wrong.
- **`__init__.py` exports**: adding a new schema class but forgetting to export it → `ImportError` in the controller.
- **Auth dependency**: does the new endpoint require authentication? If so, add `Depends(get_current_user)`.
- **Pagination**: does the new list endpoint support `limit`/`offset`? Never return all records unbounded.
- **HTTP method semantics**: bulk update should be `PATCH`, not `POST`. Search should be `GET` with query params.
- **Error propagation**: service raises `NotFoundException` → controller does not need to catch it; the middleware handles it.
