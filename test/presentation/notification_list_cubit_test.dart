import 'dart:async';

import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/entities/common/page_result.dart';
import 'package:bloc_cubit_base/domain/use_case/app_notification_use_case.dart';
import 'package:bloc_cubit_base/presentation/notification_list/cubit/notification_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Spec: docs/specs/002-notifications/tech.md, section 15; rules of D-0001.
void main() {
  late _MockUseCase useCase;
  late NotificationListCubit cubit;

  setUp(() {
    useCase = _MockUseCase();
    cubit = NotificationListCubit(useCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  void stubPage(
    int page,
    Future<PageResult<AppNotification>> Function() answer,
  ) => when(
    () => useCase.getNotifications(
      page: page,
      pageSize: NotificationListCubit.pageSize,
    ),
  ).thenAnswer((_) => answer());

  test('AC2: first load shows the first page', () async {
    stubPage(1, () async => _page(1, ['a', 'b'], hasMore: true));

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.notifications.map((n) => n.id), ['a', 'b']);
    expect(cubit.state.page, 1);
  });

  test('AC4: an empty first page settles as empty', () async {
    stubPage(1, () async => _page(1, [], hasMore: false));

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.notifications, isEmpty);
  });

  test('AC3: loads pages until there are no more, then stops', () async {
    stubPage(1, () async => _page(1, ['a'], hasMore: true));
    stubPage(2, () async => _page(2, ['b'], hasMore: false));

    await cubit.load();
    await cubit.loadMore();
    await cubit.loadMore();

    expect(cubit.state.loading, LoadingStatus.noMoreData);
    expect(cubit.state.notifications.map((n) => n.id), ['a', 'b']);
    verify(
      () => useCase.getNotifications(page: 2, pageSize: any(named: 'pageSize')),
    ).called(1);
    verifyNever(
      () => useCase.getNotifications(page: 3, pageSize: any(named: 'pageSize')),
    );
  });

  test(
    'AC3: a second load more while one is in flight sends nothing',
    () async {
      final pending = Completer<PageResult<AppNotification>>();
      stubPage(1, () async => _page(1, ['a'], hasMore: true));
      stubPage(2, () => pending.future);
      await cubit.load();

      final first = cubit.loadMore();
      await cubit.loadMore();
      pending.complete(_page(2, ['b'], hasMore: true));
      await first;

      verify(
        () =>
            useCase.getNotifications(page: 2, pageSize: any(named: 'pageSize')),
      ).called(1);
    },
  );

  test('AC3: rows already shown are not added twice', () async {
    stubPage(1, () async => _page(1, ['a', 'b'], hasMore: true));
    stubPage(2, () async => _page(2, ['b', 'c'], hasMore: false));

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.notifications.map((n) => n.id), ['a', 'b', 'c']);
  });

  test(
    'AC3: refresh replaces the list and wins over a pending load more',
    () async {
      final staleNextPage = Completer<PageResult<AppNotification>>();
      var firstPageCalls = 0;
      when(
        () =>
            useCase.getNotifications(page: 1, pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async {
        firstPageCalls++;
        return firstPageCalls == 1
            ? _page(1, ['a'], hasMore: true)
            : _page(1, ['new'], hasMore: false);
      });
      stubPage(2, () => staleNextPage.future);
      await cubit.load();

      final loadingMore = cubit.loadMore();
      await cubit.refresh();
      staleNextPage.complete(_page(2, ['stale'], hasMore: true));
      await loadingMore;

      expect(cubit.state.notifications.map((n) => n.id), ['new']);
      expect(cubit.state.loading, LoadingStatus.noMoreData);
    },
  );

  test('AC5: a failed first load shows an error, retry loads again', () async {
    var calls = 0;
    when(
      () => useCase.getNotifications(page: 1, pageSize: any(named: 'pageSize')),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return _page(1, ['a'], hasMore: false);
    });

    await cubit.load();
    expect(cubit.state.loading, LoadingStatus.error);
    expect(cubit.state.error, isA<StateError>());

    await cubit.load();
    expect(cubit.state.loading, LoadingStatus.noMoreData);
    expect(cubit.state.error, isNull);
  });

  test(
    'AC5: a failed next page keeps the list; only retry asks again',
    () async {
      var secondPageCalls = 0;
      stubPage(1, () async => _page(1, ['a'], hasMore: true));
      when(
        () =>
            useCase.getNotifications(page: 2, pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async {
        secondPageCalls++;
        if (secondPageCalls == 1) throw StateError('timeout');
        return _page(2, ['b'], hasMore: false);
      });
      await cubit.load();

      await cubit.loadMore();
      expect(cubit.state.loading, LoadingStatus.loadMoreError);
      expect(cubit.state.notifications.map((n) => n.id), ['a']);

      await cubit.loadMore();
      expect(secondPageCalls, 1, reason: 'scrolling must not retry');

      await cubit.retryLoadMore();
      expect(secondPageCalls, 2);
      expect(cubit.state.notifications.map((n) => n.id), ['a', 'b']);
    },
  );

  test(
    'AC5: a failed refresh keeps the list and reports the error once',
    () async {
      var calls = 0;
      when(
        () =>
            useCase.getNotifications(page: 1, pageSize: any(named: 'pageSize')),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 2) throw StateError('server down');
        return _page(1, ['a'], hasMore: true);
      });
      await cubit.load();

      await cubit.refresh();

      expect(cubit.state.notifications.map((n) => n.id), ['a']);
      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.effect?.value, isA<NotificationListShowErrorEffect>());
    },
  );

  test('a response after close is ignored', () async {
    final pending = Completer<PageResult<AppNotification>>();
    stubPage(1, () => pending.future);

    final loading = cubit.load();
    final beforeClose = cubit.state;
    await cubit.close();
    pending.complete(_page(1, ['a'], hasMore: false));
    await loading;

    expect(cubit.state, beforeClose);
  });
}

PageResult<AppNotification> _page(
  int page,
  List<String> ids, {
  required bool hasMore,
}) => PageResult<AppNotification>(
  items: [for (final id in ids) _Notification(id)],
  page: page,
  hasMore: hasMore,
);

class _Notification implements AppNotification {
  _Notification(this.id);

  @override
  final String id;

  @override
  String get title => 'Title $id';

  @override
  String get body => 'Body $id';

  @override
  DateTime? get createdAt => null;

  @override
  bool get isRead => false;
}

class _MockUseCase extends Mock implements AppNotificationUseCase {}
