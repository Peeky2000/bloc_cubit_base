part of 'notification_list_cubit.dart';

/// `loading` (from BaseAppState) is the one list status: initial, loading,
/// refresh, loadMore, complete, noMoreData, loadMoreError or error (D-0001).
class NotificationListState extends BaseAppState<Object> {
  const NotificationListState({
    required super.loading,
    required this.notifications,
    required this.page,
    required this.hasMore,
    super.error,
    this.effect,
  });

  factory NotificationListState.initial() => const NotificationListState(
    loading: LoadingStatus.initial,
    notifications: [],
    page: Pagination.firstPage - 1,
    hasMore: true,
  );

  /// Unmodifiable. The Cubit builds a new list only when the items change, so
  /// `buildWhen` can compare by identity.
  final List<AppNotification> notifications;

  /// The last page that was loaded; 0 before the first page.
  final int page;

  /// Whether another page may exist.
  final bool hasMore;

  final UiEffect<NotificationListEffect>? effect;

  NotificationListState copyWith({
    LoadingStatus? loading,
    List<AppNotification>? notifications,
    int? page,
    bool? hasMore,
    Object? error,
    UiEffect<NotificationListEffect>? effect,
  }) {
    return NotificationListState(
      loading: loading ?? this.loading,
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    notifications,
    page,
    hasMore,
    error,
    effect,
  ];
}
