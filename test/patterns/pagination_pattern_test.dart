// Reference implementation: pagination with pull-to-refresh and load more.
//
// Pattern: .agents/skills/flutter-patterns/references/pagination.md
// Decision: docs/decisions/D-0001-phan-trang-danh-sach-keo-de-lam-moi-va-tai-them.md
//
// Every section below is one file of a real feature. Copy the shape into the
// path in the section header, rename `Order` to the feature's entity, and keep
// the behavior the tests pin. The code here compiles against the real base
// types (BaseCubit, BaseAppState, BaseAppListState, LoadingListModel,
// BaseListResponseModel, ApiHandler) so a change to the base breaks it.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_list_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/model/response/base_list_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/response/base_list_response.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/widget/loading_list_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  /// paging arithmetic. Uses `totalResults` when the server sends it and
  /// otherwise treats a full page as "there may be more".
  factory PageResult.fromResponse(
    BaseListResponse<T> response, {
    required int page,
    required int pageSize,
  }) {
    final items = response.data ?? <T>[];
    final servedPage = response.page ?? page;
    final servedSize = response.perPage ?? pageSize;
    final total = response.totalResults;
    final hasMore = total != null
        ? servedPage * servedSize < total
        : items.length >= servedSize;
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

/// `implements BaseAppListState<Order>` lets the existing `LoadingListScreen`
/// render this state. `loading` is always `orders.loading`, so there is one
/// source of truth for the list status.
class OrderListState extends BaseAppState<Object>
    implements BaseAppListState<Order> {
  OrderListState({
    required this.orders,
    required this.page,
    required this.hasMore,
    super.error,
    this.effect,
  }) : super(loading: orders.loading);

  factory OrderListState.initial() => OrderListState(
    orders: LoadingListModel<Order>(),
    page: Pagination.firstPage - 1,
    hasMore: true,
  );

  /// Items plus list status: loading, refresh, loadMore, complete,
  /// noMoreData, loadMoreError or error.
  final LoadingListModel<Order> orders;

  /// The last page that was loaded; 0 before the first page.
  final int page;

  /// Whether another page may exist.
  final bool hasMore;

  final UiEffect<OrderListEffect>? effect;

  @override
  LoadingListModel<Order> get loadingListModel => orders;

  OrderListState copyWith({
    LoadingListModel<Order>? orders,
    int? page,
    bool? hasMore,
    Object? error,
    UiEffect<OrderListEffect>? effect,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [orders, page, hasMore, error, effect];
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
  Future<void> refresh() => _loadFirstPage(LoadingStatus.refresh);

  Future<void> _loadFirstPage(LoadingStatus status) async {
    final generation = ++_generation;
    final previous = state;
    emit(state.copyWith(orders: _withStatus(status)));
    try {
      final result = await _useCase.getOrders(
        page: Pagination.firstPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          orders: LoadingListModel<Order>(
            loading: _settled(result.items, result.hasMore),
            data: result.items,
          ),
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      if (previous.orders.data.isEmpty) {
        // Nothing to show: the Screen renders an error view with retry.
        emit(
          state.copyWith(
            orders: _withStatus(LoadingStatus.error),
            error: error,
          ),
        );
        return;
      }
      // Keep the list usable and report the failure once.
      emit(
        state.copyWith(
          orders: _withStatus(_settled(previous.orders.data, previous.hasMore)),
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

  /// Next page. Ignored unless the list is settled with more pages, so a
  /// fast scroll or a second footer trigger never sends a duplicate request.
  Future<void> loadMore() async {
    final status = state.orders.loading;
    final canLoad =
        status == LoadingStatus.complete ||
        status == LoadingStatus.loadMoreError;
    if (!state.hasMore || !canLoad) return;

    final generation = _generation;
    final nextPage = state.page + 1;
    emit(state.copyWith(orders: _withStatus(LoadingStatus.loadMore)));
    try {
      final result = await _useCase.getOrders(
        page: nextPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      final merged = _appendDistinct(state.orders.data, result.items);
      emit(
        state.copyWith(
          orders: LoadingListModel<Order>(
            loading: _settled(merged, result.hasMore),
            data: merged,
          ),
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      // The footer shows "failed"; pulling up again retries the same page.
      emit(
        state.copyWith(
          orders: _withStatus(LoadingStatus.loadMoreError),
          error: error,
        ),
      );
    }
  }

  LoadingListModel<Order> _withStatus(LoadingStatus status) =>
      LoadingListModel<Order>(loading: status, data: state.orders.data);

  /// `complete` for an empty list keeps the empty view of LoadingListScreen;
  /// `noMoreData` marks a non-empty list that reached its end.
  static LoadingStatus _settled(List<Order> items, bool hasMore) =>
      items.isNotEmpty && !hasMore
      ? LoadingStatus.noMoreData
      : LoadingStatus.complete;

  /// Page-based lists shift when rows are inserted on the server. Drop rows
  /// already shown instead of rendering duplicates.
  static List<Order> _appendDistinct(List<Order> current, List<Order> next) {
    final seen = current.map((order) => order.id).toSet();
    return [
      ...current,
      for (final order in next)
        if (seen.add(order.id)) order,
    ];
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/order_list/view/order_list_screen.dart  (excerpt)
// ---------------------------------------------------------------------------

/// Drives the pull_to_refresh indicators from state. Call it from the
/// `listener` of `LoadingListScreen`; the Cubit never sees the controller.
void syncRefreshController(RefreshController controller, OrderListState state) {
  final status = state.orders.loading;
  if (controller.isRefresh && status != LoadingStatus.refresh) {
    if (state.error == null) {
      controller.refreshCompleted(resetFooterState: true);
    } else {
      controller.refreshFailed();
    }
  }
  switch (status) {
    case LoadingStatus.loading ||
        LoadingStatus.refresh ||
        LoadingStatus.loadMore:
      return;
    case LoadingStatus.loadMoreError:
      controller.loadFailed();
    case _ when !state.hasMore:
      controller.loadNoData();
    case _ when controller.isLoading:
      controller.loadComplete();
    case _:
      return;
  }
}

/// The list body. The real screen wraps it in `BlocProvider` created once in
/// `orderListScreenBuilder()` and calls `cubit.load()` there.
class OrderListView extends StatefulWidget {
  const OrderListView({super.key});

  @override
  State<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<OrderListView> {
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderListCubit>();
    return BlocListener<OrderListCubit, OrderListState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        switch (state.effect?.value) {
          case OrderListShowErrorEffect():
            // Real screen: handleErrorResponse(context, error) + retry action.
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.loadFail)));
          case null:
            break;
        }
      },
      child: LoadingListScreen<OrderListCubit, OrderListState>(
        refreshController: _refreshController,
        loadingStyle: LoadingListStyle.android,
        refreshData: cubit.refresh,
        loadMore: cubit.loadMore,
        listener: (_, state) =>
            syncRefreshController(_refreshController, state),
        emptyWidget: const Center(child: Text('empty')),
        builder: (context, state, index) {
          final order = state.orders.data[index];
          return SizedBox(
            key: ValueKey(order.id),
            height: 64,
            child: Text(order.code),
          );
        },
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
      expect(cubit.state.orders.data, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.loading, cubit.state.orders.loading);
    });

    test('load more appends the next page until noMoreData', () async {
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.orders.data, hasLength(40));
      expect(cubit.state.orders.loading, LoadingStatus.complete);

      await cubit.loadMore();
      expect(cubit.state.orders.data, hasLength(45));
      expect(cubit.state.orders.loading, LoadingStatus.noMoreData);
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
      expect(cubit.state.orders.data, hasLength(40));
    });

    test('load more failure keeps items and retries the same page', () async {
      await cubit.load();
      repo.failNext = NetworkIssueException();

      await cubit.loadMore();
      expect(cubit.state.orders.loading, LoadingStatus.loadMoreError);
      expect(cubit.state.orders.data, hasLength(20));
      expect(cubit.state.effect, isNull);

      await cubit.loadMore();
      expect(cubit.state.orders.loading, LoadingStatus.complete);
      expect(cubit.state.orders.data, hasLength(40));
      expect(repo.requestedPages, [1, 2, 2]);
    });

    test('refresh replaces the list and reopens the footer', () async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
      expect(cubit.state.hasMore, isFalse);

      final states = await _statuses(cubit, cubit.refresh);

      expect(states, [LoadingStatus.refresh, LoadingStatus.complete]);
      expect(cubit.state.orders.data, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isTrue);
    });

    test('refresh keeps items on screen while it runs', () async {
      await cubit.load();
      repo.hold = true;

      final refreshing = cubit.refresh();
      expect(cubit.state.orders.loading, LoadingStatus.refresh);
      expect(cubit.state.orders.data, hasLength(20));
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

      expect(cubit.state.orders.data, hasLength(20));
      expect(cubit.state.page, 1);
      expect(cubit.state.orders.loading, LoadingStatus.complete);
    });

    test('rows shifted by a server insert are not shown twice', () async {
      await cubit.load();
      repo.shiftBy = 1;

      await cubit.loadMore();

      final ids = cubit.state.orders.data.map((o) => o.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, hasLength(39));
    });

    test(
      'first load failure with nothing on screen is an error state',
      () async {
        repo.failNext = NetworkIssueException();

        await cubit.load();

        expect(cubit.state.orders.loading, LoadingStatus.error);
        expect(cubit.state.error, isA<NetworkIssueException>());
        expect(cubit.state.effect, isNull);
      },
    );

    test('refresh failure keeps the list and emits one error effect', () async {
      await cubit.load();
      final error = NetworkIssueException();
      repo.failNext = error;

      await cubit.refresh();

      expect(cubit.state.orders.loading, LoadingStatus.complete);
      expect(cubit.state.orders.data, hasLength(20));
      final effect = cubit.state.effect!.value as OrderListShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, OrderListRetryAction.refresh);
    });

    test('an empty first page is complete with no items', () async {
      repo = _FakeOrderRepo(total: 0);
      await cubit.close();
      cubit = OrderListCubit(OrderUseCase(repo));

      await cubit.load();

      expect(cubit.state.orders.loading, LoadingStatus.complete);
      expect(cubit.state.orders.data, isEmpty);
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

  group('screen wiring', () {
    testWidgets('syncRefreshController maps state to the indicators', (
      tester,
    ) async {
      final controller = RefreshController();
      addTearDown(controller.dispose);
      // Footer changes land in a post-frame callback of pull_to_refresh.
      Future<void> nextFrame() {
        tester.binding.scheduleFrame();
        return tester.pump();
      }

      final settled = OrderListState.initial().copyWith(
        orders: LoadingListModel<Order>(loading: LoadingStatus.complete),
      );

      controller.headerMode!.value = RefreshStatus.refreshing;
      syncRefreshController(controller, settled);
      expect(controller.headerStatus, RefreshStatus.completed);

      controller.headerMode!.value = RefreshStatus.refreshing;
      syncRefreshController(controller, settled.copyWith(error: 'offline'));
      expect(controller.headerStatus, RefreshStatus.failed);

      controller.footerMode!.value = LoadStatus.loading;
      syncRefreshController(controller, settled);
      await nextFrame();
      expect(controller.footerStatus, LoadStatus.idle);

      syncRefreshController(
        controller,
        settled.copyWith(
          orders: LoadingListModel<Order>(loading: LoadingStatus.loadMoreError),
        ),
      );
      await nextFrame();
      expect(controller.footerStatus, LoadStatus.failed);

      syncRefreshController(
        controller,
        settled.copyWith(
          hasMore: false,
          orders: LoadingListModel<Order>(loading: LoadingStatus.noMoreData),
        ),
      );
      await nextFrame();
      expect(controller.footerStatus, LoadStatus.noMore);
    });

    testWidgets('LoadingListScreen renders the first page', (tester) async {
      final cubit = OrderListCubit(OrderUseCase(_FakeOrderRepo(total: 45)));
      addTearDown(cubit.close);
      await tester.pumpWidget(_app(cubit));
      await cubit.load();
      await tester.pump();

      expect(find.text('ORD-0'), findsOneWidget);
      expect(find.text('empty'), findsNothing);
    });

    testWidgets('LoadingListScreen renders the empty view', (tester) async {
      final cubit = OrderListCubit(OrderUseCase(_FakeOrderRepo(total: 0)));
      addTearDown(cubit.close);
      await tester.pumpWidget(_app(cubit));
      await cubit.load();
      await tester.pump();

      expect(find.text('empty'), findsOneWidget);
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
  final sub = cubit.stream.listen((s) => statuses.add(s.orders.loading));
  await action();
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return statuses;
}

Widget _app(OrderListCubit cubit) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: BlocProvider.value(value: cubit, child: const OrderListView()),
  ),
);

class _FakeOrderRepo implements OrderRepo {
  _FakeOrderRepo({required this.total});

  final int total;
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
    final start = (page - 1) * pageSize - shiftBy;
    final end = (start + pageSize).clamp(0, total);
    return BaseListResponseModel<OrderResponseModel>(
      page: page,
      perPage: pageSize,
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
