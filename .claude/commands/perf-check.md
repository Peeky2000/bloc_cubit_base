---
description: Chạy toàn bộ vòng đo và tối ưu hiệu năng bằng agent, trả báo cáo cho PM
argument-hint: "[màn hoặc luồng cần đo, bỏ trống để đo toàn bộ]"
---

Run the performance agent loop for this repository without asking the PM to
operate anything except plugging in a device.

Scope from the PM: $ARGUMENTS

1. Read `docs/performance/agent-loop.md`, `.agents/agents/perf-tester.md` and
   `.agents/agents/perf-engineer.md`.
2. Preflight, in this order, and stop with a short PM report if any fails:
   - `fvm flutter devices` shows one real Android or iOS device.
   - `PERF_USERNAME` and `PERF_PASSWORD` are set in the environment. Never
     print their values.
   - The base URL in `lib/core/app/app_config.dart` is not an `example.com`
     placeholder, or `API_BASE_URL` is set.
   - At least 10 GB of free disk space.
3. If the scope names a screen or flow without a scenario, act as perf-tester
   and write the scenario first with `pumpLoggedInApp`, then run it once with
   `dart run tool/perf.dart --scenario=<id>` until it produces numbers.
4. Run targets listed in `performance/pending.json` first, then
   `derry perf run`, or `--scenario=<ids>` when the scope is narrow.
5. Follow the loop: perf-tester writes a handoff for each app-owned finding,
   perf-engineer fixes and self-checks, perf-tester verifies. At most three
   rounds per finding. Use separate subagents for tester and engineer when the
   platform supports them, so the verifier is independent.
6. Write the PM report in Vietnamese to
   `docs/performance/YYYY-MM-DD-report.md` with the template in
   `agent-loop.md`, using ratings and thresholds from
   `docs/performance/standards.md`.
7. Never run `derry perf approve`, loosen thresholds, disable scenarios or
   delete baselines. Put those decisions in the report for the PM.
