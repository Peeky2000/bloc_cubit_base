// Reference implementation: pagination with pull-to-refresh and load more.
//
// Pattern: .agents/skills/flutter-patterns/references/pagination.md
// Decision: docs/decisions/D-0001-phan-trang-danh-sach-keo-de-lam-moi-va-tai-them.md
//
// Every section below is one file of a real feature. Copy the shape into the
// path in the section header, rename `Order` to the feature's entity, and keep
// the behavior the tests pin. The code here compiles against the real base
// types (BaseCubit, BaseAppState, BaseListResponseModel, ApiHandler,
// ErrorMapper) so a change to the base breaks it. The list uses Flutter's own
// widgets only: RefreshIndicator, ListView.builder and scroll notifications.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/error_to_string_mapper.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/model/response/base_list_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/response/base_list_response.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sli_common/sli_common.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/order/order.dart
// ---------------------------------------------------------------------------

abstract class Order {
  String get id;

  String get code;
}

// ---------------------------------------------------------------------------
// lib/domain/entities/common/page_result.dart  (shared; add once)
// ---------------------------------------------------------------------------

/// One page of a list as the domain sees it.
final class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  /// Reads the paging contract of `BaseListResponse` once, so no Cubit does
  /// paging arithmetic. An empty page always ends the list, so a server whose
  /// `totalResults` disagrees with its data cannot cause endless requests.
  /// Otherwise uses `totalResults` when the server sends it and treats a full
  /// page as "there may be more".
  factory PageResult.fromResponse(
    BaseListResponse<T> response, {
    required int page,
    required int pageSize,
  }) {
    final items = response.data ?? <T>[];
    final servedPage = response.page ?? page;
    final servedSize = response.perPage ?? pageSize;
    final total = response.totalResults;
    final hasMore =
        items.isNotEmpty &&
        (total != null
            ? servedPage * servedSize < total
            : items.length >= servedSize);
    return PageResult<T>(items: items, page: servedPage, hasMore: hasMore);
  }

  final List<T> items;
  final int page;
  final bool hasMore;
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/order_repo.dart
// ---------------------------------------------------------------------------

abstract class OrderRepo {
  /// Returns one page. [page] starts at `Pagination.firstPage`. Transport
  /// failures are thrown unchanged (NetworkIssueException, ServerException).
  Future<BaseListResponse<Order>> getOrders({
    required int page,
    required int pageSize,
  });
}

// ---------------------------------------------------------------------------
// lib/domain/use_case/order_use_case.dart  (registered in register_module.dart)
// ---------------------------------------------------------------------------

class OrderUseCase {
  OrderUseCase(this._repo);

  final OrderRepo _repo;

  Future<PageResult<Order>> getOrders({
    required int page,
    required int pageSize,
  }) async {
    final response = await _repo.getOrders(page: page, pageSize: pageSize);
    return PageResult<Order>.fromResponse(
      response,
      page: page,
      pageSize: pageSize,
    );
  }
}

// ---------------------------------------------------------------------------
// lib/data/model/response/order/order_response_model.dart
// In the app this is @JsonSerializable with part 'order_response_model.g.dart'.
// ---------------------------------------------------------------------------

class OrderResponseModel implements Order {
  OrderResponseModel({required this.id, required this.code});

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) =>
      OrderResponseModel(
        id: json['id'] as String,
        code: json['code'] as String,
      );

  @override
  final String id;

  @override
  final String code;
}

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/order_remote_data_source.dart
// ---------------------------------------------------------------------------

abstract class OrderRemoteDataSource {
  Future<BaseListResponseModel<OrderResponseModel>> getOrders({
    required int page,
    required int pageSize,
  });
}

// @LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._api);

  final ApiHandler _api;

  @override
  Future<BaseListResponseModel<OrderResponseModel>> getOrders({
    required int page,
    required int pageSize,
  }) {
    // The path belongs in url_end_point.dart in the app.
    return _api.getList<OrderResponseModel>(
      '/orders',
      queryParameters: {'page': page, 'perPage': pageSize},
      parser: OrderResponseModel.fromJson,
    );
  }
}

// ---------------------------------------------------------------------------
// lib/data/repositories/order_repo_impl.dart
// ---------------------------------------------------------------------------

// @LazySingleton(as: OrderRepo)
class OrderRepoImpl implements OrderRepo {
  OrderRepoImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<BaseListResponse<Order>> getOrders({
    required int page,
    required int pageSize,
  }) => _remote.getOrders(page: page, pageSize: pageSize);
}

