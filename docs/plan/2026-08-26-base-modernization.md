---
name: Flutter base modernization
source: approved architecture decisions in Codex task
scope: migration-heavy
date: 2026-08-26
---

# Plan: Flutter Base Modernization

## Context

Modernize `bloc_cubit_base` into a reusable personal Flutter application base and make
`sli_common` its real, independently versioned UI toolkit. The implementation borrows
proven ideas from `base_flutter_project_v2` and `/Users/long/Documents/Work/commons`
without copying their product-specific complexity or known technical debt.

The target keeps Clean Architecture, `SLIRouting`, REST/Dio, Cubit as the default,
classic BLoC as a supported option, and `BaseAppState + Equatable + copyWith`. It adds
typed environments, deterministic bootstrap, `get_it + injectable`, automation,
network inspection with mandatory redaction, a real `sli_common` Git submodule, and a
Shadcn-backed design layer. Documentation and AI instructions are versioned with every
architecture change.

## Out of Scope

- GraphQL runtime and generated operations; keep only an extension contract in docs.
- Firebase Messaging and deep-link implementation.
- HydratedBloc and Freezed state migration.
- Full VIPER process adoption and advanced AI automation.
- Product-specific backend endpoints or business features.

## Dependencies

- Flutter/FVM toolchain available locally.
- Git access to `https://github.com/Peeky2000/sli_common.git`.
- `sli_common` changes must be committed before `bloc_cubit_base` can pin the new
  submodule revision.

## Phase 0 — Baseline and architecture source of truth

- [x] **[docs]** *(coder)* — Record architecture decisions, dependency rules, scope,
  migration strategy, and current baseline. **Verify:** every accepted decision has an
  ADR and links from the architecture index.
- [x] **[tests]** *(coder)* — Run and record `flutter pub get`, `flutter analyze`, and
  `flutter test` before migration. **Verify:** existing failures are separated from new
  regressions.

## Phase 1 — Reproducible toolchain and automation

- [x] **[infra]** *(coder)* — Pin Flutter with `.fvmrc`, add `derry.yaml`, and implement
  safe scripts for bootstrap, generation, formatting, analysis, and tests. **Verify:**
  every script fails fast and runs from any working directory.
- [x] **[infra]** *(coder)* — Add CI for submodules, dependencies, code generation,
  formatting, static analysis, and tests. **Verify:** workflow contains no secret or
  product credential and uses the pinned Flutter version.

## Phase 2 — Typed environment and deterministic bootstrap

- [x] **[lib/core/config]** *(coder)* — Replace the mutable enum-driven configuration
  with immutable typed `AppEnvironment` and validated `AppEnvironmentConfig` values.
  **Verify:** invalid HTTP(S) base URLs fail before `runApp`.
- [x] **[lib/bootstrap.dart]** *(coder)* — Make bootstrap order explicit, guarded, and
  testable; keep entry points limited to environment selection. **Verify:** all four
  entry points delegate to the same bootstrap pipeline.

## Phase 3 — Injectable dependency injection

- [x] **[lib/di]** *(coder)* — Add Injectable configuration and modules for async/external
  dependencies. **Verify:** `build_runner` produces a resolving `injection.config.dart`.
- [x] **[lib]** *(coder)* — Annotate application dependencies and convert Cubits/BLoCs,
  use cases, repositories, and data sources to constructor injection. **Verify:** no
  business-layer constructor reads `Injector.getIt`.
- [ ] **[tests]** *(coder)* — Add resettable DI/bootstrap tests. **Verify:** repeated test
  setup does not leak registrations.

## Phase 4 — Cubit/BLoC and state conventions

- [ ] **[lib/core/base_component]** *(coder)* — Harden immutable `BaseAppState`, typed
  failure data, and Cubit/BLoC conventions without introducing Freezed or HydratedBloc.
  **Verify:** representative Cubit and BLoC tests cover initial/loading/success/failure.
- [ ] **[lib/presentation]** *(coder)* — Remove `BuildContext` and service-locator access
  from feature state managers; expose UI effects as state or presentation events.
  **Verify:** presentation logic can be unit-tested without a widget tree.

## Phase 5 — Clean Architecture boundary correction

