import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockAuthUseCase authUseCase;
  late SignInCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = SignInCubit(authUseCase);
  });

  tearDown(() => cubit.close());

  void stubLogin(Future<Login?> Function() answer) => when(
    () => authUseCase.login(
      phone: any(named: 'phone'),
      password: any(named: 'password'),
      isRememberLogin: any(named: 'isRememberLogin'),
    ),
  ).thenAnswer((_) => answer());

  test('keeps localized validation text out of business state', () async {
    await cubit.onTapSignIn(username: '', pass: '');

    expect(cubit.state.usernameError, EmailOrPhoneInputError.required);
    expect(cubit.state.passwordError, PasswordInputError.required);
    verifyNever(
      () => authUseCase.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        isRememberLogin: any(named: 'isRememberLogin'),
      ),
    );
  });

  test('publishes navigation intent after a login', () async {
    stubLogin(() async => _MockLogin());

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');

    expect(cubit.state.effect?.value, isA<SignInNavigateHomeEffect>());
    verify(
      () => authUseCase.login(
        phone: '0912345678',
        password: 'Password@1',
        isRememberLogin: true,
      ),
    ).called(1);
  });

  test('a login that returns nothing stays on the screen', () async {
    stubLogin(() async => null);

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');

    expect(cubit.state.effect, isNull);
  });

  test('repeated errors publish unique effects', () async {
    stubLogin(() async => throw StateError('login failed'));

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');
    final first = cubit.state.effect!;
    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');
    final second = cubit.state.effect!;

    expect(second.revision, first.revision + 1);
  });

  test('publishes an error intent instead of opening UI', () async {
    final error = StateError('login failed');
    stubLogin(() async => throw error);

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');

    final effect = cubit.state.effect?.value;
    expect(effect, isA<SignInShowErrorEffect>());
    expect((effect! as SignInShowErrorEffect).error, same(error));
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}

class _MockLogin extends Mock implements Login {}
