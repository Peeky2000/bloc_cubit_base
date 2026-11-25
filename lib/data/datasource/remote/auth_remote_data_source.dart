import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/datasource/remote/url_end_point.dart';
import 'package:bloc_cubit_base/data/model/response/auth/login_response_model.dart';
import 'package:bloc_cubit_base/data/model/response/base_response_model.dart';
import 'package:injectable/injectable.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel?> appLogin({
    required String phone,
    required String password,
  });
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiHandler _apiHandler;

  AuthRemoteDataSourceImpl(this._apiHandler);

  @override
  Future<LoginResponseModel?> appLogin({
    required String phone,
    required String password,
  }) async {
    Map<String, String> body = {};
    body['phone'] = phone;
    body['password'] = password;
    BaseResponseModel<LoginResponseModel> result = await _apiHandler.post(
      UrlEndPoint.auth.login,
      body: body,
      parser: (json) => LoginResponseModel.fromJson(json),
    );
    return result.data;
  }
}
