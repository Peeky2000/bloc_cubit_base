# Performance scenarios for an app forked from this base

The base owns the profile-mode runner, metric collection, report format and
regression checks. Each product owns its measured flows and stable test data.

1. Create an integration test under `integration_test/performance/`.
2. Use `measureScenario(tester, binding, () async { ... })` around real app UI
   interactions. Start the app through `bootstrap` so DI, theme and
   localization match production, and keep the steps and data stable between
   releases.
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

`derry perf run` (or `dart run tool/perf.dart` from the project root) discovers
all enabled descriptors and runs each one separately with
`flutter drive --profile --flavor <flavor>`. The flavor comes from
`tool/performance/config.json` because this project defines `dev`, `staging`
and `prod` Android product flavors and iOS schemes; a drive without a flavor is
rejected. On Android the runner builds the profile APK once per scenario and
passes it to every drive with `--use-application-binary`. On iOS a reusable
binary must be a signed IPA, so each drive still builds.

Reports are written under `performance/reports/<scenario>/`; approved baselines
are stored under `performance/baselines/<scenario>/<device>.json`. The runner
prints routes in `AppPage.pages` that are not covered by enabled scenarios.
Route coverage is a source-level check for the current `SLIPage(name: ...)`
syntax; it does not infer taps, login state, route arguments or test data.

The included `template_home` descriptor is disabled because this template's
Home screen is empty and the example pumps the screen directly without
`bootstrap`, DI, theme or localization. It also renders too few frames to pass
`min_frame_count`. Use it only as a code sample. Add product scenarios for
meaningful performance regression tracking. With no enabled scenario, the
runner exits with a configuration error and generates no fake measurement.

Run only when requested:

```bash
derry perf run
```

Select a device using `FLUTTER_PERF_DEVICE`; when exactly one Android/iOS
device is connected, the runner selects it automatically. A successful initial
run has no baseline comparison. After reviewing its report, explicitly approve
a baseline with `derry perf approve`. This repeats the measurement, compares it
with any existing baseline from the same device, flavor and Flutter version,
and updates baseline files only when every scenario passes the hard limits and
the regression gate. JSON reports and history are ignored by Git; commit
approved baseline files if the team wants shared regression tracking.

## Metric notes

- Frame p50/p95/p99, build p95, raster p95 and jank use Flutter engine
  `FrameTiming` samples in profile mode. Percentiles use the nearest-rank
  method. With few frames, p95/p99 collapse to the slowest frame, so a run
  below `min_frame_count` fails instead of reporting a misleading percentile.
- Relative regression is undefined when a baseline metric is 0, which is common
  for jank. `zero_baseline_regression_delta` then sets the allowed absolute
  increase per gated metric.
- Scenario duration starts before the first test pump and ends after the
  declared interaction; it is not process cold startup.
- Startup, CPU and memory are unsupported in the default collector.
