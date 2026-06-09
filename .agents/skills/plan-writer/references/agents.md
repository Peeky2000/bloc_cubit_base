# Agents — Layer Mapping

Use this table to tag every task with the correct agent.

| Agent | Scope | Typical work |
|---|---|---|
| `pos-backend` | Entire `pos-server` repo | Model, schema, repository, service, controller, migration, test, utils, middleware, handler |
| `reviewer` | `pos-server` repo | Audit completed code — never authors code, only reviews |

## Routing Rules

- A task that **writes or modifies code** in the repo → owned by `pos-backend`.
- A task that **only reviews** completed code → owned by `reviewer`. Do not schedule reviews task-by-task; bundle a single "review pass" task at the end of each phase or at the end of the plan.
- If a task involves **design clarification** before any code is written, make it a discovery task owned by `pos-backend` and specify the expected output (decision, doc, note).

## Layer Tags

Use the most specific layer tag that applies. The project has a single repo, so tags represent the code layer rather than a separate side.

| Tag | When to use |
|-----|-------------|
| `app/models` | Add or modify SQLAlchemy model |
| `app/schemas` | Add or modify Pydantic schema, request, response, converter |
| `app/repositories` | Add or modify repository (`concrete/` or `core/`) |
| `app/services` | Add or modify service logic |
| `app/controllers` | Add or modify FastAPI router / endpoint |
| `app/middlewares` | Add or modify middleware |
| `app/handlers` | Add or modify exception handler |
| `app/utils` | Add or modify utility function |
| `app/jobs` | Add or modify background job |
| `app/workers` | Add or modify async worker |
| `app/config` | Add or modify config / settings |
| `alembic` | Create or modify Alembic migration file |
| `tests` | Add or modify tests |
| `docs` | Add or modify documentation |
| `infra` | Dockerfile, docker-compose, scripts |
| `pos-server` | Use for review pass tasks (whole repo); do not use for specific code tasks |

## Standard Task Pattern

```markdown
- [ ] **[layer]** *(pos-backend)* — Task description. **Verify:** how to verify completion.
```

Examples:

```markdown
- [ ] **[app/models]** *(pos-backend)* — Add `Category` model in `app/models/category.py`. **Verify:** `poetry run alembic upgrade head` succeeds; table `categories` visible in DB.
- [ ] **[app/schemas]** *(pos-backend)* — Create `app/schemas/categories/` with `request.py`, `schema.py`, `converters.py`, `__init__.py`. **Verify:** `from app.schemas.categories import CategoryResponse` resolves without error.
- [ ] **[alembic]** *(pos-backend)* — Generate migration `alembic revision --autogenerate -m "add_categories_table"`. Review generated file; ensure `downgrade()` is correct. **Verify:** `poetry run alembic upgrade head && poetry run alembic downgrade -1` both succeed.
- [ ] **[pos-server]** *(reviewer)* — Review pass: SOLID principles, clean code, ResponseBuilder usage, exception handling patterns. **Verify:** reviewer signs off in PR comment.
```

## Commonly Forgotten Tasks

- **Register router**: creating a new controller but forgetting to import and call `app.include_router()` in `main.py`.
- **`__init__.py` exports**: new schema classes added but not exported → `ImportError` elsewhere.
- **Pre-commit gate**: the last task in every plan must verify `poetry run pre-commit run --all-files` passes.
- **Mypy check**: if new type annotations are added, verify `poetry run mypy app/` passes.
- **Down migration**: every `upgrade` must have a tested `downgrade` — never leave it as `pass`.
- **Exception handling**: services must only raise `AppException` subclasses — never `HTTPException`.