// ---------------------------------------------------------------------------
// lib/presentation/order_list/cubit/order_list_effect.dart  (part file)
// ---------------------------------------------------------------------------

enum OrderListRetryAction { refresh }

sealed class OrderListEffect {
  const OrderListEffect();
}

/// A refresh failed while a list is already on screen. The list stays; the
/// Screen shows a snackbar with a retry button.
final class OrderListShowErrorEffect extends OrderListEffect {
  const OrderListShowErrorEffect({
    required this.error,
    required this.retryAction,
  });

  final Object error;
  final OrderListRetryAction retryAction;
}

// ---------------------------------------------------------------------------
// lib/presentation/order_list/cubit/order_list_state.dart  (part file)
// ---------------------------------------------------------------------------

/// `loading` (from BaseAppState) is the one list status: initial, loading,
/// refresh, loadMore, complete, noMoreData, loadMoreError or error.
class OrderListState extends BaseAppState<Object> {
  const OrderListState({
    required super.loading,
    required this.orders,
    required this.page,
    required this.hasMore,
    super.error,
    this.effect,
  });

  factory OrderListState.initial() => const OrderListState(
    loading: LoadingStatus.initial,
    orders: [],
    page: Pagination.firstPage - 1,
    hasMore: true,
  );

  /// Unmodifiable. The Cubit builds a new list only when the items change, so
  /// `buildWhen` can compare by identity.
  final List<Order> orders;

  /// The last page that was loaded; 0 before the first page.
  final int page;

  /// Whether another page may exist.
  final bool hasMore;

  final UiEffect<OrderListEffect>? effect;

