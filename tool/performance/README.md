# Performance scenarios for an app forked from this base

The base owns the profile-mode runner, metric collection, report format and
regression checks. Each product owns its measured flows and stable test data.

## Real data

Scenarios run against the real backend of the configured flavor with a real
test account, so numbers include real payload sizes, real latency and real
rendering of production-like content. This shows what users actually feel.

Set the account once on the measuring machine. Values stay out of the repo,
are passed to the app with `--dart-define`, and are masked as `***` in every
log and report.

```bash
export PERF_USERNAME=0900000000
export PERF_PASSWORD='...'
```

Use a dedicated account on `dev` or `staging` whose data nobody edits by
hand. Real data changes over time, so a regression can come from the data
rather than the code. Every report records request count, response size and
per-endpoint timing so the two can be told apart: if `network_response_kb`
doubled, the data grew. Network failures fail the run, because a scenario
that hit an error page does not measure the real screen.

## Add a scenario

1. Create `integration_test/performance/<name>_test.dart`.
2. Start the real app with `pumpLoggedInApp` from `support/perf_app.dart`. It
   runs `bootstrap` and logs in with the test account when no session exists.
   The app's sign-in and home screens are known only to
   `support/perf_app_adapter.dart`; when a fork replaces the auth flow, update
   that one file and every scenario keeps working.
3. Navigate like a user, wait for real data with `pumpUntilFound`, and wrap the
   measured interaction in `measureScenario`. Produce at least 20 frames, for
   example with `scrollSteps` or `pumpFor`.
4. Add a descriptor under `integration_test/performance/scenarios/`.

```dart
testWidgets('orders list scroll', (tester) async {
  await pumpLoggedInApp(tester);
  await tester.tap(find.text('Đơn hàng'));
  await measureScenario(tester, binding, () async {
    await pumpUntilFound(tester, find.byType(OrderTile));
    await scrollSteps(tester, find.byType(ListView));
  });
});
```

```json
{
  "id": "orders_list",
  "description": "Open orders with real data and scroll ten screens down",
  "routes": ["/orders"],
  "test": "integration_test/performance/orders_list_test.dart",
  "enabled": true
}
```

`app_start` is the included default scenario. It measures bootstrap, splash,
session restore or login, and the first real screen. The disabled
`template_home` pumps a screen directly and is kept only as a minimal code
sample.

## How the runner works

`derry perf run` discovers enabled descriptors and runs each one with
`flutter drive --profile --flavor <flavor> --no-dds`. The flavor comes from
`tool/performance/config.json` because this project defines `dev`, `staging`
and `prod` Android product flavors and iOS schemes. `--no-dds` lets the
scenario read heap usage from the VM service. On Android the profile APK is
built once per target and passed to every drive with
`--use-application-binary`; on iOS a reusable binary must be a signed IPA, so
each drive still builds.

The `startup` target in the config runs `flutter run --profile
--trace-startup` on `lib/main_dev.dart` and reads `start_up_info.json`.

The runner prints routes in `AppPage.pages` that no enabled scenario covers.
This is a source-level check for the `SLIPage(name: ...)` syntax; it does not
infer taps, login state, route arguments or test data.

## Metric notes

- Percentiles use the nearest-rank method. With few frames, p95/p99 collapse
  to the slowest frame, so a run below `min_frame_count` fails.
- Relative regression is undefined when a baseline metric is 0, which is
  common for jank. `zero_baseline_regression_delta` sets the allowed absolute
  increase per gated metric.
- Scenario duration starts before the first measured pump and ends after the
  interaction. It is not process cold startup; the `startup` target is.
- Heap metrics are taken after a forced GC before and after the scenario. They
  catch leaks such as heap growing on every scroll, and are not gated.
- Network metrics come from the Dart VM HTTP profiler for requests made with
  `dart:io`, which includes Dio. Query strings are removed and numeric ids are
  collapsed to `:id`. Request and response bodies are never read.
- The diagnosis pass enables `debugProfileBuildsEnabled`,
  `debugProfileLayoutsEnabled` and `debugProfilePaintsEnabled` in profile
  mode. Profile builds cannot limit tracing to app widgets, so framework
  widgets appear too. Rank by self time and read the app code that creates
  the top entries.
