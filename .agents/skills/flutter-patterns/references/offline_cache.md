# Offline cache: stale-while-revalidate

Decision: [D-0003](../../../../docs/decisions/D-0003-cache-offline-theo-stale-while-revalidate.md)
(proposed). Reference code: `test/patterns/offline_cache_pattern_test.dart`.

## When to use

Screens that should open instantly and stay readable offline: home summary,
profile, settings from the server, a small reference list. Not for data that
must be exact now (balance before a payment: network-first, no cache), large
or queryable lists (local database, see Storage), offline writes (sync queue,
own decision), or secrets.

## Decision

The repository owns cache and network and returns one
`Stream<CachedSnapshot<T>>`: the saved value first when it belongs to the
current account and is not expired, then the network value unless the saved
one is fresh; the Cubit only renders snapshots and revalidates when the
network comes back. This is the "local then remote stream" of the Flutter
offline-first guide, with HTTP `max-age` + `stale-while-revalidate`
semantics (RFC 5861): `freshFor` = no request, up to `maxStale` = show and
revalidate, past `maxStale` = never shown.

## Files to create (feature `dashboard`, entity `DashboardSummary`)

| Layer | Path | Content |
|---|---|---|
| Shared entity (once) | `lib/domain/entities/common/cached_snapshot.dart` | `CachedSnapshot<T>{value, source, fetchedAt, revalidating}`, `SnapshotSource{cache, network}` |
| Shared cleaner (once) | `lib/data/datasource/local/user_cache_cleaner.dart` | `UserCacheCleaner.clearAll()` removes every `cache.*` key; called from `SessionRepoImpl.end()` |
| Entity | `lib/domain/entities/dashboard/dashboard_summary.dart` | abstract getters |
| Repo port | `lib/domain/repositories/dashboard_repo.dart` | `Stream<CachedSnapshot<DashboardSummary>> watchSummary({bool forceRefresh = false})`, `Future<void> clearCache()` |
| UseCase | `lib/domain/use_case/dashboard_use_case.dart` | passes through |
| Model | `lib/data/model/response/dashboard/dashboard_summary_response_model.dart` | `@JsonSerializable`, `fromJson`/`toJson` |
| Remote DS | `lib/data/datasource/remote/dashboard_remote_data_source.dart` | `ApiHandler.get` |
| Local DS | `lib/data/datasource/local/dashboard_local_data_source.dart` | `CacheEntry{ownerId, fetchedAt, value}` in SharedPreferences under `cache.dashboard_summary.v1` |
| Repo impl | `lib/data/repositories/dashboard_repo_impl.dart` | `freshFor = 5 min`, `maxStale = 7 days`, injectable `now` |
| Cubit | `lib/presentation/dashboard/cubit/dashboard_cubit.dart` | `load()`, `refresh()`; takes `NetworkChecker` |
| State | `.../cubit/dashboard_state.dart` | `summary`, `updatedAt`, `showsSavedData` |

## Repository algorithm

```text
owner = signed-in account id               // none → no read, no write
saved = local.read() if owner              // corrupt → null, removed
if saved.owner != owner: saved = null
if age(saved) > maxStale: remove, saved = null
if saved:
    fresh = 0 <= age < freshFor            // future time (clock moved) is stale
    yield cache snapshot (revalidating = forceRefresh || !fresh)
    if fresh and not forceRefresh: done
remote = await network                     // failure → stream error
if newest read and account unchanged: local.write(entry)
yield network snapshot
```

- Owner inside the entry, one key per feature: the device never holds two
  accounts' data, and another account never sees it.
- A revision counter lets only the newest read write (storage rule 6); a
  response landing after sign-out is not saved.
- Every user cache key starts with `UserCacheCleaner.prefix` (`cache.`).
  `SessionRepoImpl.end()` (sign-out and expiry) calls `clearAll()` once, so a
  new feature cannot forget its own clear (storage rules 1, 4, 5).
- Schema change: bump the key suffix (`.v2`). The old key is a miss, never a
  crash, and `clearAll()` removes it at sign-out.
- `clearCache()` is for invalidation after an edit that makes the value wrong.

## State

```dart
final DashboardSummary? summary;
final DateTime? updatedAt;              // device time the value was received
bool get showsSavedData => summary != null && error != null;
```

