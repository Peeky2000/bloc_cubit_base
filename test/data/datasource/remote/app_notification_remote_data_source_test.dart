import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/datasource/remote/app_notification_remote_data_source.dart';
import 'package:bloc_cubit_base/data/datasource/remote/url_end_point.dart';
import 'package:bloc_cubit_base/data/model/response/base_list_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec 002 AC2: GET /notifications?page&perPage, parsed through getList.
void main() {
  test('sends page and perPage and parses every field', () async {
    final api = _FakeApiHandler({
      'data': [
        {
          'id': 'n-1',
          'title': 'Đơn hàng đã giao',
          'body': 'Đơn #123 đã giao thành công',
          'createdAt': '2026-11-26T08:30:00Z',
          'isRead': true,
        },
      ],
      'page': 2,
      'perPage': 20,
      'totalResults': 21,
    });

    final response = await AppNotificationRemoteDataSourceImpl(api)
        .getNotifications(page: 2, pageSize: 20);

    expect(api.path, UrlEndPoint.notification.list);
    expect(api.queryParameters, {'page': 2, 'perPage': 20});
    expect(response.totalResults, 21);
    final item = response.data!.single;
    expect(item.id, 'n-1');
    expect(item.title, 'Đơn hàng đã giao');
    expect(item.body, 'Đơn #123 đã giao thành công');
    expect(item.createdAt, DateTime.utc(2026, 11, 26, 8, 30));
    expect(item.isRead, isTrue);
  });

  test('missing optional fields fall back to their defaults', () async {
    final api = _FakeApiHandler({
      'data': [
        {'id': 'n-2', 'title': 'Chào mừng'},
      ],
    });

    final response = await AppNotificationRemoteDataSourceImpl(api)
        .getNotifications(page: 1, pageSize: 20);

    final item = response.data!.single;
    expect(item.body, '');
    expect(item.createdAt, isNull);
    expect(item.isRead, isFalse);
  });
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
