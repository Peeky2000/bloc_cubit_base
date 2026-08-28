import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/remote/interceptor/auth_interceotor.dart';
import 'package:bloc_cubit_base/data/datasource/remote/interceptor/session_interceptor.dart';
import 'package:bloc_cubit_base/data/datasource/remote/url_end_point.dart';
import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseUrl = 'https://api.example.test';

void main() {
  group('SessionInterceptor', () {
    test(
      'coalesces concurrent 401 refresh and replays every request',
      () async {
        const requestCount = 8;
        final allRequestsFailed = Completer<void>();
        var initialRequestCount = 0;
        var refreshCount = 0;
        var replayCount = 0;
        final replayAuthorizations = <Object?>[];

        final harness = _SessionHarness(
          initialToken: _token('old-access', 'old-refresh'),
          mainResponder: (options) {
            initialRequestCount++;
            expect(options.headers['Authorization'], 'Bearer old-access');
            if (initialRequestCount == requestCount) {
              allRequestsFailed.complete();
            }
            return _jsonResponse(401, {'message': 'expired'});
          },
          sessionResponder: (options) async {
            if (options.uri.path == UrlEndPoint.auth.refreshToken) {
              refreshCount++;
              await allRequestsFailed.future;
              return _refreshResponse(
                accessToken: 'new-access',
                refreshToken: 'new-refresh',
              );
            }

            replayCount++;
            replayAuthorizations.add(options.headers['Authorization']);
            return _jsonResponse(200, {'path': options.uri.path});
          },
        );
        addTearDown(harness.close);

        final responses = await Future.wait(
          List.generate(
            requestCount,
            (index) => harness.dio.get<dynamic>('/protected/$index'),
          ),
        ).timeout(const Duration(seconds: 5));

        expect(responses, hasLength(requestCount));
        expect(
          responses.map((response) => response.statusCode),
          everyElement(200),
        );
        expect(refreshCount, 1);
        expect(replayCount, requestCount);
        expect(replayAuthorizations, everyElement('Bearer new-access'));
        expect(harness.provider.conditionalSetCount, 1);
        expect(harness.provider.token.accessToken, 'new-access');
        expect(harness.provider.token.refreshToken, 'new-refresh');
        expect(harness.expiryCount, 0);
        expect(harness.provider.clearCount, 0);
      },
    );

    test(
      'terminal refresh rejection expires one concurrent wave once',
      () async {
        const requestCount = 6;
        final allRequestsFailed = Completer<void>();
        var initialRequestCount = 0;
        var refreshCount = 0;
        var replayCount = 0;

        final harness = _SessionHarness(
          initialToken: _token('old-access', 'invalid-refresh'),
          mainResponder: (options) {
            initialRequestCount++;
            if (initialRequestCount == requestCount) {
              allRequestsFailed.complete();
            }
            return _jsonResponse(401, {'message': 'expired'});
          },
          sessionResponder: (options) async {
            if (options.uri.path == UrlEndPoint.auth.refreshToken) {
              refreshCount++;
              await allRequestsFailed.future;
              return _jsonResponse(401, {'message': 'invalid refresh token'});
            }
            replayCount++;
            return _jsonResponse(200, const <String, dynamic>{});
          },
        );
        addTearDown(harness.close);

        final results = await Future.wait(
          List.generate(
            requestCount,
            (index) => _capture(harness.dio.get<dynamic>('/protected/$index')),
          ),
        ).timeout(const Duration(seconds: 5));

        for (final result in results) {
          expect(result, isA<DioException>());
          final error = result as DioException;
          expect(error.response?.statusCode, 401);
          expect(error.requestOptions.uri.path, startsWith('/protected/'));
        }
        expect(refreshCount, 1);
        expect(replayCount, 0);
        expect(harness.expiryCount, 1);
        expect(harness.provider.clearCount, 1);
        expect(harness.provider.token.accessToken, isNull);
      },
    );

    test('transient refresh 500 preserves the current session', () async {
      const requestCount = 3;
      final allRequestsFailed = Completer<void>();
      var initialRequestCount = 0;
      var refreshCount = 0;

      final harness = _SessionHarness(
        initialToken: _token('old-access', 'old-refresh'),
        mainResponder: (options) {
          initialRequestCount++;
          if (initialRequestCount == requestCount) {
            allRequestsFailed.complete();
          }
          return _jsonResponse(401, {'message': 'expired'});
        },
        sessionResponder: (options) async {
          refreshCount++;
          await allRequestsFailed.future;
          return _jsonResponse(500, {'message': 'temporary failure'});
        },
      );
      addTearDown(harness.close);

      final results = await Future.wait(
        List.generate(
          requestCount,
          (index) => _capture(harness.dio.get<dynamic>('/protected/$index')),
        ),
      ).timeout(const Duration(seconds: 5));

      expect(results, everyElement(isA<DioException>()));
      expect(refreshCount, 1);
      expect(harness.expiryCount, 0);
      expect(harness.provider.clearCount, 0);
      expect(harness.provider.token.accessToken, 'old-access');
      expect(harness.provider.token.refreshToken, 'old-refresh');
    });

    test('403 permission response does not refresh or expire', () async {
      final harness = _SessionHarness(
        initialToken: _token('access', 'refresh'),
        mainResponder: (_) => _jsonResponse(403, {'message': 'forbidden'}),
        sessionResponder: (_) {
          fail('The session client must not receive a 403 retry.');
        },
      );
      addTearDown(harness.close);

      final result = await _capture(harness.dio.get<dynamic>('/admin'));

      expect(result, isA<DioException>());
      expect((result as DioException).response?.statusCode, 403);
      expect(harness.sessionAdapter.requests, isEmpty);
      expect(harness.expiryCount, 0);
      expect(harness.provider.clearCount, 0);
    });

    test(
      'external absolute 401 never receives the internal bearer token',
      () async {
        Object? authorization;
        final harness = _SessionHarness(
          initialToken: _token('internal-secret', 'refresh'),
          mainResponder: (options) {
            authorization = options.headers['Authorization'];
            return _jsonResponse(401, {'message': 'external unauthorized'});
          },
          sessionResponder: (_) {
            fail('A cross-origin request must never reach the session client.');
          },
        );
        addTearDown(harness.close);

        final result = await _capture(
          harness.dio.get<dynamic>('https://third-party.example/private'),
        );

        expect(result, isA<DioException>());
        expect(authorization, isNull);
        expect(harness.sessionAdapter.requests, isEmpty);
        expect(harness.expiryCount, 0);
      },
    );

    test('auth paths and explicit opt-out never start refresh', () async {
      final harness = _SessionHarness(
        initialToken: _token('access', 'refresh'),
        mainResponder: (_) => _jsonResponse(401, {'message': 'unauthorized'}),
        sessionResponder: (_) {
          fail('An excluded request must not reach the session client.');
        },
      );
      addTearDown(harness.close);

      final requests = <Future<Response<dynamic>>>[
        harness.dio.get<dynamic>('${UrlEndPoint.auth.login}?next=home'),
        harness.dio.get<dynamic>(UrlEndPoint.auth.signUp),
        harness.dio.get<dynamic>(UrlEndPoint.auth.refreshToken),
        harness.dio.get<dynamic>(
          '/protected',
          options: Options(extra: {skipSessionRefreshKey: true}),
        ),
      ];
      final results = await Future.wait(requests.map(_capture));

      expect(results, everyElement(isA<DioException>()));
      expect(harness.sessionAdapter.requests, isEmpty);
      expect(harness.expiryCount, 0);
      expect(harness.provider.clearCount, 0);
    });

    test('retry 500 keeps the refreshed token and does not expire', () async {
      var refreshCount = 0;
      var replayCount = 0;
      final harness = _SessionHarness(
        initialToken: _token('old-access', 'old-refresh'),
        mainResponder: (_) => _jsonResponse(401, {'message': 'expired'}),
        sessionResponder: (options) {
          if (options.uri.path == UrlEndPoint.auth.refreshToken) {
            refreshCount++;
            return _refreshResponse(accessToken: 'new-access');
          }
          replayCount++;
          return _jsonResponse(500, {'message': 'retry failed'});
        },
      );
      addTearDown(harness.close);

      final result = await _capture(harness.dio.get<dynamic>('/protected'));

      expect(result, isA<DioException>());
      expect((result as DioException).response?.statusCode, 500);
      expect(refreshCount, 1);
      expect(replayCount, 1);
      expect(harness.provider.token.accessToken, 'new-access');
      expect(harness.provider.token.refreshToken, 'old-refresh');
      expect(harness.expiryCount, 0);
      expect(harness.provider.clearCount, 0);
    });

    test('concurrent retry 401 expires the refreshed session once', () async {
      const requestCount = 4;
      final allRequestsFailed = Completer<void>();
      var initialRequestCount = 0;
      var refreshCount = 0;
      var replayCount = 0;

      final harness = _SessionHarness(
        initialToken: _token('old-access', 'old-refresh'),
        mainResponder: (_) {
          initialRequestCount++;
          if (initialRequestCount == requestCount) {
            allRequestsFailed.complete();
          }
          return _jsonResponse(401, {'message': 'expired'});
        },
        sessionResponder: (options) async {
          if (options.uri.path == UrlEndPoint.auth.refreshToken) {
            refreshCount++;
            await allRequestsFailed.future;
            return _refreshResponse(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
            );
          }
          replayCount++;
          return _jsonResponse(401, {'message': 'still unauthorized'});
        },
      );
      addTearDown(harness.close);

      final results = await Future.wait(
        List.generate(
          requestCount,
          (index) => _capture(harness.dio.get<dynamic>('/protected/$index')),
        ),
      ).timeout(const Duration(seconds: 5));

      expect(results, everyElement(isA<DioException>()));
      expect(refreshCount, 1);
      expect(replayCount, requestCount);
      expect(harness.expiryCount, 1);
      expect(harness.provider.clearCount, 1);
      expect(harness.provider.token.accessToken, isNull);
    });

    test('missing refresh token expires without a refresh request', () async {
      final harness = _SessionHarness(
        initialToken: _token('old-access', null),
        mainResponder: (_) => _jsonResponse(401, {'message': 'expired'}),
        sessionResponder: (_) {
          fail('Missing refresh credentials must not call the refresh route.');
        },
      );
      addTearDown(harness.close);

      final result = await _capture(harness.dio.get<dynamic>('/protected'));

      expect(result, isA<DioException>());
      expect(harness.sessionAdapter.requests, isEmpty);
      expect(harness.expiryCount, 1);
      expect(harness.provider.clearCount, 1);
    });

    test(
      'an old-session request is not replayed under a new account',
      () async {
        final requestReachedAdapter = Completer<void>();
        final releaseResponse = Completer<void>();
        final harness = _SessionHarness(
          initialToken: _token('account-a-access', 'account-a-refresh'),
          mainResponder: (options) async {
            expect(options.headers['Authorization'], 'Bearer account-a-access');
            requestReachedAdapter.complete();
            await releaseResponse.future;
            return _jsonResponse(401, {'message': 'expired'});
          },
          sessionResponder: (_) {
            fail('A request from the old account must not be replayed.');
          },
        );
        addTearDown(harness.close);

        final request = _capture(harness.dio.get<dynamic>('/account/mutation'));
        await requestReachedAdapter.future;
        await harness.provider.setToken(
          _token('account-b-access', 'account-b-refresh'),
        );
        releaseResponse.complete();
        final result = await request;

        expect(result, isA<DioException>());
        expect(harness.sessionAdapter.requests, isEmpty);
        expect(harness.provider.token.accessToken, 'account-b-access');
        expect(harness.provider.token.refreshToken, 'account-b-refresh');
        expect(harness.expiryCount, 0);
      },
    );

    test('a stale refresh response cannot overwrite a new account', () async {
      final refreshStarted = Completer<void>();
      final releaseRefresh = Completer<void>();
      var replayCount = 0;
      final harness = _SessionHarness(
        initialToken: _token('account-a-access', 'account-a-refresh'),
        mainResponder: (_) => _jsonResponse(401, {'message': 'expired'}),
        sessionResponder: (options) async {
          if (options.uri.path == UrlEndPoint.auth.refreshToken) {
            refreshStarted.complete();
            await releaseRefresh.future;
            return _refreshResponse(
              accessToken: 'account-a-new-access',
              refreshToken: 'account-a-new-refresh',
            );
          }
          replayCount++;
          return _jsonResponse(200, const <String, dynamic>{});
        },
      );
      addTearDown(harness.close);

      final request = _capture(harness.dio.get<dynamic>('/protected'));
      await refreshStarted.future;
      await harness.provider.setToken(
        _token('account-b-access', 'account-b-refresh'),
      );
      releaseRefresh.complete();
      final result = await request;

      expect(result, isA<DioException>());
      expect(replayCount, 0);
      expect(harness.provider.conditionalSetCount, 0);
      expect(harness.provider.token.accessToken, 'account-b-access');
      expect(harness.provider.token.refreshToken, 'account-b-refresh');
      expect(harness.expiryCount, 0);
    });

    test(
      'multipart replay clones FormData and rebuilds its boundary header',
      () async {
        final original = FormData.fromMap({'title': 'document'});
        FormData? replayed;
        String? replayContentType;
        final harness = _SessionHarness(
          initialToken: _token('old-access', 'old-refresh'),
          mainResponder: (_) => _jsonResponse(401, {'message': 'expired'}),
          sessionResponder: (options) {
            if (options.uri.path == UrlEndPoint.auth.refreshToken) {
              return _refreshResponse(
                accessToken: 'new-access',
                refreshToken: 'new-refresh',
              );
            }
            replayed = options.data as FormData;
            replayContentType =
                options.headers[Headers.contentTypeHeader] as String?;
            return _jsonResponse(200, {'ok': true});
          },
        );
        addTearDown(harness.close);

        final response = await harness.dio.post<dynamic>(
          '/upload',
          data: original,
        );

        expect(response.statusCode, 200);
        expect(replayed, isNotNull);
        expect(identical(replayed, original), isFalse);
        expect(replayed?.fields, original.fields);
        expect(replayed?.boundary, original.boundary);
        expect(replayContentType, contains(replayed?.boundary));
      },
    );
  });
}

