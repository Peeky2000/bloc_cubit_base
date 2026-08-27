import 'package:dio/dio.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/core/extension/string_extension.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenProvider _tokenProvider;

  AuthInterceptor(this._tokenProvider);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider.token;
    if (token.accessToken.isNotNullOrEmpty && !options.path.isUrl) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['app'] = 'user_app';
    return super.onRequest(options, handler);
  }
}
