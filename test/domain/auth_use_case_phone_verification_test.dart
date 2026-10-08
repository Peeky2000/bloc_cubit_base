import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _FakePhoneVerificationRepo phoneRepo;
  late AuthUseCase useCase;

  setUp(() {
    phoneRepo = _FakePhoneVerificationRepo();
    useCase = AuthUseCase(_MockAuthRepo(), _MockSessionRepo(), phoneRepo);
  });

  test('normalizes a local phone and returns the outcome', () async {
    phoneRepo.outcome = PhoneVerificationOutcome.codeSent;

    final outcome = await useCase.sendCodeVerify(phone: '0912345678');

    expect(phoneRepo.phoneNumber, '+84912345678');
    expect(outcome, PhoneVerificationOutcome.codeSent);
  });

  test('keeps a typed verification failure at the domain boundary', () async {
    phoneRepo.failure = const PhoneVerificationFailure('quota-exceeded');

    await expectLater(
      useCase.sendCodeVerify(phone: '+84912345678'),
      throwsA(
        isA<PhoneVerificationFailure>().having(
          (error) => error.code,
          'code',
          'quota-exceeded',
        ),
      ),
    );
    expect(phoneRepo.phoneNumber, '+84912345678');
  });

  test('delegates OTP verification without platform types', () async {
    phoneRepo.token = 'firebase-id-token';

    expect(await useCase.verifyOTP(otp: '123456'), 'firebase-id-token');
    expect(phoneRepo.otp, '123456');
  });
}

class _MockAuthRepo extends Mock implements AuthRepo {}

class _MockSessionRepo extends Mock implements SessionRepo {}

class _FakePhoneVerificationRepo implements PhoneVerificationRepo {
  String? phoneNumber;
  String? otp;
  String? token;
  PhoneVerificationOutcome outcome = PhoneVerificationOutcome.codeSent;
  PhoneVerificationFailure? failure;

  @override
  Future<PhoneVerificationOutcome> sendCode({
    required String phoneNumber,
  }) async {
    this.phoneNumber = phoneNumber;
    final error = failure;
    if (error != null) throw error;
    return outcome;
  }

  @override
  Future<String?> verifyOtp({required String otp}) async {
    this.otp = otp;
    return token;
  }
}
