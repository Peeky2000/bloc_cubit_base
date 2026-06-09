---
name: plan-writer
description: "Convert a brainstorm doc, design decision, or concrete feature request into a detailed implementation plan as a grouped, ordered, agent-tagged Markdown checklist. Trigger on: 'write plan', 'create plan', 'make a plan', 'detailed plan', 'implementation plan', 'plan-writer', 'checklist plan', 'break this down', 'split into tasks', 'tasks list'. Also trigger on Vietnamese: 'viết plan', 'tạo plan', 'lên plan', 'kế hoạch triển khai', 'phân chia task', 'chia task'. Always trigger this skill when the user has agreed on what to build and now wants to organize the actual work — even if they don't use the word 'plan' explicitly. Especially apply right after a brainstorm session is finalized, or when the user asks 'how do we start', 'what's next', 'how do we split the work'."
---

# Plan Writer

## Purpose

Turn a finalized design (brainstorm doc, spec, or clear feature request) into a concrete, ordered checklist that any agent or human can pick up and execute.

A good plan answers four questions for **every** task:

1. **What** is the unit of work (one verifiable change, not a vague theme)?
2. **Where** does it live — which layer (`app/models`, `app/schemas`, `app/repositories`, `app/services`, `app/controllers`, `alembic`, `tests`, `docs`)?
3. **Who** owns it — which agent (`pos-backend`, `reviewer`)?
4. **How** do we know it is done — a verifiable criterion, not "looks good"?

Plans without those four are wishlists. Wishlists are how scope creeps and how nobody knows whose turn it is.

---

## Workflow

### Step 1 — Identify Source & Scope

Find the input first:

- **Brainstorm doc** in `docs/` — read it end-to-end, including all finalized decisions and any open questions.
- **Spec file** in `docs/specs/` — treat as authoritative source.
- **User-supplied requirement** in the conversation — extract the goal, constraints, and edge cases the user already mentioned.
- If both exist, prefer the doc as the source of truth and use the conversation only to fill gaps.

**⛔ Pre-flight check — MUST pass before writing any plan:**

Before drafting a single task, scan the source document for any unresolved open questions. A question is unresolved if:
- It is marked as open / pending / TBD / unclear, or
- It has no answer in the document or in the conversation.

If **any** open question remains:
1. List every unresolved question explicitly.
2. Tell the user: "The following questions must be answered before the plan can be written."
3. **Stop. Do not write the plan.**

Only proceed to Step 2 when **every question has a confirmed answer**. If the user cannot answer a question, they must escalate to QA / PM / BRSE first.

A plan built on unanswered questions will be rewritten — and that costs more than one blocking message now.

Then classify the **scope**, which determines the template to load:

| Scope | When to use | Template |
|-------|------|----------|
| **feature** | New domain feature: model + schema + repository + service + controller + migration | `references/templates/backend-only.md` |
| **api-only** | New/modified endpoints on existing domain — no new model or migration needed | `references/templates/api-only.md` |
| **migration-heavy** | DB schema rewrite, domain refactor, large data migration | `references/templates/migration-heavy.md` |
| **job-worker** | New background job, scheduled task, or async worker | `references/templates/job-worker.md` |

If unsure, default to **feature** — easier to remove sections than to add them.

### Step 2 — Load Template

Read `references/templates/{scope}.md`. The template lists the section headings and the kinds of tasks that usually appear under each. It is a checklist of what to *consider*, not what to copy verbatim — drop sections that don't apply, add sections the template missed.

Also load `references/agents.md` for the agent mapping. Use it to tag every task correctly.

### Step 3 — Draft the Checklist

For each section, write tasks in this exact format:

```markdown
- [ ] **[layer]** *(agent)* — Task description. **Verify:** how to know it is done.
```

Where:
- **layer** = `app/models` | `app/schemas` | `app/repositories` | `app/services` | `app/controllers` | `app/middlewares` | `app/utils` | `app/handlers` | `app/jobs` | `app/workers` | `alembic` | `tests` | `docs` | `infra`
- **agent** = `pos-backend` | `reviewer` (see `references/agents.md`)
- **Verify** = an objective check: a passing pytest, a curl returning 200, a migration applying cleanly, `poetry run pre-commit run --all-files` passing, etc. Not "code reviewed" or "looks correct".

**Example task lines:**

```markdown
- [ ] **[app/models]** *(pos-backend)* — Add `Product` model in `app/models/product.py` extending `BaseModel`. Fields: `name`, `sku`, `price`, `category_id`, `is_active`. **Verify:** `poetry run alembic upgrade head` succeeds; table visible in DB.
- [ ] **[app/schemas]** *(pos-backend)* — Create `app/schemas/products/` with `request.py` (ProductCreateRequest, ProductUpdateRequest, ProductResponse), `schema.py` (internal ProductCreate), `converters.py`, `__init__.py`. **Verify:** imports from `app.schemas.products` resolve without error.
- [ ] **[app/repositories]** *(pos-backend)* — Add `ProductRepository(FullRepositoryImpl[Product])` in `app/repositories/concrete/product_repository.py`. **Verify:** `poetry run pytest tests/repositories/test_product_repository.py` passes.
- [ ] **[app/services]** *(pos-backend)* — Add `ProductService(BaseService[Product, ProductRepository])` in `app/services/product_service.py`. Add custom method `get_by_sku()` only if base methods don't suffice. **Verify:** `poetry run pytest tests/services/test_product_service.py` covers happy + error paths.
- [ ] **[app/controllers]** *(pos-backend)* — Add `app/controllers/product_controller.py` with CRUD routes. Register in `main.py` under `/products` prefix. **Verify:** `curl -X POST /products` returns 201 with expected payload; `curl /products` returns paginated list.
- [ ] **[alembic]** *(pos-backend)* — Generate migration `alembic revision --autogenerate -m "add_products_table"`. Review generated file; ensure `downgrade()` is correct. **Verify:** `poetry run alembic upgrade head && poetry run alembic downgrade -1` both succeed cleanly.
- [ ] **[tests]** *(pos-backend)* — Add integration tests in `tests/controllers/test_product_controller.py`. **Verify:** `poetry run pytest tests/controllers/test_product_controller.py -v` all green.
- [ ] **[pos-server]** *(reviewer)* — Review pass: SOLID, clean code, ResponseBuilder usage, exception handling. **Verify:** reviewer signs off in PR comment.
```

