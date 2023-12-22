class UrlEndPoint {
  static const _AuthEndPoint auth = _AuthEndPoint();
}

class _AuthEndPoint {
  const _AuthEndPoint();

  final String _authPath = '/auth';

  String get login => '$_authPath/sign-in/users';

  String get signUp => '$_authPath/sign-up/users';

  String get refreshToken => '$_authPath/refresh_token';

  String get verifyPhone => '$_authPath/verify-phone';

  String get resetPassword => '$_authPath/reset-password-phone';
}
