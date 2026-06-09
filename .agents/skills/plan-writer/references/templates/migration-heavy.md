# Template — Migration-heavy Plan

Use when a change requires meaningful **data migration** or **domain restructure**: splitting an aggregate, renaming a table, dropping a column with backfill, changing a FK topology, or a large domain refactor. These plans live or die by safety, not feature velocity.

Key principle: **never combine a schema change and a feature change in the same step.** Migrate first, prove stability, then build on top.

---

## Sections to consider

### Phase 0 — Discovery & Inventory
- Find every callsite that references the affected table/model (grep + read code).
- Capture the current schema: run `poetry run alembic current` and describe the current shape.
- Document existing data: row counts, sample rows, active constraints.
- List all consumers: services, repositories, controllers, jobs, seed scripts, tests.
- Produce an inventory doc before writing any code.

### Phase 1 — Forward-compatible Schema Change (additive)
- Add new tables/columns/indexes — **do not drop anything yet**.
- Backfill from old to new (idempotent script, restartable).
- Verify: row counts match; sample rows look correct; constraints satisfied.

### Phase 2 — Code Migration (read from new)
- Update repositories to read from the new schema shape.
- Update services to use the new domain.
- Keep old read path as fallback if a gradual cutover is needed.
- All tests must pass against the new shape.

### Phase 3 — Cutover (writes go to new)
- Switch writes from old to new schema.
- Dual-write briefly if downtime risk is high; otherwise atomic switch.
- Run the smoke test suite end-to-end.

### Phase 4 — Cleanup (drop old)
- Remove old columns/tables via a new migration.
- Remove fallback read code.
- Final migration asserting data integrity.

### Phase 5 — Rollback Plan (mandatory)
- Documented rollback steps for each phase.
- Every Alembic migration must have a tested `downgrade()` — verified on a clone DB.
- Snapshot-restore checklist for catastrophic failure.

---

## Common task patterns

```markdown
## Phase 0 — Discovery

- [ ] **[docs]** *(pos-backend)* — Produce `docs/migration/{topic}-inventory.md` listing every file that references `{old_table}` or `{OldModel}` with line numbers. **Verify:** doc is present; `rg "{old_table}" app/` matches every entry listed.
- [ ] **[docs]** *(pos-backend)* — Capture current schema shape + sample rows to `docs/migration/{topic}-current-state.md`. **Verify:** doc describes exact current columns, constraints, and FK relations.

## Phase 1 — Additive Schema

- [ ] **[alembic]** *(pos-backend)* — Create migration adding new tables/columns: `poetry run alembic revision -m "add_{new}_columns_additive"`. Ensure `downgrade()` drops only what `upgrade()` adds. **Verify:** `poetry run alembic upgrade head` succeeds; old code still runs; no data lost.
- [ ] **[alembic]** *(pos-backend)* — Write backfill script `scripts/migrate_{topic}.py` to populate new columns from old data. Must be idempotent, batched, and log progress. **Verify:** dry-run on test DB; row counts match expected; script can be re-run safely.
- [ ] **[alembic]** *(pos-backend)* — Add `NOT NULL` / `UNIQUE` constraints in a separate migration after backfill. **Verify:** constraint migration succeeds on the backfilled DB with no violations.

## Phase 2 — Code Reads New Shape

- [ ] **[app/repositories]** *(pos-backend)* — Refactor `{Entity}Repository` to read from the new schema shape. Keep the old read path callable as fallback if mid-migration. **Verify:** `poetry run pytest tests/repositories/` passes.
- [ ] **[app/services]** *(pos-backend)* — Update `{Entity}Service` to use the new domain shape. **Verify:** all existing service tests pass with no regression.

## Phase 3 — Cutover

- [ ] **[app/services]** *(pos-backend)* — Switch writes from old to new schema. **Verify:** end-to-end smoke test (create / read / update / delete via API) works; old data still accessible.
- [ ] **[docs]** *(pos-backend)* — Produce a reconciliation report: rows where old and new disagree. **Verify:** report shows zero discrepancies on the test DB.

## Phase 4 — Cleanup

- [ ] **[alembic]** *(pos-backend)* — Create migration dropping old tables/columns: `poetry run alembic revision -m "drop_{old}_columns"`. **Verify:** `poetry run alembic upgrade head` succeeds; `rg "{old_column}" app/` returns no code references.
- [ ] **[app/repositories]** *(pos-backend)* — Remove fallback read paths from repository and service. **Verify:** all tests still pass.

## Phase 5 — Rollback Drill

- [ ] **[docs]** *(pos-backend)* — Document exact rollback commands per phase in `docs/migration/{topic}-rollback.md`. **Verify:** another engineer can follow it cold without asking questions.
- [ ] **[infra]** *(pos-backend)* — Run rollback drill on clone DB: `poetry run alembic downgrade -N` for each phase. **Verify:** schema and data return to a known-good state.

## Quality Gate

- [ ] **[pos-server]** *(pos-backend)* — Run `poetry run pytest` + `poetry run pre-commit run --all-files`. **Verify:** both pass with no failures.
- [ ] **[pos-server]** *(reviewer)* — Review pass: migration safety, rollback correctness, no data loss path. **Verify:** reviewer signs off.
```

---

## Things people forget

- **Backfill is not a one-liner.** It needs progress logging, batching, restart safety, and a way to resume after failure.
- **Test data ≠ production data.** Always dry-run on a clone DB with real (or representative) data.
- **Constraints last.** Add `NOT NULL` / `UNIQUE` only after backfill; otherwise the migration fails on existing nulls/duplicates.
- **FK direction.** Adding a FK pointing the wrong way is hard to reverse — verify direction before committing.
- **Index after data.** Creating a large index during migration locks the table — use `CONCURRENTLY` or schedule for off-peak. With Alembic: `op.create_index(..., postgresql_concurrently=True)`.
- **Old code paths still run** during gradual cutover — they must keep working correctly until the cleanup phase.
- **Seed scripts** must be updated alongside production migrations, or a fresh dev environment will diverge.
- **Alembic `downgrade()` must actually work.** Never leave it as `pass` — test it on a real DB.
- **`alembic_version` table**: to reset migration state on dev, use `poetry run alembic stamp <revision>`.