| Situation | `loading` | `summary` | `error` | Screen |
|---|---|---|---|---|
| first open, no cache | `loading` → `complete` | network | null | loader, then data |
| cache then network | `loading` → `refresh` → `complete` | cache, then network | null | data at once, small spinner |
| offline with cache | `complete` | cache | set | data + "offline, updated at {updatedAt}" banner with retry |
| offline without cache | `error` | null | set | full error with retry |

The banner is lasting state, not a one-shot effect. It stays during a retry
(the error is kept while a cache snapshot is revalidating) and clears only
when a network snapshot arrives, so saved data is never shown as fresh.

## Cubit rules

- `_generation` per request; a newer `load`/`refresh` wins, older snapshots
  are dropped and leaving `await for` cancels the stream.
- After each snapshot: `isClosed` and generation check.
- Subscribes to `NetworkChecker.connectionChanges`; on `true` while `error`
  is set it calls `refresh()`. Cancel the subscription in `close()`.
- Connectivity is only a retry hint. Never skip a request because it says
  offline: a Wi-Fi without internet reports connected (connectivity_plus).

## Storage

| Data | Store |
|---|---|
| One small value per feature (a few KB) | `SharedPreferences` (this pattern) |
| Lists, paging offline, queries, many rows | drift with its own decision |
| Secrets, tokens | `flutter_secure_storage`, never this cache |

- drift (Flutter Favorite, verified publisher, typed migrations with
  `schemaVersion` + `make-migrations`). With our `injectable_generator
  ^2.12.1` (analyzer < 11) the newest pair that resolves is `drift:
  ">=2.34.4 <2.35.0"`, `drift_flutter: ^0.3.1`, dev `drift_dev: 2.34.0`
  (checked with `pub get --dry-run`). drift 2.35 needs injectable 3.
- Not chosen: isar (last release 2023-04-25, SDK < 3.0), hive (2022);
  hive_ce is maintained but has no SQL queries or typed migrations.
- SharedPreferences writes are not guaranteed durable: a cache only, never
  the only copy. The legacy `SharedPreferences` API is planned for
  deprecation; the app moves to `SharedPreferencesWithCache` in one go.

## Security and performance

- SharedPreferences is not encrypted and is in Android Auto Backup by
  default. Cache only what `flutter-datasource/references/storage-patterns.md`
  allows; the owner check stops a restored entry from leaking to another
  account.
- Clear on sign-out, expiry and `maxStale`. `DateTime` stored in UTC ISO-8601.

## Test checklist

- [ ] No cache: network only, then written. Restart: cache, then network.
- [ ] Fresh cache skips the network; `forceRefresh` does not.
- [ ] Past `maxStale`: not shown offline, removed. Future time: not fresh.
- [ ] Offline: cache snapshot, then error.
- [ ] Another account and no account see nothing; no account saves nothing.
- [ ] Response after sign-out not saved; `clearAll` removes every `cache.*`
      key and keeps settings; corrupt entry is a miss.
- [ ] Cubit: statuses for no cache and cache-then-network; offline with cache
      shows the banner; failed retry keeps it; success clears it.
- [ ] Reconnect with an error revalidates; without an error sends nothing.
- [ ] Offline without cache is `error`; newer request wins on screen and in
      storage; snapshot after `close()` ignored.

## Nguồn

- Flutter offline-first: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Flutter key-value and SQL persistence: https://docs.flutter.dev/app-architecture/design-patterns/key-value-data, https://docs.flutter.dev/app-architecture/design-patterns/sql
- Android offline-first: https://developer.android.com/topic/architecture/data-layer/offline-first
- RFC 5861 stale-while-revalidate: https://www.rfc-editor.org/rfc/rfc5861
- web.dev stale-while-revalidate: https://web.dev/articles/stale-while-revalidate
- SWR revalidate on reconnect: https://swr.vercel.app/docs/revalidation
- shared_preferences: https://pub.dev/packages/shared_preferences
- connectivity_plus: https://pub.dev/packages/connectivity_plus
- drift, drift_dev, migrations: https://pub.dev/packages/drift, https://pub.dev/packages/drift_dev, https://drift.simonbinder.eu/migrations/
- isar, hive_ce: https://pub.dev/packages/isar, https://pub.dev/packages/hive_ce
- Android Auto Backup: https://developer.android.com/identity/data/autobackup

Reference code: `test/patterns/offline_cache_pattern_test.dart`
