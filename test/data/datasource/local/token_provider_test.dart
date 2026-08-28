import 'dart:async';
import 'dart:convert';

import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MockSecureStorage storage;
  late _MockSharedPreferences preferences;
  late TokenProvider provider;

  setUp(() {
    storage = _MockSecureStorage();
    preferences = _MockSharedPreferences();
    provider = TokenProvider(storage, preferences);
  });

  test('compare-and-set persists only the expected token revision', () async {
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final token = TokenResponseModel(
      accessToken: 'access',
      refreshToken: 'refresh',
    );

    final didPersist = await provider.setTokenIfRevision(
      token,
      expectedRevision: 0,
    );
    final stalePersist = await provider.setTokenIfRevision(
      TokenResponseModel(accessToken: 'stale'),
      expectedRevision: 0,
    );

    expect(didPersist, isTrue);
    expect(stalePersist, isFalse);
    expect(provider.revision, 1);
    expect(provider.token.accessToken, 'access');
    final captured = verify(
      () => storage.write(
        key: 'token',
        value: captureAny(named: 'value'),
      ),
    ).captured.single as String;
    expect(jsonDecode(captured), {
      'accessToken': 'access',
      'refreshToken': 'refresh',
    });
  });

  test('rejecting a stale revision does not touch secure storage', () async {
    final result = await provider.setTokenIfRevision(
      TokenResponseModel(accessToken: 'stale'),
      expectedRevision: 1,
    );

    expect(result, isFalse);
    expect(provider.revision, 0);
    expect(provider.token.accessToken, isNull);
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('serializes secure writes so the latest in-memory state wins', () async {
    final writeStarted = Completer<void>();
    final releaseWrite = Completer<void>();
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) {
      writeStarted.complete();
      return releaseWrite.future;
    });
    when(
      () => storage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    final setFuture = provider.setToken(
      TokenResponseModel(accessToken: 'temporary', refreshToken: 'refresh'),
    );
    await writeStarted.future;
    final clearFuture = provider.clearToken();

    expect(provider.token.accessToken, isNull);
    expect(provider.revision, 2);
    verifyNever(() => storage.delete(key: any(named: 'key')));

    releaseWrite.complete();
    await setFuture;
    await clearFuture;

    verify(() => storage.delete(key: 'token')).called(1);
    expect(provider.token.accessToken, isNull);
  });
}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}
