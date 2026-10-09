import 'dart:async';

import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/splash/cubit/splash_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// load() waits on a real Future.delayed, so these tests use testWidgets for
// its fake clock: tester.pump advances time without waiting for it.
const _splashDelay = Duration(milliseconds: 1400);
const _phone = '0912345678';

void main() {
  late _MockAuthUseCase authUseCase;
  late SplashCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = SplashCubit(authUseCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  void stubSession({
    required bool signedIn,
    bool? phoneVerified,
    String? phone,
  }) {
    final account = _MockAccount();
    when(() => account.isPhoneVerified).thenReturn(phoneVerified);
    when(() => account.phone).thenReturn(phone);
    when(() => authUseCase.isAppLogin()).thenReturn(signedIn);
    when(() => authUseCase.accountLocal).thenReturn(account);
  }

  void stubSend(Future<PhoneVerificationOutcome> Function() answer) => when(
    () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
  ).thenAnswer((_) => answer());

  Future<void> loadPastDelay(WidgetTester tester) async {
    final loading = cubit.load();
    await tester.pump(_splashDelay);
    await loading;
  }

  testWidgets('waits for the splash delay, then sends a signed-out user to '
      'sign in', (tester) async {
    stubSession(signedIn: false);

    final loading = cubit.load();
    await tester.pump(_splashDelay - const Duration(milliseconds: 1));
    expect(cubit.state.effect, isNull);

    await tester.pump(const Duration(milliseconds: 1));
    await loading;

    expect(cubit.state.isLogin, isFalse);
    expect(cubit.state.effect?.value, isA<SplashNavigateSignInEffect>());
    verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
  });

  testWidgets('sends a signed-in, verified user home', (tester) async {
    stubSession(signedIn: true, phoneVerified: true, phone: _phone);

    await loadPastDelay(tester);

    expect(cubit.state.isLogin, isTrue);
    expect(cubit.state.isPhoneVerified, isTrue);
    expect(cubit.state.effect?.value, isA<SplashNavigateHomeEffect>());
    verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
  });

  testWidgets('sends a code to an unverified user, then asks for it', (
    tester,
  ) async {
    stubSession(signedIn: true, phoneVerified: false, phone: _phone);
    stubSend(() async => PhoneVerificationOutcome.codeSent);

    await loadPastDelay(tester);

    expect(cubit.state.loading, LoadingStatus.complete);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<SplashNavigatePhoneVerificationEffect>());
    expect((effect! as SplashNavigatePhoneVerificationEffect).phone, _phone);
    verify(() => authUseCase.sendCodeVerify(phone: _phone)).called(1);
  });

  testWidgets('a send-code failure publishes a retryable error', (
    tester,
  ) async {
    const error = PhoneVerificationFailure('quota-exceeded');
    stubSession(signedIn: true, phoneVerified: false, phone: _phone);
    when(
      () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
    ).thenThrow(error);

    await loadPastDelay(tester);

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<SplashShowErrorEffect>());
    expect((effect! as SplashShowErrorEffect).error, same(error));
  });

  testWidgets('retrying after a failure resends to the stored phone', (
    tester,
  ) async {
    stubSession(signedIn: true, phoneVerified: false, phone: _phone);
    when(
      () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
    ).thenThrow(const PhoneVerificationFailure('network-request-failed'));
    await loadPastDelay(tester);

    stubSend(() async => PhoneVerificationOutcome.codeSent);
    await cubit.sendCodeVerify();

    expect(
      cubit.state.effect?.value,
      isA<SplashNavigatePhoneVerificationEffect>(),
    );
    verify(() => authUseCase.sendCodeVerify(phone: _phone)).called(2);
  });

  testWidgets('a superseded request does not navigate', (tester) async {
    stubSession(signedIn: true, phoneVerified: false, phone: _phone);
    stubSend(() async => PhoneVerificationOutcome.superseded);

    await loadPastDelay(tester);

    expect(cubit.state.loading, LoadingStatus.loading);
    expect(cubit.state.effect, isNull);
  });

  for (final phone in [null, '']) {
    testWidgets(
      'an unverified user without a phone (${phone == null ? 'null' : 'empty'}) '
      'goes back to sign in',
      (tester) async {
        stubSession(signedIn: true, phoneVerified: false, phone: phone);

        await loadPastDelay(tester);

        expect(cubit.state.effect?.value, isA<SplashNavigateSignInEffect>());
        verifyNever(
          () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
        );
      },
    );
  }

  testWidgets('closing during the delay publishes nothing', (tester) async {
    stubSession(signedIn: true, phoneVerified: true, phone: _phone);

    final loading = cubit.load();
    await cubit.close();
    await tester.pump(_splashDelay);
    await loading;

    expect(cubit.state, SplashState.initial());
  });

  testWidgets('a send result that arrives after close is ignored', (
    tester,
  ) async {
    final pending = Completer<PhoneVerificationOutcome>();
    stubSession(signedIn: true, phoneVerified: false, phone: _phone);
    stubSend(() => pending.future);

    final loading = cubit.load();
    await tester.pump(_splashDelay);
    expect(cubit.state.loading, LoadingStatus.loading);

    await cubit.close();
    pending.complete(PhoneVerificationOutcome.codeSent);
    await loading;

    expect(cubit.state.effect, isNull);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}

class _MockAccount extends Mock implements Account {}
