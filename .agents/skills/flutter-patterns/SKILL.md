---
name: flutter-patterns
description: >
  Standard technical pattern for the recurring concerns of a real app:
  pagination (pull-to-refresh, load more), forms and validation, offline
  cache (stale-while-revalidate), image upload with progress, realtime
  updates (stream, WebSocket, polling), deep links, push notifications and
  runtime permissions. Each pattern gives exact files, class and field names,
  state and effects, error/offline handling, security notes, a test
  checklist, compiled reference code and a decision id. Load when a product
  document or task needs one of these, before writing tech.md or code.
  Trigger: "phân trang", "load more", "kéo để làm mới", "pull to refresh",
  "form", "validate", "kiểm tra dữ liệu nhập", "offline", "cache", "upload
  ảnh", "tải ảnh lên", "realtime", "websocket", "polling", "deep link",
  "push notification", "thông báo đẩy", "xin quyền", "permission".
---

# Flutter patterns

One way per concern. A feature that needs one of the concerns below
implements it exactly as its reference describes, with the same class shapes,
field names, statuses and tests.

## Check the decision log first

```bash
python3 tool/decisions/decisions.py search "<concern>"
```

- Follow accepted decisions without re-deciding.
- A decision still `proposed` is the default to use; link it in `tech.md` so
  the PM approves it with the feature.
- To differ, propose a new decision that supersedes the old one
  (`decisions.py new ...`, `Thay thế: D-NNNN`). Never diverge silently.

## Patterns

| Pattern | Reference | Reference code and tests | Decision |
|---|---|---|---|
| Pagination: `RefreshIndicator` + `PaginatedListView`, page numbers, retry button | [references/pagination.md](references/pagination.md) | `test/patterns/pagination_pattern_test.dart` | D-0001 |
| Forms and validation | [references/form_validation.md](references/form_validation.md) | `test/patterns/form_validation_pattern_test.dart` | D-0002 |
| Offline cache: stale-while-revalidate, `maxStale` 7 days, per-user keys cleared on sign-out | [references/offline_cache.md](references/offline_cache.md) | `test/patterns/offline_cache_pattern_test.dart` | D-0003 |
| Image upload: system picker, re-encode without EXIF/GPS, progress, cancel | [references/image_upload.md](references/image_upload.md) | `test/patterns/image_upload_pattern_test.dart` | D-0004 |
| Realtime: WebSocket with ticket auth, full-jitter backoff, pause in background | [references/realtime.md](references/realtime.md) | `test/patterns/realtime_pattern_test.dart` | D-0005 |
| Deep links: verified App Links/Universal Links, allow-listed routes | [references/deep_link.md](references/deep_link.md) | `test/patterns/deep_link_pattern_test.dart` | D-0006 |
| Push notifications | [references/push_notification.md](references/push_notification.md) | `test/patterns/push_notification_pattern_test.dart` | D-0007 |
| Runtime permissions | [references/permission.md](references/permission.md) | `test/patterns/permission_pattern_test.dart` | D-0008 |

Decision files: `docs/decisions/D-000N-*.md`.

## How to use a pattern

1. Read the reference and its test file. The test file holds every class of
   the pattern, one section per real file, with the target path in the
   section header.
2. Copy each section into its path, rename the example entity (`Order`,
   `ShopForm`, `Dashboard`...) to the feature's words from the glossary, and
   uncomment the DI annotation.
3. Copy the tests into `test/presentation/<feature>_cubit_test.dart` and
   the data-layer tests next to their sources; keep every case in the
   reference's checklist.
4. Patterns that need a plugin not yet in `pubspec.yaml` define the domain
   port and fake now; the feature that first needs it adds the plugin, the
   adapter from the reference (already analyzed against the real package) and
   the native setup listed there. Plugins and versions:

   | Pattern | Packages |
   |---|---|
   | Image upload | `image_picker ^1.2.4`, `flutter_image_compress ^2.5.1` |
   | Realtime | `web_socket_channel ^3.0.3` |
   | Deep links | `app_links ^7.2.2` |
   | Push | `firebase_messaging ^16.7.0` (needs `firebase_core ^4.15.0`, iOS 15), `flutter_local_notifications ^19.5.0` |
   | Permissions | `permission_handler ^12.0.3` |
   | Large offline cache | `drift >=2.34.4 <2.35.0`, `drift_flutter ^0.3.1` (drift 2.35 needs injectable 3) |

## Shared rules

- Ports return one `Future<Outcome>` or a `Stream` for many events; failures
  are one typed domain failure (`flutter-repository/references/async-flow-patterns.md`).
- Anything persisted follows `flutter-datasource/references/storage-patterns.md`:
  owner per lifecycle, cleared on sign-out, revisioned writes.
- Cubits emit state and `UiEffect<T>` only (ADR-0009); Screens translate and
  navigate.
- After every `await` or stream event: check `isClosed` and the request
  generation.
- Build adapter streams with a `StreamController` or operators, not `async*`
  around an endless source; cancelling an `async*` stream waits for its next
  event, so `close()` can hang.
