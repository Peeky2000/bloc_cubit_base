import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/user_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _FakePhoneVerificationRepo phoneRepo;
  late AuthUseCase useCase;

  setUp(() {
    phoneRepo = _FakePhoneVerificationRepo();
    useCase = AuthUseCase(_MockAuthRepo(), _MockUserRepo(), phoneRepo);
  });

  test('normalizes a local phone and forwards code-sent callback', () async {
    var codeSent = false;
    await useCase.sendCodeVerify(
      phone: '0912345678',
      onComplete: () => codeSent = true,
    );

    expect(phoneRepo.phoneNumber, '+84912345678');
    phoneRepo.onCodeSent?.call();
    expect(codeSent, isTrue);
  });

  test('keeps a typed verification failure at the domain boundary', () async {
    PhoneVerificationFailure? received;
    await useCase.sendCodeVerify(
      phone: '+84912345678',
      onError: (error) => received = error,
    );

    expect(phoneRepo.phoneNumber, '+84912345678');
    phoneRepo.onError?.call(const PhoneVerificationFailure('quota-exceeded'));
    expect(received?.code, 'quota-exceeded');
  });

  test('delegates OTP verification without platform types', () async {
    phoneRepo.token = 'firebase-id-token';

    expect(await useCase.verifyOTP(otp: '123456'), 'firebase-id-token');
    expect(phoneRepo.otp, '123456');
  });
}

class _MockAuthRepo extends Mock implements AuthRepo {}

class _MockUserRepo extends Mock implements UserRepo {}

class _FakePhoneVerificationRepo implements PhoneVerificationRepo {
  String? phoneNumber;
  String? otp;
  String? token;
  void Function()? onCodeSent;
  void Function(PhoneVerificationFailure)? onError;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    void Function(bool)? onVerificationCompleted,
    void Function()? onCodeSent,
    void Function(PhoneVerificationFailure)? onError,
  }) async {
    this.phoneNumber = phoneNumber;
    this.onCodeSent = onCodeSent;
    this.onError = onError;
  }

  @override
  Future<String?> verifyOtp({required String otp}) async {
    this.otp = otp;
    return token;
  }
}
