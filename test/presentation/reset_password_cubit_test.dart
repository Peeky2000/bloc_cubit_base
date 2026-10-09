import 'dart:async';

import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/reset_password/cubit/reset_password_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// The resend counter runs on Timer.periodic, so timer tests run on the
// testWidgets fake clock. Its pending-timer check runs before tearDown, so
// testWithClock closes the cubit in the body: a timer that close() leaves
// running fails the test.
const _phone = '0912345678';
const _idToken = 'id-token';
const _password = 'Password@1';
const _tick = Duration(seconds: 1);

void main() {
  late _MockAuthUseCase authUseCase;
  late ResetPasswordCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = ResetPasswordCubit(authUseCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  void testWithClock(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      await body(tester);
      if (!cubit.isClosed) {
        await cubit.close();
      }
    });
  }

  void stubSend(Future<PhoneVerificationOutcome> Function() answer) => when(
    () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
  ).thenAnswer((_) => answer());

  void stubVerify(Future<String?> Function() answer) => when(
    () => authUseCase.verifyOTP(otp: any(named: 'otp')),
  ).thenAnswer((_) => answer());

  void stubReset() => when(
    () => authUseCase.resetPasswordPhone(
      idToken: any(named: 'idToken'),
      newPassword: any(named: 'newPassword'),
    ),
  ).thenAnswer((_) async {});

  Future<void> sendCode() async {
    stubSend(() async => PhoneVerificationOutcome.codeSent);
    await cubit.onTapSendRequestLogin(_phone);
  }

  Future<void> verifyCode() async {
    stubVerify(() async => _idToken);
    await cubit.onCompleteOTP('123456');
  }

  group('phone page', () {
    test('an empty phone is required and sends nothing', () async {
      await cubit.onTapSendRequestLogin('');

      expect(cubit.state.phoneError, PhoneInputError.required);
      expect(cubit.state.effect, isNull);
      verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
    });

    test('a malformed phone is invalid and sends nothing', () async {
      await cubit.onTapSendRequestLogin('12345');

      expect(cubit.state.phoneError, PhoneInputError.invalid);
      expect(cubit.state.effect, isNull);
      verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
    });

    testWithClock('a sent code advances once and starts the counter', (
      tester,
    ) async {
      await sendCode();

      expect(cubit.state.phoneError, isNull);
      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.phone, _phone);
      expect(cubit.state.counter, Constant.timePeriodOTP);
      final effect = cubit.state.effect?.value;
      expect(effect, isA<ResetPasswordChangePageEffect>());
      expect((effect! as ResetPasswordChangePageEffect).delta, 1);
      verify(() => authUseCase.sendCodeVerify(phone: _phone)).called(1);

      await tester.pump(_tick);
      expect(cubit.state.counter, Constant.timePeriodOTP - 1);
    });

    testWithClock('the counter stops at zero', (tester) async {
      await sendCode();

      await tester.pump(_tick * (Constant.timePeriodOTP + 5));

      expect(cubit.state.counter, 0);
    });

    test('a send failure offers to retry sending the code', () async {
      const error = PhoneVerificationFailure('quota-exceeded');
      when(
        () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
      ).thenThrow(error);

      await cubit.onTapSendRequestLogin(_phone);

      expect(cubit.state.loading, LoadingStatus.error);
      expect(cubit.state.phone, isEmpty);
      final effect = cubit.state.effect?.value as ResetPasswordShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, ResetPasswordRetryAction.sendVerificationCode);
    });

    testWithClock('retrying after a first send failure still advances', (
      tester,
    ) async {
      when(
        () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
      ).thenThrow(const PhoneVerificationFailure('network-request-failed'));
      await cubit.onTapSendRequestLogin(_phone);

      stubSend(() async => PhoneVerificationOutcome.codeSent);
      await cubit.resendCode();

      final effect = cubit.state.effect?.value;
      expect(effect, isA<ResetPasswordChangePageEffect>());
      expect(cubit.state.phone, _phone);
    });

    test('a superseded send neither advances nor stores the phone', () async {
      stubSend(() async => PhoneVerificationOutcome.superseded);

      await cubit.onTapSendRequestLogin(_phone);

      expect(cubit.state.phone, isEmpty);
      expect(cubit.state.effect, isNull);
    });
  });

  group('code page', () {
    test('resend before any phone was sent does nothing', () async {
      await cubit.resendCode();

      verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
    });

    testWithClock('resend restarts the counter without advancing again', (
      tester,
    ) async {
      await sendCode();
      final advance = cubit.state.effect;
      await tester.pump(_tick * 10);
      expect(cubit.state.counter, Constant.timePeriodOTP - 10);

      await cubit.resendCode();

      expect(cubit.state.effect, same(advance));
      expect(cubit.state.counter, Constant.timePeriodOTP);
      verify(() => authUseCase.sendCodeVerify(phone: _phone)).called(2);
    });

    testWithClock('resend is ignored while a code is being verified', (
      tester,
    ) async {
      await sendCode();
      final pending = Completer<String?>();
      stubVerify(() => pending.future);
      final verifying = cubit.onCompleteOTP('123456');
      expect(cubit.state.isVerifying, isTrue);

      await cubit.resendCode();
      await tester.pump(_tick * 3);

      verify(() => authUseCase.sendCodeVerify(phone: _phone)).called(1);
      expect(cubit.state.counter, Constant.timePeriodOTP);

      pending.complete(_idToken);
      await verifying;
    });

    testWithClock('a valid code stops the counter and advances', (
      tester,
    ) async {
      await sendCode();
      final advanceToCode = cubit.state.effect!;

      await verifyCode();

      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.counter, 0);
      final effect = cubit.state.effect!;
      expect(effect.revision, advanceToCode.revision + 1);
      expect((effect.value as ResetPasswordChangePageEffect).delta, 1);

      await tester.pump(_tick * 3);
      expect(cubit.state.counter, 0);
    });

    testWithClock('an invalid code publishes the invalid-code effect', (
      tester,
    ) async {
      await sendCode();
      when(
        () => authUseCase.verifyOTP(otp: any(named: 'otp')),
      ).thenThrow(const PhoneVerificationFailure('invalid-verification-code'));

      await cubit.onCompleteOTP('000000');

      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.effect?.value, isA<ResetPasswordInvalidOtpEffect>());

      await tester.pump(_tick);
      expect(cubit.state.counter, Constant.timePeriodOTP - 1);
    });

    testWithClock('a code without an ID token does not advance', (
      tester,
    ) async {
      await sendCode();
      final advanceToCode = cubit.state.effect;
      stubVerify(() async => null);

      await cubit.onCompleteOTP('123456');

      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.effect, same(advanceToCode));
    });

    test('going back publishes a backward page change', () {
      cubit.onTapBackPage();

      final effect = cubit.state.effect?.value as ResetPasswordChangePageEffect;
      expect(effect.delta, -1);
    });

    testWithClock('leaving the code page stops the counter', (tester) async {
      await sendCode();

      cubit.onChangePage(1);
      await tester.pump(_tick);
      expect(cubit.state.counter, Constant.timePeriodOTP - 1);

      cubit.onChangePage(0);
      await tester.pump(_tick * 3);
      expect(cubit.state.counter, Constant.timePeriodOTP - 1);
    });

    testWithClock('close cancels the running counter', (tester) async {
      await sendCode();
      await tester.pump(_tick);

      await cubit.close();
      // An uncancelled tick would emit after close and throw.
      await tester.pump(_tick * 3);

      expect(cubit.state.counter, Constant.timePeriodOTP - 1);
    });
  });

  group('new password page', () {
    test('empty passwords are required and nothing is reset', () async {
      await cubit.onTapResetPassword(newPassword: '', confirmPassword: '');

      expect(cubit.state.newPasswordError, PasswordInputError.required);
      expect(cubit.state.confirmPasswordError, PasswordInputError.required);
    });

    testWithClock('mismatched passwords report a mismatch and reset nothing', (
      tester,
    ) async {
      await sendCode();
      await verifyCode();

      await cubit.onTapResetPassword(
        newPassword: _password,
        confirmPassword: 'Password@2',
      );

      expect(cubit.state.newPasswordError, isNull);
      expect(cubit.state.confirmPasswordError, PasswordInputError.mismatch);
      verifyNever(
        () => authUseCase.resetPasswordPhone(
          idToken: any(named: 'idToken'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test('nothing is reset before the code is verified', () async {
      stubReset();

      await cubit.onTapResetPassword(
        newPassword: _password,
        confirmPassword: _password,
      );

      expect(cubit.state.confirmPasswordError, isNull);
      verifyNever(
        () => authUseCase.resetPasswordPhone(
          idToken: any(named: 'idToken'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWithClock('a successful reset publishes the success effect', (
      tester,
    ) async {
      stubReset();
      await sendCode();
      await verifyCode();

      await cubit.onTapResetPassword(
        newPassword: _password,
        confirmPassword: _password,
      );

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.effect?.value, isA<ResetPasswordSucceededEffect>());
      verify(
        () => authUseCase.resetPasswordPhone(
          idToken: _idToken,
          newPassword: _password,
        ),
      ).called(1);
    });

    testWithClock('a reset failure offers to retry the reset', (tester) async {
      final error = StateError('reset failed');
      when(
        () => authUseCase.resetPasswordPhone(
          idToken: any(named: 'idToken'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(error);
      await sendCode();
      await verifyCode();

      await cubit.onTapResetPassword(
        newPassword: _password,
        confirmPassword: _password,
      );

      expect(cubit.state.loading, LoadingStatus.error);
      final effect = cubit.state.effect?.value as ResetPasswordShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, ResetPasswordRetryAction.resetPassword);
    });
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
