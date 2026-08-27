import 'package:bloc_cubit_base/domain/entities/auth/token_auth.dart';

abstract class TokenWrapper {
  TokenAuth? get access;

  TokenAuth? get refresh;
}