  OrderListState copyWith({
    LoadingStatus? loading,
    List<Order>? orders,
    int? page,
    bool? hasMore,
    Object? error,
    UiEffect<OrderListEffect>? effect,
  }) {
    return OrderListState(
      loading: loading ?? this.loading,
      orders: orders ?? this.orders,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, orders, page, hasMore, error, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/order_list/cubit/order_list_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class OrderListCubit extends BaseCubit<OrderListState> {
  OrderListCubit(this._useCase) : super(OrderListState.initial());

  /// Page size of this list. Use one constant per list, default 20.
  static const int pageSize = 20;

  final OrderUseCase _useCase;

  /// Bumped by every first-page request. A response from an older generation
  /// is dropped, so a refresh always wins over an in-flight load more.
  int _generation = 0;

  /// First load: full-screen loader, full-screen error when nothing is shown.
  @override
  Future<void> load() => _loadFirstPage(LoadingStatus.loading);

  /// Pull-to-refresh: keeps the current items on screen until page 1 returns.
  /// `RefreshIndicator.onRefresh` awaits this Future to hide its spinner.
  Future<void> refresh() => _loadFirstPage(LoadingStatus.refresh);

  /// Next page, called by the list when the user scrolls near the end. Runs
  /// only when the list is settled with more pages, so repeated scroll events
  /// never send a duplicate request and a failed page is never retried just
  /// by scrolling.
  Future<void> loadMore() async {
    if (state.loading != LoadingStatus.complete || !state.hasMore) return;
    await _loadNextPage();
  }

  /// The footer's retry button after a failed next page: asks the same page.
  Future<void> retryLoadMore() async {
    if (state.loading != LoadingStatus.loadMoreError) return;
    await _loadNextPage();
  }

  Future<void> _loadFirstPage(LoadingStatus status) async {
    final generation = ++_generation;
    final previous = state;
    // Keep the error until the new result: an error view being refreshed
    // stays an error view instead of flashing the empty view.
    emit(state.copyWith(loading: status, error: state.error));
    try {
      final result = await _useCase.getOrders(
        page: Pagination.firstPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          loading: _settled(result.items, result.hasMore),
          orders: List.unmodifiable(result.items),
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      if (previous.orders.isEmpty) {
        // Nothing to show: the list renders an error view with retry.
        emit(state.copyWith(loading: LoadingStatus.error, error: error));
        return;
      }
      // Keep the list usable and report the failure once.
      emit(
        state.copyWith(
          loading: _settled(previous.orders, previous.hasMore),
          error: error,
          effect: createEffect<OrderListEffect>(
            OrderListShowErrorEffect(
              error: error,
              retryAction: OrderListRetryAction.refresh,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _loadNextPage() async {
    final generation = _generation;
    final nextPage = state.page + 1;
    emit(state.copyWith(loading: LoadingStatus.loadMore));
    try {
      final result = await _useCase.getOrders(
        page: nextPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      final merged = _appendDistinct(state.orders, result.items);
      emit(
        state.copyWith(
          loading: _settled(merged, result.hasMore),
          orders: merged,
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      // The footer shows the failure and a retry button.
      emit(state.copyWith(loading: LoadingStatus.loadMoreError, error: error));
    }
  }

  /// `complete` for an empty list keeps the empty view; `noMoreData` marks a
  /// non-empty list that reached its end.
  static LoadingStatus _settled(List<Order> items, bool hasMore) =>
      items.isNotEmpty && !hasMore
      ? LoadingStatus.noMoreData
      : LoadingStatus.complete;

  /// Page-based lists shift when rows are inserted on the server. Drop rows
  /// already shown instead of rendering duplicates.
  static List<Order> _appendDistinct(List<Order> current, List<Order> next) {
    final seen = current.map((order) => order.id).toSet();
    return List.unmodifiable([
      ...current,
      for (final order in next)
        if (seen.add(order.id)) order,
    ]);
  }
}

// ---------------------------------------------------------------------------
// lib/widget/paginated_list_view.dart  (shared; add once)
// Flutter widgets only: RefreshIndicator.adaptive for pull-to-refresh and
// scroll notifications for load more. Replaces LoadingListScreen and
// pull_to_refresh for new lists.
// ---------------------------------------------------------------------------

/// Renders a paged list from a Cubit's state. Holds no paging state itself:
/// the Cubit decides whether a request is sent.
class PaginatedListView<T> extends StatelessWidget {
  const PaginatedListView({
    super.key,
    required this.items,
    required this.status,
    required this.hasMore,
    required this.itemBuilder,
    required this.empty,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetryLoadMore,
    this.error,
    this.refreshKey,
    this.listKey,
  });

  /// Request the next page when fewer than this many pixels are left below
  /// the viewport (Flutter's default cache extent), so it is usually loaded
  /// before the footer is seen.
  static const double loadMoreExtent = 250;

  final List<T> items;
  final LoadingStatus status;
  final bool hasMore;
  final Object? error;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Shown when the settled list has no items; pull-to-refresh still works.
  final Widget empty;

  /// Retry button of the full-screen error after the first page failed.
  final VoidCallback onRetry;
  final RefreshCallback onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryLoadMore;

  /// `refreshKey.currentState?.show()` refreshes with the indicator from a
  /// button, which also gives a non-drag alternative (WCAG 2.5.7).
  final GlobalKey<RefreshIndicatorState>? refreshKey;

  /// A `PageStorageKey` keeps the scroll offset across tab switches.
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    if (status == LoadingStatus.initial || status == LoadingStatus.loading) {
      return const Center(child: _Spinner());
    }
    final error = this.error;
    final Widget body;
    if (items.isEmpty) {
      body = _FillViewport(
        child: error == null
            ? empty
            : _FirstPageError(error: error, onRetry: onRetry),
      );
    } else {
      body = NotificationListener<Notification>(
        onNotification: _onScrollMetrics,
        child: ListView.builder(
          key: listKey,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 1,
          itemBuilder: (context, index) => index < items.length
              ? itemBuilder(context, items[index])
              : _PageFooter(
                  status: status,
                  hasMore: hasMore,
                  onRetry: onRetryLoadMore,
                ),
        ),
      );
    }
    return RefreshIndicator.adaptive(
      key: refreshKey,
      onRefresh: onRefresh,
      child: body,
    );
  }

  /// Scroll updates cover scrolling; metrics notifications cover a page that
  /// does not fill the screen (tablet, landscape), which cannot be scrolled.
  bool _onScrollMetrics(Notification notification) {
    final metrics = switch (notification) {
      ScrollUpdateNotification(:final metrics, depth: 0) => metrics,
      ScrollMetricsNotification(:final metrics, depth: 0) => metrics,
      _ => null,
    };
    if (metrics != null && metrics.extentAfter < loadMoreExtent) onLoadMore();
    return false;
  }
}

/// The adaptive indicator ignores `semanticsLabel` on iOS, so label it here.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    child: const CircularProgressIndicator.adaptive(),
  );
}

/// Lets an empty or error view be pulled to refresh.
class _FillViewport extends StatelessWidget {
  const _FillViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );
}

class _FirstPageError extends StatelessWidget {
  const _FirstPageError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              ErrorMapper.parse(
                error,
                fallbackMessage: l10n.errGeneral,
                noNetworkMessage: l10n.noInternetShort,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SliButton(label: l10n.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.status,
    required this.hasMore,
    required this.onRetry,
  });

  final LoadingStatus status;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: switch (status) {
          LoadingStatus.loadMoreError => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A live region is announced politely by TalkBack/VoiceOver.
              Semantics(liveRegion: true, child: Text(l10n.loadFail)),
              const SizedBox(height: 8),
              SliButton(
                label: l10n.retry,
                variant: SliButtonVariant.outline,
                onPressed: onRetry,
              ),
            ],
          ),
          _ when !hasMore => Text(l10n.noMoreData),
          _ => const _Spinner(),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/order_list/view/order_list_screen.dart  (excerpt)
// ---------------------------------------------------------------------------

/// The list body. The real screen wraps it in `BlocProvider` created once in
/// `orderListScreenBuilder()`, calls `cubit.load()` there, and adds an app bar
/// refresh action calling `_refreshKey.currentState?.show()`.
class OrderListView extends StatefulWidget {
  const OrderListView({super.key});

  @override
  State<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<OrderListView> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderListCubit>();
    return BlocConsumer<OrderListCubit, OrderListState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final l10n = context.l10n;
        switch (state.effect?.value) {
          case OrderListShowErrorEffect(:final error):
            // Real screen: handleErrorResponse(context, error) + retry action.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ErrorMapper.parse(
                    error,
                    fallbackMessage: l10n.errGeneral,
                    noNetworkMessage: l10n.noInternetShort,
                  ),
                ),
                action: SnackBarAction(
                  label: l10n.retry,
                  onPressed: () => _refreshKey.currentState?.show(),
                ),
              ),
            );
          case null:
            break;
        }
      },
      buildWhen: (previous, current) =>
          previous.loading != current.loading ||
          previous.orders != current.orders ||
          previous.hasMore != current.hasMore ||
          previous.error != current.error,
      builder: (context, state) => PaginatedListView<Order>(
        refreshKey: _refreshKey,
        listKey: const PageStorageKey<String>('order_list'),
        items: state.orders,
        status: state.loading,
        hasMore: state.hasMore,
        error: state.error,
        onRetry: cubit.load,
        onRefresh: cubit.refresh,
        onLoadMore: cubit.loadMore,
        onRetryLoadMore: cubit.retryLoadMore,
        // Real screen: a localized empty message.
        empty: const Text('empty'),
        itemBuilder: (context, order) => SizedBox(
          key: ValueKey(order.id),
          height: 64,
          child: Text(order.code),
        ),
      ),
    );
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  group('PageResult.fromResponse', () {
    test('uses totalResults when the server sends it', () {
      final page2 = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(
          page: 2,
          perPage: 20,
          totalResults: 45,
          data: List.filled(20, 0),
        ),
        page: 2,
        pageSize: 20,
      );
      final page3 = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(
          page: 3,
          perPage: 20,
          totalResults: 45,
          data: List.filled(5, 0),
        ),
        page: 3,
        pageSize: 20,
      );

      expect(page2.hasMore, isTrue);
      expect(page3.hasMore, isFalse);
    });

    test('falls back to "a full page means maybe more"', () {
      final full = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(data: List.filled(20, 0)),
        page: 1,
        pageSize: 20,
      );
      final short = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(data: List.filled(3, 0)),
        page: 1,
        pageSize: 20,
      );

      expect(full.hasMore, isTrue);
      expect(full.page, 1);
      expect(short.hasMore, isFalse);
    });

    test('treats a null data array as an empty last page', () {
      final result = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(),
        page: 1,
        pageSize: 20,
      );

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('an empty page ends the list even if totalResults says more', () {
      final result = PageResult<int>.fromResponse(
        BaseListResponseModel<int>(
          page: 3,
          perPage: 20,
          totalResults: 100,
          data: const [],
        ),
        page: 3,
        pageSize: 20,
      );

      expect(result.hasMore, isFalse);
    });
  });

