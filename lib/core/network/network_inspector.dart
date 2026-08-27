import 'dart:convert';

import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice/model/alice_http_call.dart';
import 'package:alice/model/alice_http_error.dart';
import 'package:alice/model/alice_http_request.dart';
import 'package:alice/model/alice_http_response.dart';
import 'package:bloc_cubit_base/core/network/network_redactor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NetworkInspector {
  NetworkInspector({
    required bool enabled,
    required GlobalKey<NavigatorState> navigatorKey,
    NetworkRedactor redactor = const NetworkRedactor(),
  }) : _redactor = redactor,
       _alice = enabled
           ? Alice(
               configuration: AliceConfiguration(
                 navigatorKey: navigatorKey,
                 showNotification: false,
                 showInspectorOnShake: true,
               ),
             )
           : null;

  final Alice? _alice;
  final NetworkRedactor _redactor;

  bool get enabled => _alice != null;

  Interceptor? get interceptor =>
      _alice == null ? null : _RedactedAliceInterceptor(_alice, _redactor);

  void show() => _alice?.showInspector();
}

class _RedactedAliceInterceptor extends Interceptor {
  _RedactedAliceInterceptor(this._alice, this._redactor);

  final Alice _alice;
  final NetworkRedactor _redactor;
  final Map<int, AliceHttpCall> _pending = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    final requestBody = _redactor.body(options.data);
    final request = AliceHttpRequest()
      ..time = DateTime.now()
      ..headers = _redactor.headers(options.headers)
      ..queryParameters = _redactor.query(options.queryParameters)
      ..contentType = options.contentType
      ..body = requestBody
      ..size = utf8.encode(requestBody.toString()).length;

    _pending[options.hashCode] = AliceHttpCall(options.hashCode)
      ..method = options.method
      ..endpoint = uri.path.isEmpty ? '/' : uri.path
      ..server = uri.host
      ..client = 'Dio (redacted)'
      ..uri = uri.replace(queryParameters: request.queryParameters).toString()
      ..secure = uri.scheme == 'https'
      ..request = request
      ..response = AliceHttpResponse();

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final call = _pending.remove(response.requestOptions.hashCode);
    if (call != null) {
      final responseBody = _redactor.body(response.data);
      call
        ..loading = false
        ..duration = DateTime.now().difference(call.createdTime).inMilliseconds
        ..response = (AliceHttpResponse()
          ..status = response.statusCode
          ..time = DateTime.now()
          ..headers = _redactor.headers(response.headers.map)
          ..body = responseBody
          ..size = utf8.encode(responseBody.toString()).length);
      _alice.addHttpCall(call);
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final call = _pending.remove(error.requestOptions.hashCode);
    if (call != null) {
      final responseBody = _redactor.body(error.response?.data);
      call
        ..loading = false
        ..duration = DateTime.now().difference(call.createdTime).inMilliseconds
        ..error = (AliceHttpError()
          ..error = _redactor.text(error.message ?? error.type.name)
          ..stackTrace = error.stackTrace)
        ..response = (AliceHttpResponse()
          ..status = error.response?.statusCode ?? -1
          ..time = DateTime.now()
          ..headers = _redactor.headers(error.response?.headers.map ?? {})
          ..body = responseBody
          ..size = utf8.encode(responseBody.toString()).length);
      _alice.addHttpCall(call);
    }
    handler.next(error);
  }
}
