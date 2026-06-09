# Template — Full-feature Plan (multi-phase)

Use when a feature is large enough to span multiple domains, or when careful upfront design is needed before coding. Examples: Order checkout flow (Order + Payment + Inventory), Authentication + Authorization system, Report + Export module.

Key principle: **build vertically per feature slice** — each phase should be demo-able or smoke-testable end-to-end. Never end a phase with half-done layers.

---

## Sections to consider

### Phase 0 — Discovery & Design
- Read all related specs/brainstorm docs.
- Sketch the domain/entity map and relationships (text or ASCII diagram).
- List required endpoints with sample request/response shapes.
- Determine migration order (which domain must exist before another).
- Identify service dependencies (does Service A call Service B?).
- Document important edge cases and business rules.

### Phase 1 — Foundation (Models & Migrations)
- Models for all involved domains.
- Alembic migrations in correct order (FK parent before child).
- No business logic or API in this phase.
- Exit criteria: DB schema is complete and stable.

### Phase 2 — Schemas & Repositories
- Schemas (request/response/internal) for all domains.
- Repositories for all domains.
- Unit tests for any custom repository methods.
- Exit criteria: data access layer is complete and tested.

### Phase 3 — Services (Business Logic)
- Services for each domain.
- Implement business rules, validation, and cross-domain calls.
- Unit tests for service methods (happy + error paths).
- Exit criteria: all business logic is complete and testable without HTTP.

### Phase 4 — API Surface
- Controllers + routes for each domain.
- Wire into `main.py`.
- Smoke test each endpoint with curl.
- Exit criteria: API works end-to-end.

### Phase 5 — Hardening
- Rate limiting where needed.
- Audit logging for sensitive actions.
- Edge case validation and error handling.

### Phase 6 — Tests & Quality Gate
- Full integration test coverage.
- `poetry run pytest` passes.
- `poetry run pre-commit run --all-files` passes.
- End-to-end demo flow verified.

---

## Common task patterns

```markdown
## Phase 0 — Discovery

- [ ] **[docs]** *(pos-backend)* — Produce `docs/design/{feature}-design.md`: domain map, entity relationships, endpoint list, business rules, edge cases, open questions. **Verify:** doc is present; all open questions are resolved before Phase 1 starts.

## Phase 1 — Foundation

- [ ] **[app/models]** *(pos-backend)* — Add `{EntityA}` model in `app/models/{entity_a}.py`. **Verify:** `poetry run python -c "from app.models.{entity_a} import {EntityA}"` no error.
- [ ] **[app/models]** *(pos-backend)* — Add `{EntityB}` model in `app/models/{entity_b}.py` with FK to `{EntityA}`. **Verify:** same import check.
- [ ] **[alembic]** *(pos-backend)* — Generate and review migrations for all new tables. Ensure FK order is correct (parent table before child table). **Verify:** `poetry run alembic upgrade head && poetry run alembic downgrade base && poetry run alembic upgrade head` all succeed.

## Phase 2 — Schemas & Repositories

- [ ] **[app/schemas]** *(pos-backend)* — Create schema folders for `{domain_a}` and `{domain_b}` with `request.py`, `schema.py`, `converters.py`, `__init__.py`. **Verify:** all imports from `app.schemas.{domain_a}` and `app.schemas.{domain_b}` resolve.
- [ ] **[app/repositories]** *(pos-backend)* — Add `{EntityA}Repository` and `{EntityB}Repository`. **Verify:** `poetry run pytest tests/repositories/` passes.

## Phase 3 — Services

- [ ] **[app/services]** *(pos-backend)* — Add `{EntityA}Service` implementing business rules: {rules}. **Verify:** `poetry run pytest tests/services/test_{entity_a}_service.py -v` covers all scenarios.
- [ ] **[app/services]** *(pos-backend)* — Add `{EntityB}Service` with any cross-domain calls to `{EntityA}Service` where needed. **Verify:** same pattern.

## Phase 4 — API Surface

- [ ] **[app/controllers]** *(pos-backend)* — Add `{entity_a}_controller.py` and `{entity_b}_controller.py`. Register both in `main.py`. **Verify:** `GET /docs` shows all new endpoints; smoke test each with curl.

## Phase 5 — Hardening

- [ ] **[app/middlewares]** *(pos-backend)* — Add rate limiting / audit logging / permission checks for sensitive endpoints. **Verify:** sensitive action logged in DB; rate limit returns 429 on excess requests.

## Phase 6 — Tests & Quality Gate

- [ ] **[tests]** *(pos-backend)* — Add integration tests covering the full user flow: {flow description}. **Verify:** `poetry run pytest tests/ -v` all green.
- [ ] **[pos-server]** *(pos-backend)* — Run `poetry run pre-commit run --all-files`. **Verify:** exits with code 0.
- [ ] **[pos-server]** *(reviewer)* — Review pass: architecture, SOLID principles, error handling, test coverage. **Verify:** reviewer signs off.
```

---

## Things people forget

- **Cross-service dependency order**: if `OrderService` calls `InventoryService`, ensure `InventoryService` is properly injected — check dependency injection wiring.
- **Transaction boundary**: if creating an Order and decrementing Inventory must be atomic, one service method must own the DB transaction — plan this explicitly.
- **FK migration order**: child table migration must run after parent table migration.
- **Schema contract consistency**: API response shapes must be consistent — `id` is always `str` (UUID), timestamps are always ISO 8601.
- **Rollback drill**: large features mean complex migrations — test `downgrade` on a clone DB before deploying.
- **Circular imports**: cross-domain service calls can create circular imports in Python — design layer boundaries carefully.
