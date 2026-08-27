import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:dio/dio.dart';

/// Infrastructure-only connectivity guard.
///
/// Presentation decides how an offline failure is rendered. Interceptors never
/// navigate or access a widget context.
class NetworkInterceptor extends Interceptor {
  NetworkInterceptor(this._networkChecker);

  final NetworkChecker _networkChecker;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_networkChecker.isConnected != false) {
      handler.next(options);
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        error: NetworkIssueException(),
        type: DioExceptionType.connectionError,
        message: 'No network connection is available.',
      ),
    );
  }
}
