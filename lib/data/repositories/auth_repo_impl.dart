import 'package:delivery_go/data/datasource/local/token_provider.dart';
import 'package:delivery_go/data/datasource/remote/auth_remote_data_source.dart';
import 'package:delivery_go/data/model/request/sign_up_request_model.dart';
import 'package:delivery_go/data/model/response/auth/sign_up_response_model.dart';
import 'package:delivery_go/data/model/response/auth/token_wrapper_response_model.dart';
import 'package:delivery_go/data/model/response/profile/update_account_response_model.dart';
import 'package:delivery_go/data/model/response/token_response_model.dart';
import 'package:delivery_go/domain/entities/auth/login.dart';
import 'package:delivery_go/domain/entities/auth/token_wrapper.dart';
import 'package:delivery_go/domain/repositories/auth_repo.dart';
import 'package:sli_common/extension/extensions.dart';

class AuthRepoImpl implements AuthRepo {
  final AuthRemoteDataSource _authRemoteDataSource;
  final TokenProvider _tokenProvider;

  AuthRepoImpl(this._authRemoteDataSource, this._tokenProvider);

  @override
  Future<Login?> appLogin({required String phone, required String password}) {
    return _authRemoteDataSource.appLogin(phone: phone, password: password);
  }

  @override
  Future<void> setTokenToLocal({TokenWrapper? tokenWrapper}) async {
    if (tokenWrapper is TokenWrapperResponseModel?) {
      await _tokenProvider
          .setToken(TokenResponseModel.fromTokenWrapperResponse(tokenWrapper));
    }
  }

  @override
  bool isAppLogin() {
    return _tokenProvider.token.accessToken.isNotNullOrEmpty;
  }

  @override
  Future<SignUpResponseModel?> userSignUp(
      {required SignUpRequestModel request}) {
    return _authRemoteDataSource.userSignUp(request: request);
  }

  @override
  Future<UpdateAccountResponseModel?> verifyPhone({required String idToken}) {
    return _authRemoteDataSource.verifyPhone(idToken: idToken);
  }

  @override
  Future<void> resetPasswordPhone(
      {required String idToken, required String newPassword}) {
    return _authRemoteDataSource.resetPasswordPhone(
        idToken: idToken, newPassword: newPassword);
  }
}
