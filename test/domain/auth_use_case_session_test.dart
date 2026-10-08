import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/token_wrapper.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockAuthRepo authRepo;
  late _MockSessionRepo session;
  late AuthUseCase useCase;
  final login = _MockLogin();
  final token = _MockToken();
  final account = _MockAccount();

  setUpAll(() {
    registerFallbackValue(_MockAccount());
  });

  setUp(() {
    authRepo = _MockAuthRepo();
    session = _MockSessionRepo();
    useCase = AuthUseCase(authRepo, session, _MockPhoneRepo());
    when(() => login.token).thenReturn(token);
    when(() => login.account).thenReturn(account);
    when(
      () => session.start(
        token: any(named: 'token'),
        account: any(named: 'account'),
        persist: any(named: 'persist'),
      ),
    ).thenAnswer((_) async {});
    when(() => session.end()).thenAnswer((_) async {});
    when(() => session.updateAccount(any())).thenAnswer((_) async {});
  });

  void stubLogin(Login? result) => when(
    () => authRepo.appLogin(
      phone: any(named: 'phone'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  test('a login without remember still starts an in-memory session', () async {
    stubLogin(login);

    await useCase.login(phone: '0912345678', password: 'pw');

    verify(
      () => session.start(token: token, account: account, persist: false),
    ).called(1);
  });

  test('a remembered login starts a persisted session', () async {
    stubLogin(login);

    await useCase.login(
      phone: '+84912345678',
      password: 'pw',
      isRememberLogin: true,
    );

    verify(
      () => session.start(token: token, account: account, persist: true),
    ).called(1);
  });

  test('login normalizes a local phone number', () async {
    stubLogin(login);

    await useCase.login(phone: '0912345678', password: 'pw');

    verify(
      () => authRepo.appLogin(phone: '+84912345678', password: 'pw'),
    ).called(1);
  });

  test('a failed login leaves the session untouched', () async {
    stubLogin(null);

    expect(await useCase.login(phone: '0912', password: 'pw'), isNull);

    verifyNever(
      () => session.start(
        token: any(named: 'token'),
        account: any(named: 'account'),
        persist: any(named: 'persist'),
      ),
    );
  });

  test('logout ends the session', () async {
    await useCase.logout();

    verify(() => session.end()).called(1);
  });

  test('a verified phone updates the cached account', () async {
    final update = _MockUpdateAccount();
    when(() => update.account).thenReturn(account);
    when(
      () => authRepo.verifyPhone(idToken: any(named: 'idToken')),
    ).thenAnswer((_) async => update);

    await useCase.verifyPhone(idToken: 'id-token');

    verify(() => session.updateAccount(account)).called(1);
  });

  test('sign-in state and account come from the session', () {
    when(() => session.isSignedIn).thenReturn(true);
    when(() => session.account).thenReturn(account);

    expect(useCase.isAppLogin(), isTrue);
    expect(useCase.accountLocal, same(account));
  });

  test('normalizePhone only rewrites local numbers', () {
    expect(AuthUseCase.normalizePhone('0912345678'), '+84912345678');
    expect(AuthUseCase.normalizePhone('+84912345678'), '+84912345678');
    expect(AuthUseCase.normalizePhone('user@example.com'), 'user@example.com');
  });
}

class _MockAuthRepo extends Mock implements AuthRepo {}

class _MockSessionRepo extends Mock implements SessionRepo {}

class _MockPhoneRepo extends Mock implements PhoneVerificationRepo {}

class _MockLogin extends Mock implements Login {}

class _MockToken extends Mock implements TokenWrapper {}

class _MockAccount extends Mock implements Account {}

class _MockUpdateAccount extends Mock implements UpdateAccount {}
