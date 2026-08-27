import 'dart:async';

import 'package:bloc_cubit_base/core/extension/string_extension.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/remote/url_end_point.dart';
import 'package:bloc_cubit_base/data/model/response/base_response_model.dart';
import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:dio/dio.dart';

final List<String> _skipRefreshPaths = [
  UrlEndPoint.auth.login,
  UrlEndPoint.auth.signUp,
  UrlEndPoint.auth.refreshToken,
];

class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required this.baseUrl,
    required this.onSessionExpired,
    required this.tokenProvider,
  });

  final TokenProvider tokenProvider;
  final FutureOr<void> Function() onSessionExpired;
  final String baseUrl;

  Future<String?>? _refreshing;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    final currentAccessToken = tokenProvider.token.accessToken;
    final requestAuthorization = request.headers['Authorization'];

    try {
      final accessToken = requestAuthorization != 'Bearer $currentAccessToken'
          ? currentAccessToken
          : await _singleFlightRefresh();

      if (accessToken.isNullOrEmpty) {
        await tokenProvider.clearToken();
        await onSessionExpired();
        handler.next(err);
        return;
      }

      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await Dio().fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (refreshError) {
      await tokenProvider.clearToken();
      await onSessionExpired();
      handler.next(refreshError);
    } catch (_) {
      await tokenProvider.clearToken();
      await onSessionExpired();
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioException error) {
    final statusCode = error.response?.statusCode;
    return tokenProvider.token.accessToken.isNotNullOrEmpty &&
        !_skipRefreshPaths.contains(error.requestOptions.path) &&
        (statusCode == 401 || statusCode == 403);
  }

  Future<String?> _singleFlightRefresh() {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _refreshToken();
    _refreshing = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshing, refresh)) {
        _refreshing = null;
      }
    });
  }

  Future<String?> _refreshToken() async {
    final refreshToken = tokenProvider.token.refreshToken;
    if (refreshToken.isNullOrEmpty) {
      return null;
    }

    final response =
        await Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: const {'Content-Type': 'application/json'},
          ),
        ).post<dynamic>(
          UrlEndPoint.auth.refreshToken,
          data: {'refreshToken': refreshToken},
        );

    final parsed = BaseResponseModel<TokenResponseModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TokenResponseModel.fromJson(json as Map<String, dynamic>),
    );
    await tokenProvider.setToken(parsed.data);
    return parsed.data?.accessToken;
  }
}