  group('data source and repository', () {
    test('send page/perPage and parse BaseListResponseModel', () async {
      final api = _FakeApiHandler({
        'page': 2,
        'perPage': 20,
        'totalResults': 21,
        'data': [
          {'id': 'o-21', 'code': 'ORD-21'},
        ],
      });
      final useCase = OrderUseCase(
        OrderRepoImpl(OrderRemoteDataSourceImpl(api)),
      );

      final result = await useCase.getOrders(page: 2, pageSize: 20);

      expect(api.path, '/orders');
      expect(api.queryParameters, {'page': 2, 'perPage': 20});
      expect(result.items.single.code, 'ORD-21');
      expect(result.page, 2);
      expect(result.hasMore, isFalse);
    });
  });

  group('OrderListCubit', () {
    late _FakeOrderRepo repo;
    late OrderListCubit cubit;

    setUp(() {
      repo = _FakeOrderRepo(total: 45);
      cubit = OrderListCubit(OrderUseCase(repo));
    });

    tearDown(() => cubit.close());

    test('first load shows the full-screen loader, then page 1', () async {
      final states = await _statuses(cubit, cubit.load);

      expect(states, [LoadingStatus.loading, LoadingStatus.complete]);
      expect(cubit.state.orders, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isTrue);
    });

    test('load more appends the next page until noMoreData', () async {
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.orders, hasLength(40));
      expect(cubit.state.loading, LoadingStatus.complete);

      await cubit.loadMore();
      expect(cubit.state.orders, hasLength(45));
      expect(cubit.state.loading, LoadingStatus.noMoreData);
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(repo.requestedPages, [1, 2, 3]);
    });

    test('a second load more while one is in flight sends nothing', () async {
      await cubit.load();
      repo.hold = true;

      final first = cubit.loadMore();
      final second = cubit.loadMore();
      repo.release();
      await Future.wait([first, second]);

      expect(repo.requestedPages, [1, 2]);
      expect(cubit.state.orders, hasLength(40));
    });

    test('a failed page is retried by the footer, not by scrolling', () async {
      await cubit.load();
      repo.failNext = NetworkIssueException();

      await cubit.loadMore();
      expect(cubit.state.loading, LoadingStatus.loadMoreError);
      expect(cubit.state.orders, hasLength(20));
      expect(cubit.state.effect, isNull);

      await cubit.loadMore();
      expect(repo.requestedPages, [1, 2]);

      await cubit.retryLoadMore();
      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.orders, hasLength(40));
      expect(repo.requestedPages, [1, 2, 2]);
    });

