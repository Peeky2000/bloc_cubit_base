import 'dart:typed_data';

import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:bloc_cubit_base/data/datasource/remote/interceptor/network_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkInterceptor', () {
    test('rejects a known offline state before transport', () async {
      final checker = _NetworkCheckerStub(false);
      final adapter = _CountingAdapter();
      final dio = _createDio(checker, adapter);
      addTearDown(() async {
        dio.close(force: true);
        await checker.dispose();
      });

      Object? result;
      try {
        await dio.get<dynamic>('/protected');
      } catch (error) {
        result = error;
      }

      expect(result, isA<DioException>());
      final error = result! as DioException;
      expect(error.type, DioExceptionType.connectionError);
      expect(error.error, isA<NetworkIssueException>());
      expect(error.requestOptions.uri.path, '/protected');
      expect(adapter.requestCount, 0);
    });

    for (final state in <bool?>[null, true]) {
      test('allows ${state ?? 'unknown'} connectivity state to transport', () async {
        final checker = _NetworkCheckerStub(state);
        final adapter = _CountingAdapter();
        final dio = _createDio(checker, adapter);
        addTearDown(() async {
          dio.close(force: true);
          await checker.dispose();
        });

        final response = await dio.get<dynamic>('/protected');

        expect(response.statusCode, 200);
        expect(adapter.requestCount, 1);
      });
    }
  });
}

Dio _createDio(NetworkChecker checker, _CountingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(NetworkInterceptor(checker));
  return dio;
}

class _NetworkCheckerStub extends NetworkChecker {
  _NetworkCheckerStub(bool? state) {
    isConnected = state;
  }
}

class _CountingAdapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
