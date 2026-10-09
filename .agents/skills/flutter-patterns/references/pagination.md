# Pagination: pull-to-refresh and load more

Decision: [D-0001](../../../../docs/decisions/D-0001-phan-trang-danh-sach-keo-de-lam-moi-va-tai-them.md)
(proposed). Reference code: `test/patterns/pagination_pattern_test.dart`.

## When to use

Any server list that can grow past one screen: orders, products,
notifications, history. Not for a short fixed list (load it in one call), a
chat timeline or a feed with constant inserts (ask the backend for a cursor,
see below), or a list that must stay offline (combine with
[offline_cache.md](offline_cache.md)).

## Decision

Page-number paging over `ApiHandler.getList` with `page`/`perPage`, read once
into a domain `PageResult`, driven by a Cubit, and rendered with Flutter's own
widgets: `RefreshIndicator.adaptive` + `ListView.builder` + scroll
notifications in one shared `PaginatedListView`. No paging package.

- `pull_to_refresh` (used by `LoadingListScreen`) is not used for new lists:
  last release 2.0.0 on 2021-05-07, no commit since, unverified uploader.
- Page paging duplicates or skips rows when the server inserts between
  requests; cursor/keyset paging does not (AIP-158). Our backend sends
  `page`/`perPage`, so we de-duplicate by `id`. When the API offers
  `nextCursor`, carry it in `PageResult` by a superseding decision.

## Files to create (feature `order_list`, entity `Order`)

| Layer | Path | Content |
|---|---|---|
| Entity | `lib/domain/entities/order/order.dart` | `abstract class Order` with `id` |
| Shared entity (once) | `lib/domain/entities/common/page_result.dart` | `PageResult<T>{items, page, hasMore}` + `PageResult.fromResponse` |
| Repo port | `lib/domain/repositories/order_repo.dart` | `Future<BaseListResponse<Order>> getOrders({required int page, required int pageSize})` |
| UseCase | `lib/domain/use_case/order_use_case.dart` | `Future<PageResult<Order>> getOrders(...)`; register in `lib/di/register_module.dart` |
| Model | `lib/data/model/response/order/order_response_model.dart` | `@JsonSerializable() class OrderResponseModel implements Order` |
| Remote DS | `lib/data/datasource/remote/order_remote_data_source.dart` | `_api.getList<OrderResponseModel>(UrlEndPoint..., queryParameters: {'page': page, 'perPage': pageSize}, parser: ...)` |
| Repo impl | `lib/data/repositories/order_repo_impl.dart` | `@LazySingleton(as: OrderRepo)`, passes through |
| Cubit | `lib/presentation/order_list/cubit/order_list_cubit.dart` | `load()`, `refresh()`, `loadMore()`, `retryLoadMore()`; `static const pageSize = 20` |
| State | `.../cubit/order_list_state.dart` | see below |
| Effect | `.../cubit/order_list_effect.dart` | `OrderListShowErrorEffect{error, retryAction}` |
| Shared widget (once) | `lib/widget/paginated_list_view.dart` | `PaginatedListView<T>` |
| Screen | `.../view/order_list_screen.dart` | `BlocConsumer` + `PaginatedListView<Order>` + `GlobalKey<RefreshIndicatorState>` |

The first page number is `Pagination.firstPage` (`lib/core/common/constant.dart`).
Query keys are `page` and `perPage`, the same names `BaseListResponseModel`
reads back.

## State and effects

```dart
class OrderListState extends BaseAppState<Object> {
  final List<Order> orders;   // unmodifiable; new list only when items change
  final int page;             // last loaded page, 0 before load
  final bool hasMore;
  final UiEffect<OrderListEffect>? effect;
}                             // `loading` is the one list status
```

| `loading` | Meaning | UI |
|---|---|---|
| `loading` | first load | centered spinner |
| `refresh` | pull-to-refresh, items stay | `RefreshIndicator` spinner |
| `loadMore` | next page in flight | footer spinner |
| `complete` | settled, maybe more; no items = empty view | idle |
| `noMoreData` | settled, end reached | footer "no more data" |
| `loadMoreError` | next page failed, items stay | footer message + Retry button |
| `error` | first load failed, nothing to show | error view + Retry → `load()` |

Effect: `OrderListShowErrorEffect` only when a refresh fails while items are
on screen (snackbar with retry). Load-more failure is not an effect.

## Rules the Cubit follows