    test('refresh replaces the list and reopens the footer', () async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
      expect(cubit.state.hasMore, isFalse);

      final states = await _statuses(cubit, cubit.refresh);

      expect(states, [LoadingStatus.refresh, LoadingStatus.complete]);
      expect(cubit.state.orders, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isTrue);
    });

    test('refresh keeps items on screen while it runs', () async {
      await cubit.load();
      repo.hold = true;

      final refreshing = cubit.refresh();
      expect(cubit.state.loading, LoadingStatus.refresh);
      expect(cubit.state.orders, hasLength(20));
      repo.release();
      await refreshing;
    });

    test('a refresh drops the result of an older load more', () async {
      await cubit.load();
      repo.hold = true;
      final loadingMore = cubit.loadMore();
      final refreshing = cubit.refresh();

      repo.release();
      await Future.wait([loadingMore, refreshing]);

      expect(cubit.state.orders, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.loading, LoadingStatus.complete);
    });

    test('rows shifted by a server insert are not shown twice', () async {
      await cubit.load();
      repo.shiftBy = 1;

      await cubit.loadMore();

      final ids = cubit.state.orders.map((o) => o.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, hasLength(39));
    });

    test(
      'first load failure with nothing on screen is an error state',
      () async {
        repo.failNext = NetworkIssueException();

        await cubit.load();

        expect(cubit.state.loading, LoadingStatus.error);
        expect(cubit.state.error, isA<NetworkIssueException>());
        expect(cubit.state.effect, isNull);
      },
    );

    test('refresh failure keeps the list and emits one error effect', () async {
      await cubit.load();
      final error = NetworkIssueException();
      repo.failNext = error;

      await cubit.refresh();

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.orders, hasLength(20));
      final effect = cubit.state.effect!.value as OrderListShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, OrderListRetryAction.refresh);
    });

    test('an empty first page is complete with no items', () async {
      repo = _FakeOrderRepo(total: 0);
      await cubit.close();
      cubit = OrderListCubit(OrderUseCase(repo));

      await cubit.load();

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.hasMore, isFalse);
    });

    test('a response that arrives after close is ignored', () async {
      repo.hold = true;
      final loading = cubit.load();
      await cubit.close();
      repo.release();

      await expectLater(loading, completes);
    });
  });

  group('PaginatedListView', () {
    testWidgets('shows page 1 and loads the next page near the end', (
      tester,
    ) async {
      final repo = _FakeOrderRepo(total: 45);
      final cubit = await _pumpList(tester, repo);

      expect(find.text('ORD-0'), findsOneWidget);
      expect(repo.requestedPages, [1]);

      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();
      await tester.pump();

      expect(repo.requestedPages, [1, 2]);
      expect(cubit.state.orders, hasLength(40));
    });

    testWidgets('a page shorter than the screen loads the next one', (
      tester,
    ) async {
      final repo = _FakeOrderRepo(total: 45, servedPageSize: 3);
      final cubit = await _pumpList(tester, repo);
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      // Filled the screen, then stopped while more pages remain.
      expect(repo.requestedPages.length, greaterThan(1));
      expect(repo.requestedPages.length, lessThan(15));
      expect(cubit.state.hasMore, isTrue);
    });

    testWidgets('a failed next page shows retry in the footer', (tester) async {
      final repo = _FakeOrderRepo(total: 45);
      final cubit = await _pumpList(tester, repo);
      repo.failNext = NetworkIssueException();

      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();
      await tester.pump();
      expect(cubit.state.loading, LoadingStatus.loadMoreError);
      expect(find.text('Fail', skipOffstage: false), findsOneWidget);

      await tester.ensureVisible(find.text('Retry'));
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(repo.requestedPages, [1, 2, 2]);
      expect(cubit.state.orders, hasLength(40));
    });

    testWidgets('the empty view can be pulled to refresh', (tester) async {
      final repo = _FakeOrderRepo(total: 0);
      await _pumpList(tester, repo);
      expect(find.text('empty'), findsOneWidget);

      await tester.fling(find.text('empty'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(repo.requestedPages, [1, 1]);
    });

    testWidgets('a failed first page shows the error and retries', (
      tester,
    ) async {
      final repo = _FakeOrderRepo(total: 45)
        ..failNext = NetworkIssueException();
      await _pumpList(tester, repo);
      expect(find.text('No internet connection found.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(find.text('ORD-0'), findsOneWidget);
      expect(repo.requestedPages, [1, 1]);
    });
  });
}

/// Records the list status of every state [action] emits. Bloc delivers
/// stream events asynchronously, so wait one event-loop turn before reading.
Future<List<LoadingStatus>> _statuses(
  OrderListCubit cubit,
  Future<void> Function() action,
) async {
  final statuses = <LoadingStatus>[];
  final sub = cubit.stream.listen((s) => statuses.add(s.loading));
  await action();
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return statuses;
}

/// Pumps the screen, runs the first load and renders its result.
Future<OrderListCubit> _pumpList(
  WidgetTester tester,
  _FakeOrderRepo repo,
) async {
  final cubit = OrderListCubit(OrderUseCase(repo));
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(value: cubit, child: const OrderListView()),
      ),
    ),
  );
  await cubit.load();
  await tester.pump();
  return cubit;
}

