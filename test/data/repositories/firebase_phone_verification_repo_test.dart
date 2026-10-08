import 'package:bloc_cubit_base/data/repositories/firebase_phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Captures the callbacks Firebase receives so a test can play the platform.
class _Call {
  late void Function(PhoneAuthCredential) completed;
  late void Function(FirebaseAuthException) failed;
  late void Function(String, int?) codeSent;
}

void main() {
  late _MockFirebaseAuth auth;
  late FirebasePhoneVerificationRepo repo;
  late List<_Call> calls;

  setUpAll(() {
    registerFallbackValue(_FakeCredential());
  });

  setUp(() {
    auth = _MockFirebaseAuth();
    repo = FirebasePhoneVerificationRepo(auth);
    calls = [];
    when(
      () => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        verificationCompleted: any(named: 'verificationCompleted'),
        verificationFailed: any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      calls.add(
        _Call()
          ..completed =
              args[#verificationCompleted] as void Function(PhoneAuthCredential)
          ..failed =
              args[#verificationFailed] as void Function(FirebaseAuthException)
          ..codeSent = args[#codeSent] as void Function(String, int?),
      );
    });
  });

  test('OTP before a code was sent returns a domain failure', () async {
    await expectLater(
      repo.verifyOtp(otp: '123456'),
      throwsA(
        isA<PhoneVerificationFailure>().having(
          (error) => error.code,
          'code',
          'verification-not-started',
        ),
      ),
    );
  });

  test('completes with codeSent when Firebase sends the SMS', () async {
    final result = repo.sendCode(phoneNumber: '+84912345678');
    await pumpEventQueue();

    calls.single.codeSent('verification-id', null);

    expect(await result, PhoneVerificationOutcome.codeSent);
  });

  test(
    'completes with autoVerified when Firebase signs in by itself',
    () async {
      final credential = _MockUserCredential();
      when(() => credential.user).thenReturn(_MockUser());
      when(
        () => auth.signInWithCredential(any()),
      ).thenAnswer((_) async => credential);

      final result = repo.sendCode(phoneNumber: '+84912345678');
      await pumpEventQueue();
      calls.single.completed(_FakeCredential());

      expect(await result, PhoneVerificationOutcome.autoVerified);
    },
  );

  test('a Firebase verification failure becomes a domain failure', () async {
    final result = repo.sendCode(phoneNumber: '+84912345678');
    await pumpEventQueue();

    calls.single.failed(FirebaseAuthException(code: 'quota-exceeded'));

    await expectLater(
      result,
      throwsA(
        isA<PhoneVerificationFailure>().having(
          (e) => e.code,
          'code',
          'quota-exceeded',
        ),
      ),
    );
  });

  test('a thrown platform failure is mapped to a domain failure', () async {
    when(
      () => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        verificationCompleted: any(named: 'verificationCompleted'),
        verificationFailed: any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    await expectLater(
      repo.sendCode(phoneNumber: '+84912345678'),
      throwsA(
        isA<PhoneVerificationFailure>().having(
          (error) => error.code,
          'code',
          'network-request-failed',
        ),
      ),
    );
  });

  test('a newer request supersedes the older one', () async {
    final first = repo.sendCode(phoneNumber: 'first');
    await pumpEventQueue();
    final second = repo.sendCode(phoneNumber: 'second');
    await pumpEventQueue();

    expect(await first, PhoneVerificationOutcome.superseded);

    calls.first.codeSent('stale-id', null);
    calls.first.failed(FirebaseAuthException(code: 'expired'));
    calls.last.codeSent('current-id', null);
    expect(await second, PhoneVerificationOutcome.codeSent);
  });

  test('OTP is checked against the latest request', () async {
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(() => credential.user).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'id-token');
    PhoneAuthCredential? used;
    when(() => auth.signInWithCredential(any())).thenAnswer((invocation) async {
      used = invocation.positionalArguments.single as PhoneAuthCredential;
      return credential;
    });

    final result = repo.sendCode(phoneNumber: '+84912345678');
    await pumpEventQueue();
    calls.single.codeSent('current-id', null);
    await result;

    expect(await repo.verifyOtp(otp: '123456'), 'id-token');
    expect(used?.verificationId, 'current-id');
    expect(used?.smsCode, '123456');
  });
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakeCredential extends Fake implements PhoneAuthCredential {}
