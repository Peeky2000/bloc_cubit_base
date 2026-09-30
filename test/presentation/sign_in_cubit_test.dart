import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
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

  test('publishes unique effects for repeated UI commands', () {
    cubit.onTapForgotPassword();
    final first = cubit.state.effect!;
    cubit.onTapForgotPassword();
    final second = cubit.state.effect!;

    expect(first.value, isA<SignInNavigateForgotPasswordEffect>());
    expect(second.value, isA<SignInNavigateForgotPasswordEffect>());
    expect(second.revision, first.revision + 1);
  });

  test('publishes navigation intent after a verified login', () async {
    final login = _MockLogin();
    final account = _MockAccount();
    when(() => login.account).thenReturn(account);
    when(() => account.isPhoneVerified).thenReturn(true);
    when(
      () => authUseCase.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        isRememberLogin: any(named: 'isRememberLogin'),
      ),
    ).thenAnswer((_) async => login);

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');

    expect(cubit.state.effect?.value, isA<SignInNavigateHomeEffect>());
    verify(
      () => authUseCase.login(
        phone: '+84912345678',
        password: 'Password@1',
        isRememberLogin: true,
      ),
    ).called(1);
  });

  test('publishes a retryable error intent instead of opening UI', () async {
    final error = StateError('login failed');
    when(
      () => authUseCase.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        isRememberLogin: any(named: 'isRememberLogin'),
      ),
    ).thenThrow(error);

    await cubit.onTapSignIn(username: '0912345678', pass: 'Password@1');

    final effect = cubit.state.effect?.value;
    expect(effect, isA<SignInShowErrorEffect>());
    final errorEffect = effect! as SignInShowErrorEffect;
    expect(errorEffect.error, same(error));
    expect(errorEffect.retryAction, SignInRetryAction.signIn);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}

class _MockLogin extends Mock implements Login {}

class _MockAccount extends Mock implements Account {}