class _FakeOrderRepo implements OrderRepo {
  _FakeOrderRepo({required this.total, this.servedPageSize});

  final int total;

  /// A server page size that differs from the requested one.
  final int? servedPageSize;
  final List<int> requestedPages = [];
  Object? failNext;
  bool hold = false;
  int shiftBy = 0;
  final List<Completer<void>> _held = [];

  void release() {
    hold = false;
    for (final gate in _held) {
      gate.complete();
    }
    _held.clear();
  }

  @override
  Future<BaseListResponse<Order>> getOrders({
    required int page,
    required int pageSize,
  }) async {
    requestedPages.add(page);
    if (hold) {
      final gate = Completer<void>();
      _held.add(gate);
      await gate.future;
    }
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    final size = servedPageSize ?? pageSize;
    final start = (page - 1) * size - shiftBy;
    final end = (start + size).clamp(0, total);
    return BaseListResponseModel<OrderResponseModel>(
      page: page,
      perPage: size,
      totalResults: total,
      data: [
        for (var i = start.clamp(0, total); i < end; i++)
          OrderResponseModel(id: 'o-$i', code: 'ORD-$i'),
      ],
    );
  }
}

/// Parses the JSON body the same way `ApiClient.getList` does.
class _FakeApiHandler extends Fake implements ApiHandler {
  _FakeApiHandler(this.body);

  final Map<String, dynamic> body;
  String? path;
  Map<String, dynamic>? queryParameters;

  @override
  Future<BaseListResponseModel<T>> getList<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    this.queryParameters = queryParameters;
    return BaseListResponseModel<T>.fromJson(
      body,
      (json) => parser(json as Map<String, dynamic>),
    );
  }
}
