/// Platform-agnostic phone verification contract used by auth flows.
abstract class PhoneVerificationRepo {
  Future<void> sendCode({
    required String phoneNumber,
    void Function(bool)? onVerificationCompleted,
    void Function()? onCodeSent,
    void Function(PhoneVerificationFailure)? onError,
  });

  Future<String?> verifyOtp({required String otp});
}

/// Safe failure category; infrastructure exceptions stay in the data layer.
class PhoneVerificationFailure implements Exception {
  const PhoneVerificationFailure(this.code);

  final String code;

  @override
  String toString() => 'PhoneVerificationFailure($code)';
}
