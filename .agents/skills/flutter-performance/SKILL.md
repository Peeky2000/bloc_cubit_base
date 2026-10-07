---
name: flutter-performance
description: >
  Diagnose or improve Flutter/mobile performance using profile-mode evidence.
  Use for jank, "giật lag", slow startup, sluggish scrolling, memory growth,
  large images, excessive rebuilds, battery/network work, or when reviewing a
  performance claim. Require before/after measurements and a reproducible
  scenario.
---

# Flutter performance

Do not call code slow based only on appearance or a widget count. Use the user's
trace if available; otherwise define a reproducible profile-mode measurement.

## Measurement workflow

1. Record device/OS, Flutter version, build mode, data size, route, interaction
   and baseline. Separate cold from warm startup and first render from steady
   scrolling.
2. Capture evidence using Flutter DevTools Performance/Timeline, frame chart,
   CPU profiler, memory/allocations and network view as appropriate. For native
   bottlenecks, use Android Studio Profiler or Xcode Instruments.
3. Locate the expensive path in code. Compare UI and raster frame time, rebuild
   frequency, synchronous work, image decode/cache, list virtualization,
   layout/intrinsics and platform-channel cost. Treat a correlation as a lead,
   not proof of cause.
4. Change one bounded cause, then repeat the same scenario and report before/
   after values plus variability. Keep the change only if benefit outweighs
   complexity and UX trade-offs.

## Output

Report scenario, baseline, evidence source, suspected bottleneck, proposed or
implemented change, after measurement, and remaining uncertainty. If no
profile data can be obtained, provide the exact capture steps and avoid a
numerical improvement claim.

For this repo, inspect `BlocBuilder` scope and selectors, `Sli*` composition,
image loading, list builders, animation disposal, startup/bootstrap order and
network payloads. Do not add `const`, caching, isolates or `RepaintBoundary`
without a measured reason. Run focused behavior tests and `derry quality` after
an implementation.

## Opt-in benchmark harness

For an explicit benchmark/measurement request, follow `PERFORMANCE.md` and run
`derry perf run` (`dart run tool/perf.dart`) only after product scenarios are
registered. The runner discovers
enabled descriptors under `integration_test/performance/scenarios/` and lists
routes without coverage. A new route needs a deterministic scenario and data;
never infer arbitrary interactions or approve a baseline automatically. A
normal code edit does not trigger the benchmark.
