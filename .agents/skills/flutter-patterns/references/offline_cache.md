# Offline cache: stale-while-revalidate

Decision: [D-0003](../../../../docs/decisions/D-0003-cache-offline-theo-stale-while-revalidate.md)
(proposed). Reference code: `test/patterns/offline_cache_pattern_test.dart`.

## When to use

Screens that should open instantly and stay readable offline: home summary,
profile, settings from the server, a small reference list. Not for data that
must be exact now (balance before a payment), large or queryable lists (add a
local database by its own decision), or secrets.

## Decision

The repository owns cache and network and returns one
`Stream<CachedSnapshot<T>>`: the saved value first when it belongs to the
current account, then the network value unless the saved one is fresh; the
Cubit only renders snapshots.

## Files to create (feature `dashboard`, entity `DashboardSummary`)

| Layer | Path | Content |
|---|---|---|
| Shared entity (once) | `lib/domain/entities/common/cached_snapshot.dart` | `CachedSnapshot<T>{value, source, fetchedAt, revalidating}`, `SnapshotSource{cache, network}` |
| Entity | `lib/domain/entities/dashboard/dashboard_summary.dart` | abstract getters |
| Repo port | `lib/domain/repositories/dashboard_repo.dart` | `Stream<CachedSnapshot<DashboardSummary>> watchSummary({bool forceRefresh = false})`, `Future<void> clearCache()` |
| UseCase | `lib/domain/use_case/dashboard_use_case.dart` | passes through |
| Model | `lib/data/model/response/dashboard/dashboard_summary_response_model.dart` | `@JsonSerializable`, `fromJson`/`toJson` |
| Remote DS | `lib/data/datasource/remote/dashboard_remote_data_source.dart` | `ApiHandler.get` |
| Local DS | `lib/data/datasource/local/dashboard_local_data_source.dart` | `CacheEntry{ownerId, fetchedAt, value}` in SharedPreferences under `cache.dashboard_summary.v1` |
| Repo impl | `lib/data/repositories/dashboard_repo_impl.dart` | `freshFor = Duration(minutes: 5)`, injectable `now` |
| Cubit | `lib/presentation/dashboard/cubit/dashboard_cubit.dart` | `load()`, `refresh()` |
| State | `.../cubit/dashboard_state.dart` | `summary`, `updatedAt`, `showsSavedData` |

## Repository algorithm

```text
saved = local.read()                         // corrupt entry → null, removed
if saved belongs to current account:
    yield cache snapshot (revalidating = forceRefresh || stale)
    if fresh and not forceRefresh: done
remote = await network                       // failure → stream error
if this is still the newest read and the account did not change:
    local.write(entry)
yield network snapshot
```

- Key every entry by owner (account id). Another account never sees it.
- A revision counter in the repository lets only the newest read write the
  cache, so a slow older response cannot overwrite a newer one (storage
  rule 6).
- `clearCache()` is called from the session end path with everything else
  the user owns (storage rule 4).
- Bump the key suffix (`.v2`) when the stored shape changes; old entries
  become misses, never crashes.

## State

```dart
final DashboardSummary? summary;
final DateTime? updatedAt;              // fetchedAt of what is on screen
bool get showsSavedData => summary != null && error != null;
```

| Situation | `loading` | `summary` | `error` | Screen |
|---|---|---|---|---|
| first open, no cache | `loading` → `complete` | network | null | loader, then data |
| cache then network | `loading` → `refresh` → `complete` | cache, then network | null | data at once, small spinner |
| offline with cache | `complete` | cache | set | data + "offline, updated at {updatedAt}" banner with retry |
| offline without cache | `error` | null | set | full error with retry |

The offline banner is lasting state, not a one-shot effect: it stays until a
refresh succeeds.

## Cubit rules

- `_generation` per request. A newer `load`/`refresh` wins; snapshots of the
  older stream are dropped and leaving `await for` cancels it.
- After each snapshot: `isClosed` and generation check.

## Error, empty, offline

`NetworkIssueException` reaches the Cubit as a stream error after the cache
snapshot. An empty server value is a normal value. Pull-to-refresh and the
banner retry call `refresh()` (`forceRefresh: true`).

## Security and performance

- SharedPreferences is not encrypted. Cache only what the storage table in
  `flutter-datasource/references/storage-patterns.md` allows; personal data
  that is sensitive goes to secure storage or is not cached.
- Clear on sign-out and expiry.
- Small values only (a few KB). Larger or queryable data needs a database
  decision.
- `DateTime` stored in UTC ISO-8601.

## Test checklist

- [ ] No cache: network only, then written.
- [ ] Restart (new repo over the same storage): cache first, then network.
- [ ] Fresh cache skips the network; `forceRefresh` does not.
- [ ] Offline: cache snapshot, then error.
- [ ] Another account does not see the entry.
- [ ] `clearCache` removes it; corrupt entry is a miss.
- [ ] Cubit: statuses for no cache and cache-then-network.
- [ ] Offline with cache keeps data and shows the banner; retry clears it.
- [ ] Offline without cache is `error`.
- [ ] Newer request wins on screen and in storage.
- [ ] Snapshot after `close()` ignored.

Reference code: `test/patterns/offline_cache_pattern_test.dart`
