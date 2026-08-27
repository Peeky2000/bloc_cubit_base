class UrlEndPoint {
  static const AuthEndPoint auth = AuthEndPoint();
}

class AuthEndPoint {
  const AuthEndPoint();

  final String _authPath = '/auth';

  String get login => '$_authPath/sign-in/users';

  String get signUp => '$_authPath/sign-up/users';

  String get refreshToken => '$_authPath/refresh_token';

  String get verifyPhone => '$_authPath/verify-phone';

  String get resetPassword => '$_authPath/reset-password-phone';
}
