import 'dart:async';

import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PhoneVerificationRepo)
class FirebasePhoneVerificationRepo implements PhoneVerificationRepo {
  FirebasePhoneVerificationRepo(this._auth);

  final FirebaseAuth _auth;
  String _verificationId = '';
  int _requestGeneration = 0;
  Completer<PhoneVerificationOutcome>? _pending;

  @override
  Future<PhoneVerificationOutcome> sendCode({required String phoneNumber}) {
    final generation = ++_requestGeneration;
    _verificationId = '';
    _pending?.complete(PhoneVerificationOutcome.superseded);
    final result = Completer<PhoneVerificationOutcome>();
    _pending = result;

    bool isCurrent() => generation == _requestGeneration && !result.isCompleted;
    void succeed(PhoneVerificationOutcome outcome) {
      if (isCurrent()) result.complete(outcome);
    }

    void fail(String code) {
      if (isCurrent()) result.completeError(PhoneVerificationFailure(code));
    }

    // Future.sync also routes a synchronous SDK throw into catchError.
    Future.sync(
      () => _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          if (!isCurrent()) return;
          try {
            final user = await _auth.signInWithCredential(credential);
            if (user.user != null) {
              succeed(PhoneVerificationOutcome.autoVerified);
            } else {
              fail('auto-verification-without-user');
            }
          } on FirebaseAuthException catch (error) {
            fail(error.code);
          } catch (_) {
            fail('unknown');
          }
        },
        verificationFailed: (error) => fail(error.code),
        codeSent: (verificationId, _) {
          if (!isCurrent()) return;
          _verificationId = verificationId;
          succeed(PhoneVerificationOutcome.codeSent);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (generation == _requestGeneration) {
            _verificationId = verificationId;
          }
        },
      ),
    ).catchError((Object error) {
      fail(error is FirebaseAuthException ? error.code : 'unknown');
    });

    return result.future;
  }

  @override
  Future<String?> verifyOtp({required String otp}) async {
    if (_verificationId.isEmpty) {
      throw const PhoneVerificationFailure('verification-not-started');
    }
    try {
      final credential = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: otp,
        ),
      );
      return credential.user?.getIdToken();
    } on FirebaseAuthException catch (error) {
      throw PhoneVerificationFailure(error.code);
    } catch (_) {
      throw const PhoneVerificationFailure('unknown');
    }
  }
}
