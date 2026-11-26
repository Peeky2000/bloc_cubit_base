class UrlEndPoint {
  static const AuthEndPoint auth = AuthEndPoint();
}

class AuthEndPoint {
  const AuthEndPoint();

  final String _authPath = '/auth';

  String get login => '$_authPath/sign-in/users';

  String get refreshToken => '$_authPath/refresh_token';
}
