# Generate a Frontend Spec

## 1. Validate and preserve inputs

Require at least one requirement source: description, screenshot, design link,
or documentation. Create `docs/specs/{id}-{slug}/` with the provided scripts and
store local design references there. Do not invent inaccessible design details.

## 2. Load project context

Read `docs/prerequisites.md`, architecture docs/ADRs, `project-convention`, and
the relevant Flutter skills. Search app-memory and inspect `sli_common` before
classifying anything as new.

## 3. Analyze behavior before files

Capture:

- user goal, actors, entry/exit flows, and acceptance criteria;
- screen states: initial/loading/empty/error/success and one-shot effects;
- form rules, normalized values, error codes, retry/offline/session behavior;
- responsive/accessibility/theme requirements;
- open questions that materially change behavior, security, or scope.

If a material question cannot be discovered from context, record it in §4 and
pause before finalizing implementation contracts.

## 4. Fill `fe.md` in dependency order

Use `templates/spec-fe-template.md` and the section rules:

1. Pure domain entities/values in `lib/domain/entities/`.
2. json_serializable models in `lib/data/model/`.
3. Repository interface/implementation and UseCase.
4. ApiHandler-based remote or local DataSource.
5. Typed validation and utilities at their correct ownership boundary.
6. UI reuse: `sli_common` → app reusable → feature-specific.
7. Cubit by default or documented BLoC, immutable Equatable state, constructor
   injection, and UI effects handled by listeners.
8. Thin screen under `lib/presentation/{feature}/view/`.
9. `AppPage`/`SLIPage` route and documented arguments.
10. ARB keys and test scenarios.

Do not force unused layers into a UI-only feature. Do not specify Freezed,
Retrofit, go_router, Easy Localization, `lib/features/`, or `lib/shared/`.

## 5. Verify the spec

- Every name and location is checked against the repository or marked “create”.
- Presentation exposes domain types, never data models.
- Every action maps to a Cubit method/BLoC event and observable state/effect.
- Every endpoint maps to a DataSource, repository method, and UseCase consumer.
- Loading/empty/error/retry/offline/session and accessibility are explicit.
- No placeholders or unresolved questions remain before checklist generation.

Report the absolute `fe.md` path and a concise list of decisions/reuse findings.
