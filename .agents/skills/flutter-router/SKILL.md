---
name: flutter-router
description: >
  Navigation for this base using SLIRouting, AppPage, and SLIPage (not go_router).
  Use when adding screens, named routes, or passing arguments. Trigger: "routing",
  "navigation", "SLIRouting", "AppPage", "route".
---

# Flutter Routing — SLIRouting

## Key files

| File | Role |
|------|------|
| `lib/core/common/route.dart` | `AppPage` path constants + `pages` list |
| `lib/core/routing/routing.dart` | `SLIRouting` — `toNamed`, `offNamed`, `offAllNamed`, `back` |
| `lib/core/routing/sli_page.dart` | `SLIPage` wrapper |
| `presentation/*/view/*_screen.dart` | `*ScreenBuilder()` functions registered in route list |

## Add a new screen

1. Create `presentation/<feature>/view/<feature>_screen.dart` with builder function.
2. Add `static const String MY_PAGE = '/my_page';` to `AppPage`.
3. Append `SLIPage(name: MY_PAGE, page: myPageScreenBuilder())` to `AppPage.pages`.
4. Navigate: `SLIRouting.toNamed(AppPage.MY_PAGE)` or `offAllNamed` with `arguments: {...}`.

## Arguments

```dart
SLIRouting.toNamed(
  AppPage.CONFIRM_INFO,
  arguments: {'phone': phone, 'page_success': AppPage.HOME},
);
```

Read arguments in the target screen from route settings (follow existing screens).

## Rules

- Do **not** add `go_router` or `GoRoute`
- Path constants: `SCREAMING_SNAKE` on `AppPage`, value `'/snake_case'`
- Auth redirects: handle in splash / app cubit flow (see `SplashCubit`), not inside random widgets

## References

- `references/setup.md` — update mentally: SLI stack only
- Ignore go_router-specific rules in `rules/go-vs-push.md` — use `SLIRouting.toNamed` / `offAllNamed` instead
