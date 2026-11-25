import 'package:bloc_cubit_base/domain/entities/auth/login.dart';

abstract class AuthRepo {
  Future<Login?> appLogin({required String phone, required String password});
}
