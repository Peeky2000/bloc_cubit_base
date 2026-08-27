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
2. Add `static const String myPage = '/my_page';` to `AppPage`.
3. Append `SLIPage(name: myPage, page: myPageScreenBuilder())` to `AppPage.pages`.
4. Navigate with `SLIRouting.toNamed(AppPage.myPage)` or `offAllNamed`.

## Arguments

```dart
SLIRouting.toNamed(
  AppPage.confirmInfo,
  arguments: {'phone': phone, 'page_success': AppPage.home},
);
```

Read arguments in the target screen from route settings (follow existing screens).

## Rules

- Do **not** add `go_router` or `GoRoute`
- Path constants: `lowerCamelCase` on `AppPage`, value `'/snake_case'`
- Auth redirects: handle in splash / app cubit flow (see `SplashCubit`), not inside random widgets

## State owner composition

Resolve a screen-scoped Cubit/BLoC once in the screen builder and provide it with
`BlocProvider`. Navigation is a UI effect handled by a listener; reusable state
logic does not retain BuildContext or call `SLIRouting` directly.
