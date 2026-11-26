import 'package:bloc_cubit_base/domain/entities/response/base_list_response.dart';

/// One page of a list as the domain sees it (D-0001).
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
