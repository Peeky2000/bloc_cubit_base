import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/presentation/notification_list/cubit/notification_list_cubit.dart';
import 'package:bloc_cubit_base/widget/paginated_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sli_common/sli_common.dart' show SliIcons, SliSpacing;

/// Route builder: the only place this feature resolves from the DI graph.
Widget notificationListScreenBuilder() => BlocProvider<NotificationListCubit>(
  create: (_) => Injector.getIt.get<NotificationListCubit>()..load(),
  child: const NotificationListScreen(),
);

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationListCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationTitle),
        actions: [
          // Non-drag alternative to pull-to-refresh (WCAG 2.5.7).
          IconButton(
            tooltip: context.l10n.retry,
            icon: const Icon(SliIcons.refresh),
            onPressed: () => _refreshKey.currentState?.show(),
          ),
        ],
      ),
      body: BlocConsumer<NotificationListCubit, NotificationListState>(
        listenWhen: (previous, current) => previous.effect != current.effect,
        listener: (context, state) {
          switch (state.effect?.value) {
            case NotificationListShowErrorEffect(:final error):
              handleErrorResponse(
                context,
                error,
                onRetry: () async => _refreshKey.currentState?.show(),
              );
            case null:
              break;
          }
        },
        buildWhen: (previous, current) =>
            previous.loading != current.loading ||
            previous.notifications != current.notifications ||
            previous.hasMore != current.hasMore ||
            previous.error != current.error,
        builder: (context, state) => PaginatedListView<AppNotification>(
          refreshKey: _refreshKey,
          listKey: const PageStorageKey<String>('notification_list'),
          items: state.notifications,
          status: state.loading,
          hasMore: state.hasMore,
          error: state.error,
          onRetry: cubit.load,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          onRetryLoadMore: cubit.retryLoadMore,
          empty: Text(context.l10n.notificationEmpty),
          itemBuilder: (context, item) =>
              _NotificationTile(key: ValueKey(item.id), notification: item),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({super.key, required this.notification});

  static final DateFormat _timeFormat = DateFormat('dd/MM/yyyy HH:mm');

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final createdAt = notification.createdAt;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SliSpacing.lg,
        vertical: SliSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SliSpacing.xs),
            child: Icon(SliIcons.notification, color: App.appColor?.iconColor),
          ),
          SizedBox(width: SliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: App.appStyle?.semiBold16?.copyWith(
                    color: App.appColor?.textColor,
                  ),
                ),
                SizedBox(height: SliSpacing.xxs),
                Text(
                  notification.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: App.appStyle?.medium14?.copyWith(
                    color: App.appColor?.textColorLight,
                  ),
                ),
                if (createdAt != null) ...[
                  SizedBox(height: SliSpacing.xxs),
                  Text(
                    _timeFormat.format(createdAt.toLocal()),
                    style: App.appStyle?.medium12?.copyWith(
                      color: App.appColor?.textColorLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!notification.isRead)
            // A decorative dot has no text of its own; container: true gives
            // it a node so screen readers say "unread".
            Semantics(
              container: true,
              label: context.l10n.notificationUnread,
              child: Padding(
                padding: EdgeInsets.only(
                  left: SliSpacing.sm,
                  top: SliSpacing.sm,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: App.appColor?.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: SliSpacing.sm),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
