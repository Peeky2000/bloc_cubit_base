---
name: plan-writer
description: >
  Convert an agreed Flutter requirement, brainstorm, or spec into a detailed,
  ordered, agent-tagged Markdown checklist with exact paths and verification.
  Trigger: write/create/make a plan, implementation plan, break down, tasks,
  viết plan, tạo plan, lên plan, kế hoạch triển khai, phân chia task.
---

# Flutter Plan Writer

## Goal

Produce a plan that a Flutter engineer can execute top-to-bottom without hidden
architecture decisions. Always save it to
`docs/plan/YYYY-MM-DD-{topic}.md` before replying.

## Pre-flight

1. Read the requirement and any linked brainstorm/spec/checklists completely.
2. Read `docs/prerequisites.md`, `project-convention`, and relevant ADRs.
3. Search app-memory and inspect actual sibling files/paths.
4. Resolve only questions that materially change scope, behavior, storage,
   security, or UX. Do not block on discoverable details.

## Task format

```markdown
- [ ] **[layer]** *(coder)* — Implement one verifiable change at
  `exact/path.dart`. **Verify:** objective command or behavior.
```

Allowed tags include `discovery`, `entity`, `model`, `datasource`, `repository`,
`usecase`, `di`, `bloc-cubit`, `route`, `widget`, `page`, `l10n`, `security`,
`test`, `docs`, `tooling`, `migration`, and `review`. Ownership is `coder` or
`reviewer`; use another agent tag only when that agent exists in the repository.

## Ordering

Use only applicable phases and keep dependencies above consumers:

1. Discovery, baseline, and architecture decisions.
2. Domain entity/contracts.
3. Data models, data sources, repository implementation.
4. UseCases and generated DI.
5. Cubit/BLoC state and tests.
6. UI, route, accessibility, l10n, and shared toolkit changes.
7. Security, integration, migration, and backward compatibility.
8. Quality gates, docs/app-memory, reviewer pass.

## Required document sections

- Front matter: title, source, scope, date.
- Context and goal.
- Decisions/constraints already agreed.
- Out of scope.
- Dependencies and reusable artifacts.
- Phased checklist with exact paths and Verify conditions.
- Risks and mitigations.
- Definition of Done.

Definition of Done must include `derry quality`, generated files current,
architecture boundary script passing, relevant package/submodule gates passing,
documentation updated, and no regression hidden as baseline debt.

## Quality bar

- No backend/Python/Poetry/Alembic templates or paths.
- Do not force unused Clean Architecture layers into UI-only work.
- Split tasks that cannot be independently reviewed in half a day.
- Call out destructive migrations, secret handling, submodule pointer changes,
  and native configuration explicitly.
- Never mark a phase complete unless its objective Verify condition passed.
