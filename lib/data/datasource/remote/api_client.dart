import 'dart:io';

import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/data/datasource/remote/interceptor/curl_interceptor.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:delivery_go/core/error/exception.dart';
import 'package:delivery_go/data/datasource/local/token_provider.dart';
import 'package:delivery_go/data/datasource/remote/interceptor/auth_interceotor.dart';
import 'package:delivery_go/data/datasource/remote/interceptor/network_interceptor.dart';
import 'package:delivery_go/data/datasource/remote/interceptor/session_interceptor.dart';
import 'package:delivery_go/data/model/response/base_list_response_model.dart';
import 'package:delivery_go/data/model/response/base_response_model.dart';

typedef ApiResponseToModelParser<T> = T Function(Map<String, dynamic> json);

abstract class ApiHandler {
  // parser JSON data {} => Object
  Future<BaseResponseModel<T>> post<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  // parser JSON data {} => Object
  Future<BaseResponseModel<T>> get<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  // parser JSON data [] => List Object
  Future<BaseListResponseModel<T>> getList<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  // parser JSON data {} => Object
  Future<BaseResponseModel<T>> put<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  // parser JSON data {} => Object
  Future<BaseResponseModel<T>> patch<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  // parser JSON data {} => Object
  Future<BaseResponseModel<T>> delete<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });
}

class ApiClient implements ApiHandler {
  Dio _dio = Dio();
  final TokenProvider tokenProvider;
  final String baseUrl;
  String get baseUrlWithFormat {
    if (baseUrl.contains('localhost') && Platform.isAndroid) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return baseUrl;
  }

  ApiClient({required this.baseUrl, required this.tokenProvider}) {
    init();
  }

  void init() {
    _dio = Dio(BaseOptions(
        followRedirects: false,
        baseUrl: baseUrlWithFormat,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30)));
    _dio.interceptors.addAll([
      NetworkInterceptor(),
      AuthInterceptor(tokenProvider),
      SessionInterceptor(
          baseUrl: baseUrlWithFormat,
          tokenProvider: tokenProvider,
          onSessionExpired: () {
            Injector.getIt.get<AppController>().showSessionEnd();
          }),
      CurlInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          responseHeader: true,
          requestHeader: true,
        ),
    ]);
  }

  @override
  Future<BaseResponseModel<T>> post<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! < 300 &&
          response.data.toString().isEmpty) {
        return BaseResponseModel<T>(data: null, message: 'Empty Response');
      }
      return BaseResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  @override
  Future<BaseResponseModel<T>> get<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! < 300 &&
          response.data.toString().isEmpty) {
        return BaseResponseModel<T>(data: null, message: 'Empty Response');
      }
      return BaseResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  @override
  Future<BaseResponseModel<T>> delete<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.delete(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! < 300 &&
          response.data.toString().isEmpty) {
        return BaseResponseModel<T>(data: null, message: 'Empty Response');
      }
      return BaseResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  @override
  Future<BaseResponseModel<T>> put<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.put(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! < 300 &&
          response.data.toString().isEmpty) {
        return BaseResponseModel<T>(data: null, message: 'Empty Response');
      }
      return BaseResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  @override
  Future<BaseResponseModel<T>> patch<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.patch(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! < 300 &&
          response.data.toString().isEmpty) {
        return BaseResponseModel<T>(data: null, message: 'Empty Response');
      }
      return BaseResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  @override
  Future<BaseListResponseModel<T>> getList<T>(
    String path, {
    required ApiResponseToModelParser<T> parser,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _remapError(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return BaseListResponseModel<T>.fromJson(
          response.data, (json) => parser(json as Map<String, dynamic>));
    });
  }

  Future<T> _remapError<T>(ValueGetter<Future<T>> func) async {
    try {
      return await func();
    } catch (e) {
      throw await _apiErrorToInternalError(e);
    }
  }

  Future<dynamic> _apiErrorToInternalError(e) async {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          (e.type == DioExceptionType.unknown && e.error is SocketException)) {
        return NetworkIssueException();
      }
      return ServerException(e);
    }
    return e;
  }
}
