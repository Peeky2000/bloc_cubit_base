/// Platform-agnostic phone verification contract used by auth flows.
abstract class PhoneVerificationRepo {
  /// Starts verification for an E.164 [phoneNumber] and completes once, when
  /// the platform has either sent an SMS code or verified the number by
  /// itself.
  ///
  /// Throws [PhoneVerificationFailure] when verification cannot start or the
  /// platform reports a failure. A newer call supersedes an older one; the
  /// older call then completes with [PhoneVerificationOutcome.superseded].
  Future<PhoneVerificationOutcome> sendCode({required String phoneNumber});

  /// Confirms the SMS code of the latest [sendCode] call and returns the
  /// platform ID token, or null when the platform returned no user.
  Future<String?> verifyOtp({required String otp});
}

/// How a [PhoneVerificationRepo.sendCode] call ended.
enum PhoneVerificationOutcome {
  /// An SMS code was sent; ask the user for it.
  codeSent,

  /// The platform verified the number without a code.
  autoVerified,

  /// A newer request replaced this one; the caller should do nothing.
  superseded,
}

/// Safe failure category; infrastructure exceptions stay in the data layer.
class PhoneVerificationFailure implements Exception {
  const PhoneVerificationFailure(this.code);

  final String code;

  @override
  String toString() => 'PhoneVerificationFailure($code)';
}
