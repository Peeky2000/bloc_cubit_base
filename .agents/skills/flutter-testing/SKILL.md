---
name: flutter-testing
description: >
  Design, write or review Flutter tests for a feature, regression or refactor.
  Use for "viết test", choosing unit/widget/integration tests, reproducing a bug, testing
  Cubit/BLoC, DI, network races, widget semantics, routing or native boundaries.
  Select the smallest test that proves the behavior.
---

# Flutter testing

## Choose the boundary

| Question | Preferred test |
|---|---|
| Pure mapping, validation, use case or state transitions | Dart unit test |
| Widget interaction, layout, semantics, l10n or theme | Widget test |
| Native plugin, platform channel, deep link or cross-screen flow | Integration test or platform test |
| Stable visual contract | Golden, paired with behavior/semantics test |

Test public behavior rather than restating internal implementation. Include
failure and cancellation paths where the bug can occur. Use deterministic fake
time, injected dependencies and controlled completers for concurrency; avoid
real network, arbitrary sleeps and order-dependent global state.

## Base-specific patterns

- Cubit/BLoC: initial → loading → success/failure; repeated one-shot effects,
  stale response after close, and event transformer semantics where relevant.
- DI: reset/dispose graph and resolve the same composition root, without
  editing generated config.
- REST/session: concurrent 401 single-flight, terminal versus transient refresh
  failure, token revision, cross-origin protection and safe replay.
- UI toolkit: light/dark, disabled/loading, 48×48 touch targets, semantics,
  keyboard inset and compatibility behavior before migration.

Run focused tests first, then `derry quality` for changes in this repo. Report
the command and pass/fail count. A passing test with no assertion on user
observable behavior is not evidence of correctness.