1. `loadMore()` runs only when `loading == complete` and `hasMore`; repeated
   scroll events and a second trigger in flight send nothing.
2. A failed page is retried only by `retryLoadMore()` (footer button), never
   by scrolling, so an offline user is not spammed with requests.
3. Every first-page request bumps `_generation`; a response of an older
   generation is dropped. A refresh always wins over an in-flight load more.
4. Append with de-duplication by `id`.
5. `hasMore` comes from `PageResult.fromResponse`: an empty page always ends
   the list; else `page * perPage < totalResults` when sent; else "a full
   page means maybe more". No Cubit does paging arithmetic.
6. `refresh()` returns the Future `RefreshIndicator.onRefresh` awaits; the
   error stays until the new result so an error view does not flash empty.
7. After every `await`, check `isClosed` and the generation.

## PaginatedListView

- Load more when `extentAfter < 250` px (Flutter's default cache extent), on
  `ScrollUpdateNotification` and on `ScrollMetricsNotification`, so a first
  page shorter than the screen (tablet, landscape) still loads the next one.
- `AlwaysScrollableScrollPhysics` everywhere, so the empty and error views
  can be pulled to refresh.
- `listKey: PageStorageKey(...)` keeps the scroll offset across tabs; rows
  use `ValueKey(item.id)`; give `ListView` an extent when rows are fixed.
- Footer and errors reuse `SliButton`; texts come from l10n and
  `ErrorMapper.parse`.

## Accessibility

- `CircularProgressIndicator.adaptive` ignores `semanticsLabel` on iOS, so
  every spinner is wrapped in `Semantics(label: l10n.loading)`.
- Footer failure and first-page error are `Semantics(liveRegion: true)`:
  TalkBack and VoiceOver announce them politely. Do not call
  `SemanticsService.announce` (deprecated after 3.35; Android discourages
  announcements).
- Pull-to-refresh is a drag, so the Screen also offers an app bar refresh
  action calling `refreshKey.currentState?.show()` (WCAG 2.5.7).

## Error, empty, offline

Empty first page: empty view, pullable. First load offline
(`NetworkIssueException`): `error` + `ErrorMapper.parse` + Retry. Refresh
offline: items stay, one snackbar. Load more offline: footer Retry.

## Security and performance

- Page size 20 by default; never request "all". The server must cap
  `perPage`.
- Ownership is checked by the API; never filter other users' rows on the
  client.
- Narrow `buildWhen` (`loading`, `orders`, `hasMore`, `error`). Measure long
  lists with the scenario in `docs/performance/ac-to-scenario.md`.

## Test checklist

- [ ] `PageResult.fromResponse` with and without `totalResults`, null data,
      empty page with a larger `totalResults`.
- [ ] Data source sends `page`/`perPage` and parses through `getList`.
- [ ] Load until `noMoreData`, nothing after the end or while in flight.
- [ ] Load more failure keeps items; scrolling does not retry;
      `retryLoadMore` asks the same page.
- [ ] Refresh replaces items, reopens the footer, drops an older load more.
- [ ] De-duplication; empty list; first load `error`; refresh failure effect;
      response after `close()` ignored.
- [ ] Widget: scroll near the end loads; a short page fills the screen; footer
      Retry; empty view pulls to refresh; first-page error Retry.

## Nguồn

- RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Long lists: https://docs.flutter.dev/cookbook/lists/long-lists
- ScrollMetricsNotification: https://api.flutter.dev/flutter/widgets/ScrollMetricsNotification-class.html
- Semantics liveRegion: https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html
- SemanticsService.announce (deprecated): https://api.flutter.dev/flutter/semantics/SemanticsService/announce.html
- pull_to_refresh: https://pub.dev/packages/pull_to_refresh
- infinite_scroll_pagination 5.1.1 changelog: https://pub.dev/packages/infinite_scroll_pagination/changelog
- very_good_infinite_list: https://pub.dev/packages/very_good_infinite_list
- Bloc infinite list tutorial: https://bloclibrary.dev/tutorials/flutter-infinite-list/
- AIP-158 pagination: https://google.aip.dev/158
- Keyset vs offset: https://use-the-index-luke.com/no-offset
- Swipe-to-refresh accessibility: https://developer.android.com/develop/ui/views/touch-and-input/swipe/add-swipe-interface
- WCAG 2.5.7 Dragging Movements: https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html

Reference code: `test/patterns/pagination_pattern_test.dart`
