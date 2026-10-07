# Performance scenarios for an app forked from this base

The base owns the profile-mode runner, metric collection, report format and
regression checks. Each product owns its measured flows and stable test data.

1. Create an integration test under `integration_test/performance/`.
2. Use `measureScenario(tester, binding, () async { ... })` around real app UI
   interactions. Keep the steps and data stable between releases.
3. Add one JSON descriptor under `integration_test/performance/scenarios/`:

```json
{
  "id": "orders_list",
  "description": "Open orders, scroll, open one order, return",
  "routes": ["/orders"],
  "test": "integration_test/performance/orders_list_test.dart",
  "enabled": true
}
```

`dart run perf` discovers all enabled descriptors and runs each one separately.
Reports are written under `performance/reports/<scenario>/`; approved baselines
are stored under `performance/baselines/<scenario>/<device>.json`. The runner
prints routes in `AppPage.pages` that are not covered by enabled scenarios.
Route coverage is a source-level check for the current `SLIPage(name: ...)`
syntax; it does not infer taps, login state, route arguments or test data.

The included `template_home` descriptor is disabled because this template's
Home screen is empty. Enable it only if a first-render smoke benchmark is useful
for your fork. Add product scenarios for meaningful performance regression
tracking. With no enabled scenario, the runner exits with a configuration error
and generates no fake measurement.

Run only when requested:

```bash
dart run perf
```

Select a device using `FLUTTER_PERF_DEVICE`; when exactly one supported device
is connected, the runner selects it automatically. A successful initial run has
no baseline comparison. After reviewing its report, explicitly approve a
baseline with `dart run perf --approve-baseline`. This repeats the measurement;
it updates baseline files only for scenarios meeting hard thresholds. Keep the
same device and Flutter version for later comparisons. JSON reports and history
are ignored by Git; commit approved baseline files if the team wants shared
regression tracking.

Startup, CPU and memory are unsupported in the default collector. Scenario
duration starts before the first test pump and ends after the declared
interaction; it is not process cold startup. Frame p50/p95/p99, build p95,
raster p95 and jank use Flutter engine `FrameTiming` samples in profile mode.
