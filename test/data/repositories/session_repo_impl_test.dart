import 'dart:convert';

import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/data/datasource/local/session_expiry_coordinator.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:bloc_cubit_base/data/datasource/local/user_local_data_source.dart';
import 'package:bloc_cubit_base/data/model/response/token_response_model.dart';
import 'package:bloc_cubit_base/data/repositories/session_repo_impl.dart';
import 'package:bloc_cubit_base/domain/entities/auth/token_auth.dart';
import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the whole session lifecycle through [SessionRepoImpl] with real
/// token and account stores backed by in-memory storage.
void main() {
  late _MemorySecureStorage secure;
  late SharedPreferences preferences;
  late TokenProvider tokens;
  late UserLocalDataSource accounts;
  late SessionRepoImpl session;

  Future<void> boot() async {
    tokens = await TokenProvider(secure, preferences).init();
    accounts = UserLocalDataSourceImpl(preferences);
    session = SessionRepoImpl(tokens, accounts);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    secure = _MemorySecureStorage();
    await boot();
  });

  test('a session that is not remembered is signed in until restart', () async {
    await session.start(
      token: _token('access-1', 'refresh-1'),
      account: _account(phone: '+84912345678'),
      persist: false,
    );

    expect(session.isSignedIn, isTrue);
    expect(tokens.token.accessToken, 'access-1');
    expect(session.account.phone, '+84912345678');
    expect(secure.values, isEmpty);

    await boot();
    expect(session.isSignedIn, isFalse);
    expect(session.account.phone, isNull);
  });

  test('a remembered session survives a restart', () async {
    await session.start(
      token: _token('access-1', 'refresh-1'),
      account: _account(phone: '+84912345678'),
      persist: true,
    );

    await boot();
    expect(session.isSignedIn, isTrue);
    expect(tokens.token.refreshToken, 'refresh-1');
    expect(session.account.phone, '+84912345678');
  });

  test(
    'a non-remembered sign-in removes an older remembered session',
    () async {
      await session.start(
        token: _token('old', 'old'),
        account: _account(phone: 'old'),
        persist: true,
      );
      await session.start(
        token: _token('new', 'new'),
        account: _account(phone: 'new'),
        persist: false,
      );

      await boot();
      expect(session.isSignedIn, isFalse);
      expect(session.account.phone, isNull);
    },
  );

  test('ending a session clears token and account together', () async {
    await session.start(
      token: _token('access', 'refresh'),
      account: _account(phone: '+84912345678'),
      persist: true,
    );

    await session.end();

    expect(session.isSignedIn, isFalse);
    expect(session.account.phone, isNull);
    await boot();
    expect(session.isSignedIn, isFalse);
    expect(session.account.phone, isNull);
  });

  test('expiry ends the whole session before announcing it', () async {
    await session.start(
      token: _token('access', 'refresh'),
      account: _account(phone: '+84912345678'),
      persist: true,
    );
    final events = SessionEventController();
    addTearDown(events.dispose);
    final announced = events.events.first;

    await SessionExpiryCoordinator(session, events).expire();

    expect(await announced, isA<SessionExpiredEvent>());
    expect(session.isSignedIn, isFalse);
    expect(session.account.phone, isNull);
  });

  test('accounts from any domain implementation are stored', () async {
    await session.start(
      token: _token('access', 'refresh'),
      account: _account(phone: '+84900000000', isPhoneVerified: false),
      persist: true,
    );
    await session.updateAccount(
      _account(phone: '+84900000000', isPhoneVerified: true),
    );

    await boot();
    expect(session.account.isPhoneVerified, isTrue);
  });

  test(
    'a refreshed token stays in memory for a non-remembered session',
    () async {
      await session.start(
        token: _token('access', 'refresh'),
        account: _account(),
        persist: false,
      );

      final updated = await tokens.setTokenIfRevision(
        TokenResponseModel(accessToken: 'refreshed', refreshToken: 'r2'),
        expectedRevision: tokens.revision,
      );

      expect(updated, isTrue);
      expect(tokens.token.accessToken, 'refreshed');
      expect(secure.values, isEmpty);
    },
  );
}

TokenWrapper _token(String access, String refresh) =>
    _Token(_Auth(access), _Auth(refresh));

Account _account({String? phone, bool? isPhoneVerified}) =>
    _Account(phone, isPhoneVerified);

class _Token implements TokenWrapper {
  _Token(this.access, this.refresh);
  @override
  final TokenAuth? access;
  @override
  final TokenAuth? refresh;
}

class _Auth implements TokenAuth {
  _Auth(this.token);
  @override
  final String? token;
  @override
  DateTime? get expires => null;
}

/// A domain account that is not the data model, as returned by a fake API.
class _Account implements Account {
  _Account(this.phone, this.isPhoneVerified);
  @override
  final String? phone;
  @override
  final bool? isPhoneVerified;
  @override
  int? get id => 1;
  @override
  String? get role => 'user';
  @override
  bool? get isEmailVerified => null;
  @override
  bool? get isDeleted => false;
  @override
  String? get email => null;
  @override
  bool? get isActive => true;
  @override
  DateTime? get updatedAt => null;
  @override
  DateTime? get createdAt => null;
}

class _MemorySecureStorage implements FlutterSecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      jsonDecode(value);
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
