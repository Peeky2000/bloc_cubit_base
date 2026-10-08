---
description: Giao một tính năng cho flutter-dev rồi flutter-tester kiểm tra độc lập, trả báo cáo tiếng Việt
argument-hint: "<spec, AC, link thiết kế hoặc mô tả tính năng>"
---

Deliver this feature end to end with the dev and tester agents:
$ARGUMENTS

Follow `docs/agents/delivery-loop.md` exactly.

1. Create a branch `feat/<feature>` from `main` if you are on `main`.
2. Act as `.agents/agents/flutter-dev.md`. First search the decision log and
   write `tech.md` with the `tech-design` skill, then STOP and ask the PM to
   approve it; do not write feature code in the same turn. After approval:
   reuse first, scaffold with
   `dart run tool/scaffold/feature.dart`, implement, then self-check with
   `derry gen` and `derry quality`. Write the handoff to
   `docs/handoffs/YYYY-MM-DD-hh-mm-<feature>.md`.
3. Start a separate subagent acting as `.agents/agents/flutter-tester.md`.
   Give it only the spec and the handoff path, not your reasoning. It writes
   acceptance tests from the AC before reading the code, then runs the
   functional and convention modes, plus security or performance when the
   change needs them.
4. On FAIL, fix as flutter-dev and send the handoff back. Stop after three
   rounds on the same finding and escalate.
5. Never edit `tool/convention/baseline.txt`, thresholds, baselines or
   acceptance tests as flutter-dev.
6. Finish with the Vietnamese PM report from `delivery-loop.md`: AC table,
   what was built, decisions needed, and what still needs a real device or
   server. Do not push or merge unless the PM asks.
