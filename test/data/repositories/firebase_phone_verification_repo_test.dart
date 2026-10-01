import 'dart:async';

import 'package:bloc_cubit_base/data/repositories/firebase_phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockFirebaseAuth auth;
  late FirebasePhoneVerificationRepo repo;

  setUp(() {
    auth = _MockFirebaseAuth();
    repo = FirebasePhoneVerificationRepo(auth);
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

  test('Firebase verification failure is mapped to a domain failure', () async {
    when(
      () => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        verificationCompleted: any(named: 'verificationCompleted'),
        verificationFailed: any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
      ),
    ).thenAnswer((invocation) async {
      final failed =
          invocation.namedArguments[#verificationFailed]
              as void Function(FirebaseAuthException);
      failed(FirebaseAuthException(code: 'quota-exceeded'));
    });

    PhoneVerificationFailure? received;
    await repo.sendCode(
      phoneNumber: '+84912345678',
      onError: (error) => received = error,
    );

    expect(received?.code, 'quota-exceeded');
  });

  test(
    'a thrown platform failure is mapped before reaching the use case',
    () async {
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
    },
  );

  test('stale code-sent callback cannot replace a newer request', () async {
    final callbacks = <void Function(String, int?)>[];
    when(
      () => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        verificationCompleted: any(named: 'verificationCompleted'),
        verificationFailed: any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
      ),
    ).thenAnswer((invocation) async {
      callbacks.add(
        invocation.namedArguments[#codeSent] as void Function(String, int?),
      );
    });

    var notified = 0;
    await repo.sendCode(phoneNumber: 'first', onCodeSent: () => notified++);
    await repo.sendCode(phoneNumber: 'second', onCodeSent: () => notified++);

    callbacks.first('stale-id', null);
    expect(notified, 0);
    callbacks.last('current-id', null);
    expect(notified, 1);
  });

  test('a stale request failure does not fail the newer flow', () async {
    final firstRequestResult = Completer<void>();
    var requestCount = 0;
    when(
      () => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        verificationCompleted: any(named: 'verificationCompleted'),
        verificationFailed: any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
      ),
    ).thenAnswer((_) {
      requestCount++;
      return requestCount == 1
          ? firstRequestResult.future
          : Future<void>.value();
    });

    final oldRequest = repo.sendCode(phoneNumber: 'first');
    await repo.sendCode(phoneNumber: 'second');
    firstRequestResult.completeError(FirebaseAuthException(code: 'expired'));

    await expectLater(oldRequest, completes);
  });
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}
