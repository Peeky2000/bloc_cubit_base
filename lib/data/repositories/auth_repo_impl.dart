import 'package:bloc_cubit_base/data/datasource/remote/auth_remote_data_source.dart';
import 'package:bloc_cubit_base/data/model/response/auth/sign_up_response_model.dart';
import 'package:bloc_cubit_base/data/model/response/profile/update_account_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/auth/login.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/repositories/auth_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepo)
class AuthRepoImpl implements AuthRepo {
  final AuthRemoteDataSource _authRemoteDataSource;

  AuthRepoImpl(this._authRemoteDataSource);

  @override
  Future<Login?> appLogin({required String phone, required String password}) {
    return _authRemoteDataSource.appLogin(phone: phone, password: password);
  }

  @override
  Future<SignUpResponseModel?> userSignUp({required SignUpParams request}) {
    return _authRemoteDataSource.userSignUp(request: request);
  }

  @override
  Future<UpdateAccountResponseModel?> verifyPhone({required String idToken}) {
    return _authRemoteDataSource.verifyPhone(idToken: idToken);
  }

  @override
  Future<void> resetPasswordPhone({
    required String idToken,
    required String newPassword,
  }) {
    return _authRemoteDataSource.resetPasswordPhone(
      idToken: idToken,
      newPassword: newPassword,
    );
  }
}
