# Rules — Checklist: entity

## When to create

- **Always create** for every entity in `fe.md` section **6.1 Entity** (including Reuse).

## Fill rules

- **Entity name:** kebab-case file slug from entity name (e.g. `user`, `order-item`).
- **Location:** `lib/domain/entities/{domain}/{name}.dart` — verify with grep; see [canonical-paths.md](../../../../project-convention/references/canonical-paths.md).
- **No JSON** on entities.

## Review rules

- [ ] Path under `lib/domain/entities/`.
- [ ] No placeholders remain.
