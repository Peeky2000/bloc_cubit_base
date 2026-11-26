import 'package:bloc_cubit_base/data/model/response/base_list_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/common/page_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-0001: PageResult decides hasMore once, so no Cubit does paging maths.
void main() {
  PageResult<int> read({
    int? page,
    int? perPage,
    int? total,
    List<int>? data,
    int requestedPage = 1,
  }) => PageResult<int>.fromResponse(
    BaseListResponseModel<int>(
      page: page,
      perPage: perPage,
      totalResults: total,
      data: data,
    ),
    page: requestedPage,
    pageSize: 20,
  );

  test('uses totalResults when the server sends it', () {
    expect(
      read(page: 2, perPage: 20, total: 45, data: List.filled(20, 0)).hasMore,
      isTrue,
    );
    expect(
      read(page: 3, perPage: 20, total: 45, data: List.filled(5, 0)).hasMore,
      isFalse,
    );
  });

  test('without totalResults a full page means maybe more', () {
    expect(read(data: List.filled(20, 0)).hasMore, isTrue);
    expect(read(data: List.filled(7, 0)).hasMore, isFalse);
  });

  test('an empty page ends the list even if totalResults says more', () {
    final result = read(page: 3, perPage: 20, total: 500, data: const []);

    expect(result.hasMore, isFalse);
    expect(result.items, isEmpty);
  });

  test('null data is an empty, finished page on the requested page', () {
    final result = read(requestedPage: 4);

    expect(result.items, isEmpty);
    expect(result.page, 4);
    expect(result.hasMore, isFalse);
  });
}