### Step 4 — Order with Phases

**Default layer phases (default):** Entity → Model → DataSource → Repository → UseCase → Cubit → Screen → Route → l10n → DI (`lib/di/injection.dart`). See `docs/prerequisites.md`.

Group tasks under **Phase** headings reflecting dependencies. Use the phase structure already present in the brainstorm doc when one exists; otherwise default to:

- **Phase 0 — Discovery & Setup** (verify assumptions, audit affected files, plan migration)
- **Phase 1 — Foundation** (model, migration, schema — no business logic)
- **Phase 2 — Repository & Service** (repository methods + service business logic)
- **Phase 3 — API Surface** (controllers, routes, request/response schemas)
- **Phase 4 — Hardening** (validation edge cases, error handling, rate limit, audit log)
- **Phase 5 — Tests & Quality Gate** (pytest coverage, pre-commit, mypy)

Within each phase, order tasks so that **a task's prerequisites appear above it**. If task B reads from a class added by task A, A must come first. The plan should be runnable top-to-bottom without backtracking.

### Step 5 — Add Cross-cutting Sections

Even small plans should include these explicit sections (skip only if genuinely irrelevant — say so):

- **Out of scope** — what is intentionally not in this plan, so the executor doesn't drift.
- **Dependencies on other plans / specs** — links to brainstorm docs, prior plans, or specs that must land first.
- **Risks & mitigations** — top 2–4 risks specific to this plan.
- **Definition of Done (DoD)** — the global verification: all tests pass, pre-commit passes, endpoints smoke-tested, migration reversible.

### Step 6 — Save to File (MANDATORY)

Always write the plan to `docs/plan/YYYY-MM-DD-{topic}.md` before replying — no exceptions. Use today's date and a kebab-case slug from the topic. If a plan with that slug already exists today, append `-v2`, `-v3`, etc.

The document structure must be:

```markdown
---
name: {plan title}
source: {path to brainstorm doc or spec, or "ad-hoc requirement"}
scope: {feature | api-only | migration-heavy | job-worker}
date: YYYY-MM-DD
---

# Plan: {title}

## Context
{1–3 paragraphs: what we are building and why, linking to source doc}

## Out of Scope
- ...

## Dependencies
- ...

## Phase 0 — {name}
- [ ] **[layer]** *(agent)* — Task. **Verify:** ...
...

## Phase 1 — {name}
...

## Risks & Mitigations
- **Risk:** ... → **Mitigation:** ...

## Definition of Done
- [ ] All tasks above checked.
- [ ] `poetry run pytest` passes with no failures.
- [ ] `poetry run pre-commit run --all-files` passes.
- [ ] Migration tested: `alembic upgrade head` and `alembic downgrade -1` both succeed.
- [ ] Smoke test: key endpoints return expected responses.
```

### Step 7 — Reply with File Link

After saving, reply with:

1. The file path as a reference: `docs/plan/YYYY-MM-DD-{topic}.md`.
2. A short summary: total task count, phase count, which agents are involved, estimated duration if computable.
3. The full plan inline so the user can review without opening the file.
4. End with one clarifying question if there is a remaining unknown that would change the plan, or with a clear next-step suggestion (e.g., "Ready to start Phase 0?").

---

## Quality Bar

Before saving, re-read the plan and check:

- [ ] **No open questions remain** — every question from the source doc and brainstorm is resolved. If any is still open, do not save; surface it to the user.
- [ ] Every task has `[layer]`, `(agent)`, and `**Verify:**`.
- [ ] No task is so big it would take more than ~half a day to verify; split if it is.
- [ ] No task is so small it adds noise (e.g., "create file" alone). Combine into a meaningful unit.
- [ ] Tasks are ordered so prerequisites come first.
- [ ] The "Out of Scope" section is non-empty if the source doc covered topics not in this plan.
- [ ] Pre-commit / mypy / pytest checks are explicitly tasked, not assumed.

A good plan is one a new contributor could pick up cold, work top-to-bottom, and finish without asking design questions. If reading your plan raises a "wait, but…" question, fix the plan.

---

## Style Notes

- **English throughout** — use English for all prose, descriptions, and comments. Use English identifiers in code/CLI.
- **Imperative mood** for task descriptions ("Add X", "Create Y"), not "We will add X".
- **Surgical scope per task** — one file or one feature slice per checkbox. If verifying needs more than one bullet, split.
- **Don't speculate timelines** unless the user asked. Estimating "1d / 0.5d" for each task is OK if cumulative effort matters; otherwise omit.
- **Reference real paths** — `app/services/product_service.py`, not "the product service file". Plans that name the exact file save the executor a search.
- **Always run with Poetry** — all commands must use `poetry run ...` (e.g., `poetry run pytest`, `poetry run alembic`).
