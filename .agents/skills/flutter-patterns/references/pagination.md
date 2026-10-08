# Pagination: pull-to-refresh and load more

Decision: [D-0001](../../../../docs/decisions/D-0001-phan-trang-danh-sach-keo-de-lam-moi-va-tai-them.md)
(proposed). Reference code: `test/patterns/pagination_pattern_test.dart`.

## When to use

Any server list that can grow past one screen: orders, products,
notifications, history. Not for a short fixed list (load it in one call), a
chat timeline (newest-first with a cursor), or a list that must stay offline
(combine with [offline_cache.md](offline_cache.md)).

## Decision

Page-number paging over `ApiHandler.getList` with `page`/`perPage`, read once
into a domain `PageResult`, driven by a Cubit whose state holds a
`LoadingListModel` and is rendered by the existing `LoadingListScreen`.

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
| Cubit | `lib/presentation/order_list/cubit/order_list_cubit.dart` | `OrderListCubit`: `load()`, `refresh()`, `loadMore()`; `static const pageSize = 20` |
| State | `.../cubit/order_list_state.dart` | see below |
| Effect | `.../cubit/order_list_effect.dart` | `OrderListShowErrorEffect{error, retryAction}` |
| Screen | `.../view/order_list_screen.dart` | `LoadingListScreen` + `RefreshController` + `syncRefreshController` |

The first page number is `Pagination.firstPage` (`lib/core/common/constant.dart`).
Query keys are `page` and `perPage`, the same names `BaseListResponseModel`
reads back.

## State and effects

```dart
class OrderListState extends BaseAppState<Object>
    implements BaseAppListState<Order> {
  // super(loading: orders.loading): one source of truth for the status.
  final LoadingListModel<Order> orders;   // items + LoadingStatus
  final int page;                          // last loaded page, 0 before load
  final bool hasMore;
  final UiEffect<OrderListEffect>? effect;
  @override LoadingListModel<Order> get loadingListModel => orders;
}
```

| Status in `orders.loading` | Meaning | UI |
|---|---|---|
| `loading` | first load | full-screen loader (LoadingListScreen) |
| `refresh` | pull-to-refresh, items stay | header spinner |
| `loadMore` | next page in flight | footer spinner |
| `complete` | settled, maybe more; empty list = empty view | idle |
| `noMoreData` | settled, end reached | footer "no more data" |
| `loadMoreError` | next page failed, items stay | footer "failed", pull up retries |
| `error` | first load failed, nothing to show | error view with retry → `load()` |

Effect: `OrderListShowErrorEffect` only when a refresh fails while items are
on screen (snackbar with retry → `refresh()`). Load-more failure is not an
effect; the footer shows it.

## Rules the Cubit follows

1. `loadMore()` runs only when status is `complete` or `loadMoreError` and
   `hasMore`. A second trigger while one is in flight does nothing.
2. Every first-page request bumps `_generation`; a response of an older
   generation is dropped. A refresh always wins over an in-flight load more.
3. Append with de-duplication by `id`. Page-based lists shift when the server
   inserts rows.
4. `hasMore` comes from `PageResult.fromResponse`: `page * perPage <
   totalResults` when the server sends `totalResults`, else "a full page means
   maybe more". No Cubit does paging arithmetic.
5. After every `await`, check `isClosed` and the generation.

## Screen

`RefreshController` lives in the Screen state and is disposed there. The
Cubit never sees it. `syncRefreshController(controller, state)` runs in the
`listener` of `LoadingListScreen` and maps state to `refreshCompleted`,
`refreshFailed`, `loadComplete`, `loadFailed` and `loadNoData`. Use
`buildWhen` on `orders` and give every row a `ValueKey(order.id)`.

## Error, empty, offline

- Empty first page: status `complete` with no items → `emptyWidget`.
- First load offline (`NetworkIssueException`): status `error`; the Screen
  maps the error with `ErrorMapper.parse` and offers retry.
- Refresh offline: items stay, one snackbar effect.
- Load more offline: items stay, footer failed, pull up again retries the same
  page.

## Security and performance

- Page size 20 by default; never request "all". The server must cap
  `perPage`.
- Ownership is checked by the API; never filter other users' rows on the
  client.
- Keep `buildWhen` narrow and row widgets `const` where possible. Measure
  long lists with the scenario in `docs/performance/ac-to-scenario.md`.

## Test checklist

- [ ] `PageResult.fromResponse` with and without `totalResults`, null data.
- [ ] Data source sends `page`/`perPage` and parses through `getList`.
- [ ] First load: `loading → complete`, items, page, `hasMore`.
- [ ] Load more appends until `noMoreData`; no request after the end.
- [ ] Duplicate load more while in flight sends nothing.
- [ ] Load more failure keeps items, `loadMoreError`, retry asks the same page.
- [ ] Refresh: `refresh → complete`, replaces items, reopens the footer.
- [ ] Refresh drops an older in-flight load more.
- [ ] De-duplication when rows shift.
- [ ] First load failure → `error`; refresh failure → effect, items kept.
- [ ] Empty list → `complete`, no items.
- [ ] Response after `close()` ignored.
- [ ] Widget: `LoadingListScreen` shows rows and the empty view;
      `syncRefreshController` maps every status.

Reference code: `test/patterns/pagination_pattern_test.dart`
