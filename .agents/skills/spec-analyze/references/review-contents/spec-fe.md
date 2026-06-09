# Review Content — Spec-FE (fe.md)

Apply this reference during [review-spec-fe.md Step 5.1](../workflows/review-spec-fe.md) when reviewing `fe.md`.

Template to reference: `.agents/skills/spec-analyze/templates/spec-fe-template.md`

---

## 1. Template Alignment

For each **required section** in spec-fe-template, verify it exists in `fe.md` and is meaningfully filled (no empty tables, no `TBD` where concrete content is expected):

| Section | Requirement |
|---------|-------------|
| §1 Overview | Present and describes the feature in ≥2 sentences; Spec type is set |
| §1.1 Input | At least one design input filled (Figma / Screenshot / Stitch / Description) |
| §2 Analysis | §2.1 Layout blocks filled; §2.2/§2.3 filled or omitted with justification |
| §3 In scope / Out of scope | Both sub-lists filled; not empty |
| §4 Questions for requester | Present (can be "None" if no open questions) |
| §5 Functional requirements | §5.1 user stories, §5.2 flows, §5.3 validation/edge cases filled |
| §6.1 Entity | Filled or explicitly omitted with reason (e.g. static screen) |
| §6.2 Model | Filled if §6.4 has API calls; one model per API response |
| §6.3 Repository | Filled if §6.4 has API calls; interface + impl locations present |
| §6.4 API | Filled if screen calls any endpoints; state management line present |
| §6.5 Validation | Filled if screen has a form; omitted with note otherwise |
| §6.6 Utility | Filled or explicitly omitted |
| §6.7 Widget | Filled; every major UI element from §2 represented |
| §6.8 BLoC/Cubit | Filled; Type (Cubit/BLoC) declared, states listed |
| §6.9 Page | Filled; all 4 screen states present; user actions listed |
| §6.10 Route | Filled; pattern, parent route/shell, path, route key present |
| §7 UI/UX guidelines | Present (style, accessibility, loading/error UI) |
| §8 Open questions / constraints | Present (can be empty after resolution) |
| §9 Acceptance criteria | ≥3 concrete, testable criteria |
| §10 Attachments | Present (design links, references) |

**Issue type:** `Template mismatch` or `Missing section`

---

## 2. Requirements Clarity

**Goal:** A reader who has **not** seen the original Figma, Stitch screen, or design brief must be able to fully understand the feature requirements from `fe.md` alone.

| Criterion | Check |
|-----------|-------|
| §1 Overview explains the **problem or goal** of the feature — not just "add a screen" | |
| §1 includes **who** uses this feature (user role or context) | |
| §3 Scope makes clear **what is included and excluded** — no ambiguity | |
| §5 Functional requirements are **self-contained**: each user story / flow is understandable without the original design | |
| §6.9 Screen states cover all user-facing scenarios (loading, empty, error, success) | |
| §9 Acceptance criteria are **verifiable without seeing the design** — use concrete values, not "looks good" or "works correctly" | |
| No section uses "see Figma" / "see design" as the sole explanation — design details are captured in §2 or §6.x | |
| Domain terms or abbreviations are either well-known or defined within the spec | |

**Issue type:** `Requirements unclear`

---

## 3. Internal Consistency

Cross-reference between sections to ensure they do not contradict each other:

| Check | Sections |
|-------|----------|
| Every API response in §6.4 references a Model name that exists in §6.2 | §6.4 ↔ §6.2 |
| Every Model in §6.2 maps to an Entity that exists in §6.1 | §6.2 ↔ §6.1 |
| Every repository method in §6.3 corresponds to an API endpoint in §6.4 | §6.3 ↔ §6.4 |
| Every BLoC/Cubit method or event in §6.8 is triggered by a user action in §6.9 | §6.8 ↔ §6.9 |
| BLoC/Cubit `success` state data fields reference Entities from §6.1 | §6.8 ↔ §6.1 |
| Widgets listed in §6.7 are referenced in §2 Analysis ("Component(s)" column) where applicable | §6.7 ↔ §2 |
| Validators in §6.5 correspond to the validation rules in §5.3 | §6.5 ↔ §5.3 |
| Utility functions in §6.6 are referenced in §2.5 Logic analysis | §6.6 ↔ §2.5 |
| Route in §6.10 is consistent with the navigation flow in §5.2 Main business flows | §6.10 ↔ §5.2 |
| Page structure in §6.9 main sections matches layout blocks in §2.1 | §6.9 ↔ §2.1 |

**Issue type:** `Inconsistency`

---

## 4. Quality and Placeholders

| Check |
|-------|
| No leftover template instructions that should have been deleted |
| No `{WidgetName}`, `{EntityName}`, `{FieldName}`, or `{}` placeholders left unfilled |
| Dart types used everywhere — no TypeScript types (`string`, `number`, `boolean`, `interface`) |
| All `Location` paths in §6.1–§6.10 use `lib/` prefix and follow Flutter/Dart conventions |
| If codebase exists: verify key paths with grep/glob and flag `Wrong path` if stale |
| §9 Acceptance criteria are concrete and testable (not vague like "should work correctly") |

**Issue type:** `Placeholder left` or `Wrong path`

---

## Acceptance Criteria (for review file)

Fill the **Acceptance** table in the review file with:

| Criterion | Met |
|-----------|-----|
| All required sections present (§1–§10) | ✓ / ✗ |
| Requirements understandable without external design context | ✓ / ✗ |
| §6.4 API responses reference Models from §6.2 | ✓ / ✗ |
| §6.2 Models map to Entities from §6.1 | ✓ / ✗ |
| §6.5 validators align with §5.3 validation rules | ✓ / ✗ |
| §6.8 BLoC/Cubit methods/events cover all user actions in §6.9 | ✓ / ✗ |
| §9 acceptance criteria are concrete and testable | ✓ / ✗ |
| No leftover placeholders or wrong-tech-stack references | ✓ / ✗ |
