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

const String skipSessionRefreshKey = 'skipSessionRefresh';

class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required this.baseUrl,
    required this.onSessionExpired,
    required this.tokenProvider,
    required Dio sessionClient,
  }) : _sessionClient = sessionClient;

  final TokenProvider tokenProvider;

  /// Owns terminal session cleanup and may publish an app-level notification.
  ///
  /// The callback is coalesced for every access-token generation, even when
  /// several requests fail while waiting for the same refresh operation.
  final FutureOr<void> Function() onSessionExpired;
  final String baseUrl;
  final Dio _sessionClient;

  Future<_RefreshResult>? _refreshing;
  _SessionSnapshot? _refreshingSession;
  Future<void>? _expiringSession;
  String? _expiredAccessToken;
  _RefreshTransition? _lastRefresh;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final currentToken = tokenProvider.token;
    final currentAccessToken = currentToken.accessToken;
    _synchronizeSession(currentAccessToken);

    if (!_shouldRefresh(err, currentAccessToken)) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    if (!_canReplayData(request.data)) {
      handler.next(err);
      return;
    }
    final requestAccessToken = _bearerAccessToken(request);
    String? accessToken;

    if (requestAccessToken != currentAccessToken) {
      final activeRefresh = _refreshing;
      final activeSession = _refreshingSession;
      if (activeRefresh != null &&
          activeSession?.accessToken == requestAccessToken) {
        final result = await activeRefresh;
        if (!result.isSuccess) {
          handler.next(err);
          return;
        }
        accessToken = result.accessToken;
      } else {
        if (!_canReplayStaleRequest(
          requestAccessToken: requestAccessToken,
          currentAccessToken: currentAccessToken,
        )) {
          handler.next(err);
          return;
        }
        accessToken = currentAccessToken;
      }
    } else {
      final result = await _singleFlightRefresh(
        _SessionSnapshot(
          accessToken: currentAccessToken!,
          refreshToken: currentToken.refreshToken,
          revision: tokenProvider.revision,
        ),
      );
      if (!result.isSuccess) {
        handler.next(err);
        return;
      }
      accessToken = result.accessToken;
    }

    final replayRequest = _buildReplayRequest(request, accessToken!);

    try {
      final response = await _sessionClient.fetch<dynamic>(replayRequest);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (_requiresRefresh(retryError)) {
        await _expireSessionOnce(accessToken);
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioException error, String? currentAccessToken) {
    final request = error.requestOptions;
    return currentAccessToken.isNotNullOrEmpty &&
        _requiresRefresh(error) &&
        _isFirstParty(request) &&
        _bearerAccessToken(request).isNotNullOrEmpty &&
        request.extra[skipSessionRefreshKey] != true &&
        !_skipRefreshPaths.contains(request.uri.path);
  }

  bool _requiresRefresh(DioException error) {
    return error.response?.statusCode == 401;
  }

  bool _isFirstParty(RequestOptions request) {
    final expected = Uri.parse(baseUrl);
    final actual = request.uri;
    return actual.scheme == expected.scheme &&
        actual.host == expected.host &&
        actual.port == expected.port;
  }

  String? _bearerAccessToken(RequestOptions request) {
    Object? authorization;
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        authorization = entry.value;
        break;
      }
    }
    if (authorization is! String) {
      return null;
    }

    final match = RegExp(
      r'^Bearer\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(authorization.trim());
    return match?.group(1)?.trim();
  }

  bool _canReplayStaleRequest({
    required String? requestAccessToken,
    required String? currentAccessToken,
  }) {
    final transition = _lastRefresh;
    return transition != null &&
        transition.previousAccessToken == requestAccessToken &&
        transition.currentAccessToken == currentAccessToken;
  }

  Future<_RefreshResult> _singleFlightRefresh(_SessionSnapshot session) {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) {
      return _refreshingSession?.matches(session) == true
          ? activeRefresh
          : Future<_RefreshResult>.value(_RefreshResult.superseded);
    }

    late final Future<_RefreshResult> refresh;
    refresh = _refreshToken(session).whenComplete(() {
      if (identical(_refreshing, refresh)) {
        _refreshing = null;
        _refreshingSession = null;
      }
    });
    _refreshingSession = session;
    _refreshing = refresh;
    return refresh;
  }

  Future<_RefreshResult> _refreshToken(_SessionSnapshot session) async {
    if (!_isCurrentSession(session)) {
      return _RefreshResult.superseded;
    }
    if (session.refreshToken.isNullOrEmpty) {
      await _expireSessionOnce(session.accessToken);
      return _RefreshResult.terminalFailure;
    }

    late final Response<dynamic> response;
    try {
      response = await _sessionClient.post<dynamic>(
        UrlEndPoint.auth.refreshToken,
        data: {'refreshToken': session.refreshToken},
      );
    } on DioException catch (error) {
      if (!_isCurrentSession(session)) {
        return _RefreshResult.superseded;
      }
      if (_isTerminalRefreshError(error)) {
        await _expireSessionOnce(session.accessToken);
        return _RefreshResult.terminalFailure;
      }
      return _RefreshResult.transientFailure;
    } catch (_) {
      return _isCurrentSession(session)
          ? _RefreshResult.transientFailure
          : _RefreshResult.superseded;
    }

    late final TokenResponseModel? refreshedToken;
    try {
      final parsed = BaseResponseModel<TokenResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TokenResponseModel.fromJson(json as Map<String, dynamic>),
      );
      refreshedToken = parsed.data;
    } catch (_) {
      return _isCurrentSession(session)
          ? _RefreshResult.transientFailure
          : _RefreshResult.superseded;
    }

    if (!_isCurrentSession(session)) {
      return _RefreshResult.superseded;
    }
    if (refreshedToken?.accessToken.isNullOrEmpty ?? true) {
      await _expireSessionOnce(session.accessToken);
      return _RefreshResult.terminalFailure;
    }

    final tokenToPersist = TokenResponseModel(
      accessToken: refreshedToken!.accessToken,
      refreshToken: refreshedToken.refreshToken ?? session.refreshToken,
    );
    late final bool didPersist;
    try {
      didPersist = await tokenProvider.setTokenIfRevision(
        tokenToPersist,
        expectedRevision: session.revision,
      );
    } catch (_) {
      return _RefreshResult.transientFailure;
    }

    final refreshedAccessToken = tokenToPersist.accessToken!;
    if (!didPersist ||
        tokenProvider.revision != session.revision + 1 ||
        tokenProvider.token.accessToken != refreshedAccessToken) {
      return _RefreshResult.superseded;
    }
    _lastRefresh = _RefreshTransition(
      previousAccessToken: session.accessToken,
      currentAccessToken: refreshedAccessToken,
    );
    _expiredAccessToken = null;
    return _RefreshResult.success(refreshedAccessToken);
  }

  bool _isTerminalRefreshError(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }

  bool _isCurrentSession(_SessionSnapshot session) {
    final current = tokenProvider.token;
    return current.accessToken == session.accessToken &&
        current.refreshToken == session.refreshToken &&
        tokenProvider.revision == session.revision;
  }

  dynamic _replayableData(dynamic data) {
    return data is FormData ? data.clone() : data;
  }

  RequestOptions _buildReplayRequest(
    RequestOptions request,
    String accessToken,
  ) {
    final data = _replayableData(request.data);
    final headers = <String, dynamic>{
      ...request.headers,
      'Authorization': 'Bearer $accessToken',
    };
    if (data is FormData) {
      headers.removeWhere(
        (key, _) => key.toLowerCase() == Headers.contentTypeHeader,
      );
      return request.copyWith(
        data: data,
        headers: headers,
        contentType: Headers.multipartFormDataContentType,
      );
    }
    return request.copyWith(data: data, headers: headers);
  }

  bool _canReplayData(dynamic data) {
    return data is! Stream<dynamic>;
  }

  void _synchronizeSession(String? currentAccessToken) {
    if (currentAccessToken.isNotNullOrEmpty &&
        currentAccessToken != _expiredAccessToken) {
      _expiredAccessToken = null;
    }
    if (_lastRefresh?.currentAccessToken != currentAccessToken) {
      _lastRefresh = null;
    }
  }

  Future<void> _expireSessionOnce(String? accessToken) async {
    if (_expiredAccessToken == accessToken) {
      try {
        await _expiringSession;
      } catch (_) {
        // The original request error remains the source of truth for callers.
      }
      return;
    }

    _expiredAccessToken = accessToken;
    late final Future<void> expiringSession;
    expiringSession = Future<void>.sync(onSessionExpired).whenComplete(() {
      if (identical(_expiringSession, expiringSession)) {
        _expiringSession = null;
      }
    });
    _expiringSession = expiringSession;

    try {
      await expiringSession;
    } catch (_) {
      // The original request error remains the source of truth for callers.
    }
  }
}

enum _RefreshStatus { success, terminalFailure, transientFailure, superseded }

class _RefreshResult {
  const _RefreshResult._(this.status, [this.accessToken]);

  static const terminalFailure = _RefreshResult._(
    _RefreshStatus.terminalFailure,
  );
  static const transientFailure = _RefreshResult._(
    _RefreshStatus.transientFailure,
  );
  static const superseded = _RefreshResult._(_RefreshStatus.superseded);

  factory _RefreshResult.success(String accessToken) {
    return _RefreshResult._(_RefreshStatus.success, accessToken);
  }

  final _RefreshStatus status;
  final String? accessToken;

  bool get isSuccess => status == _RefreshStatus.success;
}

class _SessionSnapshot {
  const _SessionSnapshot({
    required this.accessToken,
    required this.refreshToken,
    required this.revision,
  });

  final String accessToken;
  final String? refreshToken;
  final int revision;

  bool matches(_SessionSnapshot other) {
    return accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        revision == other.revision;
  }
}

class _RefreshTransition {
  const _RefreshTransition({
    required this.previousAccessToken,
    required this.currentAccessToken,
  });

  final String previousAccessToken;
  final String currentAccessToken;
}
