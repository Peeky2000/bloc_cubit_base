import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/confirm_information/cubit/confirm_information_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  test('resets the resend timer after codeSent succeeds', () async {
    when(
      () => authUseCase.sendCodeVerify(
        phone: any(named: 'phone'),
        onComplete: any(named: 'onComplete'),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((invocation) async {
      final onComplete = invocation.namedArguments[#onComplete] as Function()?;
      onComplete?.call();
    });

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.complete);
    expect(cubit.state.counter, Constant.timePeriodOTP);
    expect(cubit.state.effect, isNull);
  });

  test('publishes an error effect when sending the code fails', () async {
    final error = FirebaseAuthException(code: 'quota-exceeded');
    when(
      () => authUseCase.sendCodeVerify(
        phone: any(named: 'phone'),
        onComplete: any(named: 'onComplete'),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((invocation) async {
      final onError =
          invocation.namedArguments[#onError]
              as Function(FirebaseAuthException)?;
      onError?.call(error);
    });

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<ConfirmInformationShowErrorEffect>());
    expect((effect! as ConfirmInformationShowErrorEffect).error, same(error));
  });

  test('maps a thrown send-code failure to the same error effect', () async {
    final error = StateError('platform failure');
    when(
      () => authUseCase.sendCodeVerify(
        phone: any(named: 'phone'),
        onComplete: any(named: 'onComplete'),
        onError: any(named: 'onError'),
      ),
    ).thenThrow(error);

    await cubit.sendCodeVerify();

    expect(cubit.state.loading, LoadingStatus.error);
    final effect = cubit.state.effect?.value;
    expect(effect, isA<ConfirmInformationShowErrorEffect>());
    expect((effect! as ConfirmInformationShowErrorEffect).error, same(error));
  });

  test('ignores delayed Firebase callbacks after close', () async {
    Function()? delayedCallback;
    when(
      () => authUseCase.sendCodeVerify(
        phone: any(named: 'phone'),
        onComplete: any(named: 'onComplete'),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((invocation) async {
      delayedCallback = invocation.namedArguments[#onComplete] as Function()?;
    });

    await cubit.sendCodeVerify();
    await cubit.close();

    expect(delayedCallback, isNotNull);
    expect(delayedCallback, returnsNormally);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
