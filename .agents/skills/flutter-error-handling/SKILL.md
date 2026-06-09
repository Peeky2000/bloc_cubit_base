---
name: flutter-error-handling
description: >
  Error handling for this base: core exceptions, Dio interceptors, ErrorMapper,
  handleErrorResponse + DialogUtil. Trigger: "exception", "error", "dialog", "401".
---

# Error Handling

## Key files

| File | Role |
|------|------|
| `lib/core/error/exception.dart` | `ServerException`, `NetworkIssueException`, `GeneralException`, … |
| `lib/core/error/error_to_string_mapper.dart` | `ErrorMapper.parse(error)` → user message |
| `lib/presentation/global_handler.dart` | `handleErrorResponse(error, onRetry: …)` |
| `lib/core/widget/dialog_util.dart` | Error dialog UI |
| `lib/data/datasource/remote/interceptor/` | Auth, network, session interceptors |

## Cubit pattern

```dart
} catch (e) {
  emit(state.copyWith(loading: LoadingStatus.error));
  handleErrorResponse(e, onRetry: () => _retry());
}
```

## Rules

- Data sources / API: throw or propagate — do not show UI
- Cubit: catch, update state, call `handleErrorResponse` for global dialog when appropriate
- UI: do not inspect raw `DioException` in widgets
- Field validation errors: keep in state (`errorUsername`, …) — not `handleErrorResponse`

## References

- `references/exception-hierarchy.md` — align with `core/error/exception.dart`
- Ignore unauthorized go_router redirect docs unless app adds that flow in `AppCubit`
