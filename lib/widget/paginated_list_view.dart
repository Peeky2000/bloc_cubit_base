import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/error_to_string_mapper.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sli_common/sli_common.dart'
    show SliButton, SliButtonVariant, SliSpacing;

/// Renders a paged list from a Cubit's state (D-0001). Holds no paging state
/// itself: the Cubit decides whether a request is sent. Flutter widgets only:
/// `RefreshIndicator.adaptive` for pull-to-refresh and scroll notifications
/// for load more.
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
      padding: EdgeInsets.all(SliSpacing.xl),
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
          SizedBox(height: SliSpacing.lg),
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
      padding: EdgeInsets.all(SliSpacing.lg),
      child: Center(
        child: switch (status) {
          LoadingStatus.loadMoreError => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A live region is announced politely by TalkBack/VoiceOver.
              Semantics(liveRegion: true, child: Text(l10n.loadFail)),
              SizedBox(height: SliSpacing.sm),
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
