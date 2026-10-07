# Performance benchmark contract

Performance benchmarking is opt-in. Do not run it automatically after a code
change, during `flutter test`, `flutter run`, build, post-build, git hooks,
pre-commit, or default CI. Run it only when the user requests performance
measurement/regression work or explicitly asks to execute the benchmark:

```bash
derry perf run              # or: dart run tool/perf.dart
```

The runner discovers enabled scenarios under
`integration_test/performance/scenarios/` and uses profile mode on the native
flavor set in `tool/performance/config.json` (`dev` by default), one warmup and
five measured runs per scenario. On Android it builds the profile APK once per
scenario and reuses it for every run. It compares the median run metrics, keeps
raw frame timings in each JSON report, and treats CPU/memory as unsupported
unless a real collector is implemented. Debug-mode data and single-run
conclusions are not valid performance claims.

Keep device, OS, flavor, Flutter version, power/thermal state, data size and
scenario consistent when comparing results. Review JSON as the machine-readable
source and Markdown/console output for the summary.

Gates, configurable in `tool/performance/config.json`:

| Gate | Default |
|---|---|
| Jank (frames over 16.67 ms) | ≤ 3% |
| Frame p95 / p99 | ≤ 20 ms / ≤ 32 ms |
| Scenario duration | ≤ 5000 ms |
| Regression versus baseline | ≤ 5% |
| Absolute regression when the baseline is 0 | per metric, e.g. jank +0.5 point |
| Frames per measured run (median) | ≥ 20, so p95/p99 are meaningful |

Adjust thresholds only with a documented rationale for the target
product/device.

Baseline changes are never automatic. After reviewing a valid report, update it
only on explicit user request:

```bash
derry perf approve          # or: dart run tool/perf.dart --approve-baseline
```

An approval run measures again and still compares against the existing
baseline from the same environment. Baselines are written only when every
scenario passes both the hard limits and the regression gate, so a regression
cannot be approved by accident. If a regression is intentional, delete that
scenario's baseline file in the same reviewed change and state why. Never use a
new baseline to hide a regression.

If the user asks only for a feature change, do not benchmark. For a request to
check/measure/benchmark performance, run `derry perf run`; for before/after
comparison, inspect the approved baseline and generated JSON report.

Reports are written to `performance/reports/` and history is appended to
`performance/history.jsonl`; both are gitignored by default. Commit
`performance/baselines/` when the team wants shared regression tracking.
New routes without scenarios are listed during discovery. A new screen needs a
stable scenario and test data before its performance can be compared; the
runner does not invent interactions. The disabled template example and
unsupported metrics are documented in `tool/performance/README.md`.
