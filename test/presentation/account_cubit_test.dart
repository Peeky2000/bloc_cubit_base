import 'dart:async';

import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/account/cubit/account_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Spec: docs/specs/001-account/tech.md, section 15.
void main() {
  late _MockAuthUseCase authUseCase;
  late AccountCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = AccountCubit(authUseCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  test('starts in the initial state', () {
    expect(cubit.state, AccountState.initial());
  });

  test('AC2: load reads email, phone and role from the session', () async {
    final account = _MockAccount();
    when(() => account.email).thenReturn('an@example.com');
    when(() => account.phone).thenReturn('+84912345678');
    when(() => account.role).thenReturn('owner');
    when(() => authUseCase.accountLocal).thenReturn(account);

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.email, 'an@example.com');
    expect(cubit.state.phone, '+84912345678');
    expect(cubit.state.role, 'owner');
  });

  test('AC3: tapping sign out asks to confirm and does not sign out', () {
    cubit.onTapLogout();

    expect(cubit.state.effect?.value, isA<AccountConfirmLogoutEffect>());
    verifyNever(() => authUseCase.logout());
  });

  test('AC3: confirming signs out, then goes to sign-in', () async {
    when(() => authUseCase.logout()).thenAnswer((_) async {});

    await cubit.logout();

    verify(() => authUseCase.logout()).called(1);
    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.effect?.value, isA<AccountNavigateSignInEffect>());
  });

  test('AC4: a failed sign-out shows the error and stays', () async {
    final error = StateError('storage locked');
    when(() => authUseCase.logout()).thenThrow(error);

    await cubit.logout();

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<AccountShowErrorEffect>());
    expect((effect! as AccountShowErrorEffect).error, same(error));
  });

  test('a second sign-out while one is running is ignored', () async {
    final pending = Completer<void>();
    when(() => authUseCase.logout()).thenAnswer((_) => pending.future);

    final first = cubit.logout();
    await cubit.logout();
    pending.complete();
    await first;

    verify(() => authUseCase.logout()).called(1);
  });

  test('a sign-out result after close is ignored', () async {
    final pending = Completer<void>();
    when(() => authUseCase.logout()).thenAnswer((_) => pending.future);

    final running = cubit.logout();
    final beforeClose = cubit.state;
    await cubit.close();
    pending.complete();
    await running;

    expect(cubit.state, beforeClose);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}

class _MockAccount extends Mock implements Account {}
