import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/use_case/app_notification_use_case.dart';
import 'package:injectable/injectable.dart';

part 'notification_list_effect.dart';
part 'notification_list_state.dart';

/// Paged notification list (spec 002-notifications, D-0001).
@injectable
class NotificationListCubit extends BaseCubit<NotificationListState> {
  NotificationListCubit(this._useCase) : super(NotificationListState.initial());

  /// AC2: 20 per page.
  static const int pageSize = 20;

  final AppNotificationUseCase _useCase;

  /// Bumped by every first-page request. A response from an older generation
  /// is dropped, so a refresh always wins over an in-flight load more.
  int _generation = 0;

  /// AC2/AC5: first load; full-screen error when nothing is shown.
  @override
  Future<void> load() => _loadFirstPage(LoadingStatus.loading);

  /// AC3: pull-to-refresh keeps the current items until page 1 returns.
  /// `RefreshIndicator.onRefresh` awaits this Future.
  Future<void> refresh() => _loadFirstPage(LoadingStatus.refresh);

  /// AC3: next page, only when the list is settled with more pages, so
  /// repeated scroll events never send a duplicate request and a failed page
  /// is never retried just by scrolling.
  Future<void> loadMore() async {
    if (state.loading != LoadingStatus.complete || !state.hasMore) return;
    await _loadNextPage();
  }

  /// AC5: the footer's retry after a failed next page asks the same page.
  Future<void> retryLoadMore() async {
    if (state.loading != LoadingStatus.loadMoreError) return;
    await _loadNextPage();
  }

  Future<void> _loadFirstPage(LoadingStatus status) async {
    final generation = ++_generation;
    final previous = state;
    // Keep the error until the new result, so a refreshing error view does
    // not flash the empty view.
    emit(state.copyWith(loading: status, error: state.error));
    try {
      final result = await _useCase.getNotifications(
        page: Pagination.firstPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          loading: _settled(result.items, result.hasMore),
          notifications: List.unmodifiable(result.items),
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      if (previous.notifications.isEmpty) {
        emit(state.copyWith(loading: LoadingStatus.error, error: error));
        return;
      }
      emit(
        state.copyWith(
          loading: _settled(previous.notifications, previous.hasMore),
          error: error,
          effect: createEffect<NotificationListEffect>(
            NotificationListShowErrorEffect(error: error),
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
      final result = await _useCase.getNotifications(
        page: nextPage,
        pageSize: pageSize,
      );
      if (isClosed || generation != _generation) return;
      final merged = _appendDistinct(state.notifications, result.items);
      emit(
        state.copyWith(
          loading: _settled(merged, result.hasMore),
          notifications: merged,
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loading: LoadingStatus.loadMoreError, error: error));
    }
  }

  /// `complete` for an empty list keeps the empty view (AC4); `noMoreData`
  /// marks a non-empty list that reached its end (AC3).
  static LoadingStatus _settled(List<AppNotification> items, bool hasMore) =>
      items.isNotEmpty && !hasMore
      ? LoadingStatus.noMoreData
      : LoadingStatus.complete;

  /// Page-based lists shift when rows are inserted on the server; drop rows
  /// already shown instead of rendering duplicates.
  static List<AppNotification> _appendDistinct(
    List<AppNotification> current,
    List<AppNotification> next,
  ) {
    final seen = current.map((item) => item.id).toSet();
    return List.unmodifiable([
      ...current,
      for (final item in next)
        if (seen.add(item.id)) item,
    ]);
  }
}
