# Performance benchmark contract

Performance benchmarking is opt-in. Do not run it automatically after a code
change, during `flutter test`, `flutter run`, build, post-build, git hooks,
pre-commit, or default CI. Run it only when the user requests performance
measurement/regression work or explicitly asks to execute the benchmark:

```bash
dart run perf
```

The runner discovers enabled scenarios under
`integration_test/performance/scenarios/` and uses profile mode, one warmup
and five measured runs per scenario by default. It compares the median run
metrics, keeps raw frame timings in each JSON report,
and treats CPU/memory as unsupported unless a real collector is implemented.
Debug-mode data and single-run conclusions are not valid performance claims.

Keep device, OS, Flutter version, power/thermal state, data size and scenario
consistent when comparing results. Review JSON as the machine-readable source
and Markdown/console output for the summary. A regression above 5% requires
investigation. Hard limits are jank ≤ 3%, frame p95 ≤ 20 ms, frame p99 ≤ 32 ms,
and scenario ≤ 5000 ms; thresholds are configurable in
`tool/performance/config.json` and should be adjusted with documented rationale
if the target product/device requires it.

Baseline changes are never automatic. After reviewing a valid report, update it
only on explicit user request:

```bash
dart run perf --approve-baseline
```

If the user asks only for a feature change, do not benchmark. For a request to
check/measure/benchmark performance, run `dart run perf`; for before/after
comparison, inspect the approved baseline and generated JSON report. Never use
a new baseline to hide a regression.

Reports are written to `performance/reports/` and history is appended to
`performance/history.jsonl`; both are gitignored by default. Commit
`performance/baselines/` when the team wants shared regression tracking.
New routes without scenarios are listed during discovery. A new screen needs a
stable scenario and test data before its performance can be compared; the
runner does not invent interactions. The disabled template example and
unsupported metrics are documented in
`tool/performance/README.md`.
