---
description: Viết kịch bản đo hiệu năng và đề xuất ngưỡng từ AC hoặc mô tả bằng lời
argument-hint: "<AC dán vào, đường dẫn spec kèm mã AC, hoặc mô tả thao tác>"
---

Write performance scenarios for this input: $ARGUMENTS

Act as `.agents/agents/perf-tester.md`. Do not edit anything under `lib/`.
Follow `docs/performance/ac-to-scenario.md` exactly.

1. Identify the input:
   - pasted acceptance criteria text;
   - a spec path, optionally with AC ids, such as
     `docs/specs/012-orders/fe.md AC3 AC5`; read section 9 of that spec;
   - a plain description of a flow.
2. Split it into measurable flows. Skip criteria that only state business
   rules or content. List the skipped ones and why.
3. For each flow, classify its interaction type with the table in
   `ac-to-scenario.md` and choose the primary metric and default targets.
   Use numbers from the AC when it has them and mark those `approved`.
4. Find the route, screen, widgets and texts by reading
   `lib/core/common/route.dart`, the screen under `lib/presentation/` and the
   ARB files. Prefer finding widgets by type over by text. Never guess.
5. Create `integration_test/performance/<id>_test.dart`:
   - start with `pumpLoggedInApp` from `support/perf_app.dart`;
   - do setup such as navigation outside `measureScenario`;
   - wrap only the interaction the AC is about in `measureScenario`;
   - wait for real data with `pumpUntilFound`;
   - pass `dataSize` when the flow loads a list;
   - produce at least 20 frames, for example with `scrollSteps`.
6. Create `integration_test/performance/scenarios/<id>.json` with
   `enabled: true`, the routes, `source` (spec, ac, text) and `targets` with
   `status: "proposed"` and a Vietnamese `rationale`.
7. Run `derry quality`, then `dart run tool/perf.dart --scenario=<ids>` if a
   device is connected. Fix the scenario until it measures. If a device is
   missing, say so and stop after quality.
8. Report in Vietnamese as a table: AC, flow, interaction type, proposed
   targets, first measured value and rating. Ask the PM to approve or adjust
   the targets. Never set `status` to `approved` for inferred targets.