- [x] **[lib/domain]** *(coder)* — Remove all imports from `data` and Flutter/UI layers.
  **Verify:** automated boundary check reports zero domain violations.
- [x] **[lib/presentation]** *(coder)* — Depend on domain entities/use cases rather than
  data models/data sources. **Verify:** automated boundary check reports zero direct
  presentation-to-data imports.

## Phase 6 — REST, session security, and network inspection

- [ ] **[lib/data]** *(coder)* — Refactor Dio/session interceptors to avoid navigation or
  dialogs, serialize token refresh, and retry requests safely. **Verify:** tests cover
  concurrent 401, refresh failure, and offline behavior.
- [x] **[lib/core/network]** *(coder)* — Add non-production Alice inspection with default
  redaction for authorization, cookies, tokens, passwords, and common PII. **Verify:**
  production config cannot enable inspector and redaction tests pass.
- [x] **[lib/data/local]** *(coder)* — Introduce a secure token storage abstraction and
  migration path from preferences. **Verify:** access/refresh tokens are not newly
  persisted in plain preferences.

## Phase 7 — `sli_common` and Shadcn design toolkit

- [x] **[sli_common]** *(coder)* — Establish a stable package public API, source layout,
  semantic design tokens, light/dark theme extensions, license, changelog, and docs.
  **Verify:** consumers import public barrels only and package analysis passes.
- [ ] **[sli_common]** *(coder)* — Add Shadcn as an implementation detail behind stable
  `Sli*` component wrappers, including accessibility and variant contracts. **Verify:**
  example, widget tests, and golden tests cover core components and both themes.
- [x] **[lib/modules]** *(coder)* — Replace the empty embedded tree with the real Git
  submodule and add a path dependency from the app. **Verify:** a fresh recursive clone
  resolves `sli_common` and builds without copied widget imports.
- [ ] **[lib/core/widget]** *(coder)* — Migrate duplicated widgets through compatibility
  adapters/deprecations. **Verify:** no behavior-breaking bulk migration and drift is
  tracked in a compatibility matrix.

## Phase 8 — Reusable template cleanup

- [ ] **[app]** *(coder)* — Remove or parameterize mOrder/Giaohang247 branding, signing
  artifacts, credentials, example endpoints, and generated residue. **Verify:** secret
  scan is clean and a rename smoke test succeeds.
- [ ] **[scripts]** *(coder)* — Provide a safe create/rename workflow with dry-run and
  validation. **Verify:** a temporary generated app passes `flutter pub get` and analyze.

## Phase 9 — Documentation and AI instruction alignment

- [x] **[docs]** *(coder)* — Update README, prerequisites, architecture, DI, state,
  networking, UI toolkit, environment, and contributor guides. **Verify:** all commands
  and paths exist and no doc teaches a retired pattern.
- [x] **[.agents]** *(coder)* — Rewrite agents, skills, checklists, and memory metadata to
  match Injectable, constructor injection, Cubit/BLoC choice, and `sli_common` placement.
  **Verify:** repository-wide search finds no contradictory manual-DI requirement.

## Risks & Mitigations

- **Risk:** one large migration hides regressions. **Mitigation:** keep phases independently
  analyzable/testable and maintain compatibility adapters during UI migration.
- **Risk:** generated DI becomes opaque. **Mitigation:** keep external providers in a small
  documented module and add graph-resolution tests.
- **Risk:** Shadcn API changes leak into applications. **Mitigation:** expose stable `Sli*`
  wrappers and prohibit direct app imports except documented escape hatches.
- **Risk:** submodule revision cannot reference uncommitted `sli_common` work.
  **Mitigation:** complete and verify package changes first, then commit/pin explicitly.
- **Risk:** existing credentials or product files survive template cleanup. **Mitigation:**
  add secret scanning and a release checklist; never print credential contents.

## Definition of Done

- [ ] All tasks above are checked or explicitly moved to a follow-up plan with rationale.
- [x] `./scripts/format.sh --check` passes.
- [x] `flutter analyze` passes without findings.
- [x] `flutter test` passes for the application and `sli_common`.
- [x] `derry gen` is reproducible.
- [x] A fresh recursive clone bootstraps through the documented command.
- [x] Documentation, ADRs, AI agents, skills, and implementation teach the same rules.
