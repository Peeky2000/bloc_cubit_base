---
name: flutter-error-handling
description: >
  Layered error handling for this base: infrastructure exceptions, mapping,
  state errors, UI effects, redacted diagnostics, and session expiry.
  Trigger: exception, error, failure, dialog, retry, 401.
---

# Error handling

## Direction

```text
ApiClient/interceptors throw → DataSource propagates → Repository maps if needed
→ UseCase propagates domain meaning → Cubit/BLoC emits error → UI renders/effects
```

## Rules

- Data and domain code never imports UI, navigates, or displays dialogs.
- Interceptors classify transport/session problems but do not access BuildContext.
- Cubit/BLoC stores a recoverable error/failure in state and exposes retry as a
  method/event. UI maps that value to localized copy and presentation.
- `presentation/global_handler.dart` is a legacy compatibility adapter, not the
  pattern for new features. New code uses `BlocListener`/`BlocConsumer` for
  one-shot dialogs and navigation.
- Field validation errors are typed state, not raw Dio errors or hardcoded copy.
- Never log tokens, cookies, passwords, personal data, or unredacted bodies.
- Session refresh must be single-flight; terminal expiry clears credentials and
  emits one app-level session event.

Test failure mapping, retry state, redaction, and concurrent 401 behavior when
the relevant implementation changes.
