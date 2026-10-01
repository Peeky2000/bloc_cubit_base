import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PhoneVerificationRepo)
class FirebasePhoneVerificationRepo implements PhoneVerificationRepo {
  FirebasePhoneVerificationRepo(this._auth);

  final FirebaseAuth _auth;
  String _verificationId = '';
  int _requestGeneration = 0;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    void Function(bool)? onVerificationCompleted,
    void Function()? onCodeSent,
    void Function(PhoneVerificationFailure)? onError,
  }) async {
    final generation = ++_requestGeneration;
    _verificationId = '';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          if (generation != _requestGeneration) return;
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (generation == _requestGeneration) {
              onVerificationCompleted?.call(userCredential.user != null);
            }
          } on FirebaseAuthException catch (error) {
            if (generation == _requestGeneration) {
              onError?.call(PhoneVerificationFailure(error.code));
            }
          } catch (_) {
            if (generation == _requestGeneration) {
              onError?.call(const PhoneVerificationFailure('unknown'));
            }
          }
        },
        verificationFailed: (error) {
          if (generation == _requestGeneration) {
            onError?.call(PhoneVerificationFailure(error.code));
          }
        },
        codeSent: (verificationId, _) {
          if (generation != _requestGeneration) return;
          _verificationId = verificationId;
          onCodeSent?.call();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (generation == _requestGeneration) {
            _verificationId = verificationId;
          }
        },
      );
    } on FirebaseAuthException catch (error) {
      if (generation == _requestGeneration) {
        throw PhoneVerificationFailure(error.code);
      }
    } catch (_) {
      if (generation == _requestGeneration) {
        throw const PhoneVerificationFailure('unknown');
      }
    }
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
