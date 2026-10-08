# Performance benchmark contract

Performance benchmarking is opt-in. Do not run it automatically after a code
change, during `flutter test`, `flutter run`, build, post-build, git hooks,
pre-commit, or default CI. Run it only when the user requests performance
measurement/regression work or explicitly asks to execute the benchmark.

| Command | What it does |
|---|---|
| `derry perf run` | Measure startup and all enabled scenarios |
| `derry perf diagnose` | Same, plus one instrumented pass that ranks slow widgets |
| `derry perf approve` | Measure again and store baselines if everything passes |
| `dart run tool/perf.dart --scenario=<id>` | Measure only the listed targets |

All commands need one real Android or iOS device. Select one with
`FLUTTER_PERF_DEVICE` when several are connected.

Scenarios use the real backend and a real test account, not fake data. Set
`PERF_USERNAME` and `PERF_PASSWORD` in the environment of the measuring
machine; they are masked in all output. See `tool/performance/README.md`.

## What is measured

| Target | Metrics | Source |
|---|---|---|
| `startup` | Time to first rasterized frame, time to framework init | `flutter run --profile --trace-startup` |
| Each scenario | Frame p50/p95/p99, jank, build p95, raster p95, scenario time | Engine `FrameTiming` |
| Each scenario | Dart heap at end and heap growth, reported but not gated | VM service after a forced GC |
| Each scenario | Request count, failures, p95 latency, response size, slowest endpoints | VM service HTTP profiler |
| Diagnosis pass | Slowest widgets and render objects by self time, GC counts | Instrumented VM timeline |

Everything runs in profile mode on the native flavor in
`tool/performance/config.json` (`dev` by default). Each scenario gets one
warmup and five measured runs and is compared on the median. Startup is
measured three times. On Android the profile APK is built once per target and
reused. CPU is not measured.

Diagnosis timings are inflated by tracing every widget. They show which
widgets cost the most relative to each other and are never compared with
thresholds or baselines. A failing scenario gets a diagnosis pass
automatically when `diagnose_on_failure` is true.

## Two kinds of limits

Every run is judged twice.

1. **Gate (PASS/FAIL)** blocks regressions. It uses hard limits and the
   comparison with the approved baseline in `thresholds`.
2. **Rating (GOOD / NEEDS_IMPROVEMENT / POOR)** tells how good the experience
   is. It uses `bands` and `data_budgets`, which are based on public
   standards so the numbers mean the same thing to everyone.

| Metric | GOOD up to | POOR above | Source |
|---|---|---|---|
| Startup first frame | 1500 ms | 5000 ms | Android vitals: cold start of 5 s or more is excessive |
| Frame p95 | 16.67 ms | 33 ms | One 60 Hz frame; two frames is visible stutter |
| Frame p99 | 33 ms | 700 ms | Android vitals: frames over 700 ms are frozen |
| Jank (frames over 16.67 ms) | 5% | 25% | Stricter than Play's 50% slow-rendering line |
| Scenario time | 1000 ms | 10000 ms | Nielsen: 1 s keeps flow, 10 s loses attention |
| Network p95 | 1000 ms | 3000 ms | Same 1 s limit applied to one request |

Between the two lines the rating is NEEDS_IMPROVEMENT. Change the lines in
`bands` when the product needs stricter or looser targets.

### Data-aware budgets

A screen that loads more real data may take longer, within a limit.
`data_budgets` sets this per scenario and metric:

```json
"orders_list": {
  "scenario_ms": {
    "items_metric": "data_items",
    "base_ms": 1000, "base_items": 50,
    "per_unit_ms": 200, "unit": 100,
    "cap_ms": 2500, "poor_factor": 2
  }
}
```

This reads: up to 50 orders must be GOOD within 1000 ms; every extra 100
orders allows 200 ms more; the budget never exceeds 2500 ms however much data
there is; POOR starts at twice the GOOD budget.

| Orders loaded | GOOD up to | POOR above |
|---:|---:|---:|
| 20 | 1000 ms | 2000 ms |
| 250 | 1400 ms | 2800 ms |
| 2000 | 2500 ms (cap) | 5000 ms |

The scenario reports its data size with
`measureScenario(..., dataSize: () => {'items': count})`; the runner turns it
into `data_items`. The cap matters: past it, the fix is pagination or lazy
loading, not more time. `_example_orders_list` in the config is a template.

### Gate defaults

| Gate | Default |
|---|---|
| Jank | ≤ 3% |
| Frame p95 / p99 | ≤ 20 ms / ≤ 32 ms |
| Scenario duration, including real network | ≤ 15000 ms |
| Startup first frame | ≤ 2000 ms |
| Failed network requests in a measured run | 0 |
| Regression versus baseline | ≤ 5% |
| Absolute regression when the baseline is 0 | per metric, e.g. jank +0.5 point |
| Frames per measured run (median) | ≥ 20 |

## Failed requests

A run with a failed request measured an error screen, not the real screen.
Each failure is classified by owner using HTTP semantics (RFC 9110: 4xx means
the request is wrong, 5xx means the server failed):

| Owner | Typical cause | What happens |
|---|---|---|
| `network` | Timeout, connection reset or refused, 408 | Run discarded and repeated after `retry.delay_seconds` |
| `backend` | 5xx, 429 | Run discarded and repeated; reported to the backend team if it persists |
| `mobile` | 400, 404, 405, 409, 422, auth call before login | Run kept and failed; the app sent a wrong request |
| `environment` | 401/403 with a session, DNS, TLS | Run kept and failed; check the test account and base URL |

At most `retry.max_extra_runs` runs are discarded per scenario. If valid runs
are still missing, the target is ERROR and is written to
`performance/pending.json` with its owners and the command to re-run it. The
next successful run removes it from the queue. Reports list failures grouped
by owner with endpoint, status, time and reason.

## Outputs

`performance/latest/summary.json` is the machine-readable result of the last
run for agents; `summary.md` is the same for people. Per-target reports and
command logs are in `performance/reports/<target>/`, and history is appended
to `performance/history.jsonl`. All of these are gitignored. Commit
`performance/baselines/` when the team wants shared regression tracking.

Exit codes: 0 pass, 1 a gate failed, 2 configuration or device problem,
3 a target could not be measured (see `log_tail` in the summary).

## Baselines

Baseline changes are never automatic. After reviewing a valid report, update
them only on explicit user request with `derry perf approve`. An approval run
measures again and still compares against the existing baseline from the same
environment, so a regression cannot be approved by accident. If a regression
is intentional, delete that target's baseline file in the same reviewed change
and state why. Never use a new baseline to hide a regression.

## Agent loop

`perf-tester` measures, diagnoses and writes a handoff; `perf-engineer` fixes
and self-checks; `perf-tester` verifies. The PM only plugs in a device and
reads the report. See `docs/performance/agent-loop.md`.
