# Template — Job / Worker Plan

Use when adding a background job, scheduled task, or async worker. Typical examples: scheduled report generation, async email/notification sender, periodic data sync, event-driven worker.

---

## Sections to consider

### Phase 0 — Discovery
- Identify the trigger: scheduled (cron), event-driven (queue/message broker), or manual API trigger.
- Identify data access: which tables does the job read/write?
- Define idempotency strategy: can the job be safely re-run without side effects?
- Define failure strategy: retry? dead-letter queue? alert?
- Check the infrastructure: which scheduler/queue does the project use (APScheduler, Celery, asyncio, etc.)?

### Phase 1 — Schema / Model (if needed)
- Add a model/table to track job execution state (if needed).
- Create Alembic migration for the new table.

### Phase 2 — Core Logic
- Implement the job function/class in `app/jobs/` or `app/workers/`.
- Delegate business logic to the service layer — do not access the DB directly from the job.
- Ensure idempotency: running the job multiple times must not create duplicates or repeated side effects.
- Log start, end, and errors using `get_trace_logger()`.
- Handle errors explicitly: catch exceptions, log them, and retry or report failure — never swallow silently.

### Phase 3 — Registration / Wiring
- Register the job with the scheduler or subscribe to the queue consumer.
- Configure schedule/trigger in `app/config/` if needed.
- Verify the job is triggered correctly.

### Phase 4 — Tests
- Unit tests for job logic with mocked service/repository.
- Integration test: trigger the job manually and verify output.

### Phase 5 — Quality Gate
- `poetry run pre-commit run --all-files` passes.
- Verify the job runs correctly in the Docker environment.

---

## Common task patterns

```markdown
## Phase 0 — Discovery

- [ ] **[docs]** *(pos-backend)* — Document `docs/design/{job_name}-design.md`: trigger type, data flow, idempotency strategy, failure handling, infrastructure requirements. **Verify:** doc is present; all open questions are resolved before Phase 1 starts.

## Phase 1 — Schema (if needed)

- [ ] **[app/models]** *(pos-backend)* — Add `{JobName}Log` model in `app/models/{job_name}_log.py` to track job execution state. **Verify:** `poetry run alembic upgrade head` succeeds; table visible in DB.
- [ ] **[alembic]** *(pos-backend)* — Generate migration for the job log table. **Verify:** `upgrade` and `downgrade` both succeed cleanly.

## Phase 2 — Core Logic

- [ ] **[app/jobs]** *(pos-backend)* — Add `{job_name}.py` in `app/jobs/`. Implement the job function by calling into the service layer. Ensure idempotency: running twice produces the same result. Log start/end/error with `get_trace_logger()`. Catch all exceptions and log them — do not swallow silently. **Verify:** calling the job function twice yields the same outcome; errors are caught and logged.
- [ ] **[app/services]** *(pos-backend)* — Add any new service methods required by the job. Keep the job thin — delegate to the service. **Verify:** `poetry run pytest tests/services/` passes.

## Phase 3 — Registration

- [ ] **[app/jobs]** *(pos-backend)* — Register the job with the scheduler or wire to the queue consumer in `app/jobs/__init__.py` or a startup hook in `main.py`. Set the correct schedule/trigger. **Verify:** job appears in the scheduler list; manual trigger fires correctly.

## Phase 4 — Tests

- [ ] **[tests]** *(pos-backend)* — Add unit tests in `tests/jobs/test_{job_name}.py` with the service layer mocked. Cover: normal run, idempotent re-run, error case. **Verify:** `poetry run pytest tests/jobs/test_{job_name}.py -v` all green.

## Phase 5 — Quality Gate

- [ ] **[pos-server]** *(pos-backend)* — Run `poetry run pre-commit run --all-files`. **Verify:** exits with code 0.
- [ ] **[pos-server]** *(reviewer)* — Review pass: idempotency, error handling, logging completeness, no direct DB access bypassing the service layer. **Verify:** reviewer signs off.
```

---

## Things people forget

- **Idempotency**: the job must be safe to re-run after a crash — check "already processed" before starting work.
- **Timeout**: a job without a timeout will hang forever — set an explicit timeout.
- **Concurrency**: if the job can run in parallel, add a lock or semaphore to prevent duplicate processing.
- **Logging context**: background jobs have no request context — log enough info (job_id, run_at, duration) to debug post-mortem.
- **Graceful shutdown**: a job running during server restart must not be killed mid-way — handle `SIGTERM` properly.
- **Error visibility**: a silently failing job is worse than a loudly failing job — always log and alert on failure.
- **Service layer**: jobs must not access the DB directly — call through the service to reuse validation and business rules.
