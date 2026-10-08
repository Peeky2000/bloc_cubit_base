import 'dart:async';

import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/presentation/confirm_information/cubit/confirm_information_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockAuthUseCase authUseCase;
  late ConfirmInformationCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = ConfirmInformationCubit(authUseCase);
    cubit.initialize(phone: '0912345678');
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  void stubSend(Future<PhoneVerificationOutcome> Function() answer) => when(
    () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
  ).thenAnswer((_) => answer());

  test('resets the resend timer after a code is sent', () async {
    stubSend(() async => PhoneVerificationOutcome.codeSent);

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.counter, Constant.timePeriodOTP);
    expect(cubit.state.effect, isNull);
  });

  test('publishes an error effect when sending the code fails', () async {
    const error = PhoneVerificationFailure('quota-exceeded');
    stubSend(() async => throw error);

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<ConfirmInformationShowErrorEffect>());
    expect((effect! as ConfirmInformationShowErrorEffect).error, same(error));
  });

  test('maps a thrown platform failure to the same error effect', () async {
    final error = StateError('platform failure');
    when(
      () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
    ).thenThrow(error);

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<ConfirmInformationShowErrorEffect>());
    expect((effect! as ConfirmInformationShowErrorEffect).error, same(error));
  });

  test('a superseded request changes nothing', () async {
    stubSend(() async => PhoneVerificationOutcome.superseded);

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.loading);
    expect(cubit.state.effect, isNull);
  });

  test('a result that arrives after close is ignored', () async {
    final pending = Completer<PhoneVerificationOutcome>();
    stubSend(() => pending.future);

    final sending = cubit.sendCodeVerify();
    await cubit.close();
    pending.complete(PhoneVerificationOutcome.codeSent);

    await expectLater(sending, completes);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
