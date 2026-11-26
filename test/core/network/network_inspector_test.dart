import 'package:bloc_cubit_base/core/network/network_inspector.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Regression: Dio allows int query values (page=1) but Uri.replace does not,
/// so the inspector used to fail every paged request before it was sent.
void main() {
  test('a request with int and list query values passes through', () async {
    final inspector = NetworkInspector(
      enabled: true,
      navigatorKey: GlobalKey<NavigatorState>(),
    );
    final options = RequestOptions(
      path: 'https://api.example.com/notifications',
      queryParameters: {
        'page': 1,
        'perPage': 20,
        'tags': [1, 'a'],
      },
    );
    final handler = _RecordingHandler();

    inspector.interceptor!.onRequest(options, handler);

    expect(handler.forwarded, same(options));
  });
}

class _RecordingHandler extends RequestInterceptorHandler {
  RequestOptions? forwarded;

  @override
  void next(RequestOptions requestOptions) => forwarded = requestOptions;
}