TokenResponseModel _token(String? accessToken, String? refreshToken) {
  return TokenResponseModel(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}

ResponseBody _refreshResponse({
  required String accessToken,
  String? refreshToken,
}) {
  return _jsonResponse(200, {
    'data': {
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    },
    'message': '',
    'code': 200,
  });
}

ResponseBody _jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Future<Object> _capture<T>(Future<T> future) async {
  try {
    return await future as Object;
  } catch (error) {
    return error;
  }
}

typedef _AdapterResponder =
    FutureOr<ResponseBody> Function(RequestOptions options);

class _MemoryAdapter implements HttpClientAdapter {
  _MemoryAdapter(this._responder);

  final _AdapterResponder _responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

class _SessionHarness {
  _SessionHarness({
    required TokenResponseModel initialToken,
    required _AdapterResponder mainResponder,
    required _AdapterResponder sessionResponder,
  }) {
    provider = _MemoryTokenProvider(initialToken);
    mainAdapter = _MemoryAdapter(mainResponder);
    sessionAdapter = _MemoryAdapter(sessionResponder);
    sessionDio = Dio(BaseOptions(baseUrl: _baseUrl));
    sessionDio.httpClientAdapter = sessionAdapter;
    dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = mainAdapter;
    dio.interceptors.addAll([
      AuthInterceptor(provider),
      SessionInterceptor(
        baseUrl: _baseUrl,
        tokenProvider: provider,
        sessionClient: sessionDio,
        onSessionExpired: () async {
          expiryCount++;
          await provider.clearToken();
        },
      ),
    ]);
  }

  late final _MemoryTokenProvider provider;
  late final _MemoryAdapter mainAdapter;
  late final _MemoryAdapter sessionAdapter;
  late final Dio sessionDio;
  late final Dio dio;
  int expiryCount = 0;

  void close() {
    dio.close(force: true);
    sessionDio.close(force: true);
  }
}

class _MemoryTokenProvider implements TokenProvider {
  _MemoryTokenProvider(this._token);

  TokenResponseModel _token;
  int _revision = 0;
  int setCount = 0;
  int conditionalSetCount = 0;
  int clearCount = 0;

  @override
  TokenResponseModel get token => _token;

  @override
  int get revision => _revision;

  @override
  Future<TokenProvider> init() async => this;

  @override
  Future<void> setToken(TokenResponseModel? token) async {
    setCount++;
    _revision++;
    _token = token ?? TokenResponseModel();
  }

  @override
  Future<bool> setTokenIfRevision(
    TokenResponseModel token, {
    required int expectedRevision,
  }) async {
    if (_revision != expectedRevision) {
      return false;
    }
    conditionalSetCount++;
    _revision++;
    _token = token;
    return true;
  }

  @override
  Future<void> clearToken() async {
    clearCount++;
    _revision++;
    _token = TokenResponseModel();
  }
}
