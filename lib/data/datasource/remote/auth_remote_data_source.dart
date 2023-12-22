import 'package:delivery_go/data/datasource/remote/api_client.dart';
import 'package:delivery_go/data/datasource/remote/url_end_point.dart';
import 'package:delivery_go/data/model/request/sign_up_request_model.dart';
import 'package:delivery_go/data/model/response/auth/login_response_model.dart';
import 'package:delivery_go/data/model/response/auth/sign_up_response_model.dart';
import 'package:delivery_go/data/model/response/base_response_model.dart';
import 'package:delivery_go/data/model/response/profile/update_account_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel?> appLogin(
      {required String phone, required String password});

  Future<SignUpResponseModel?> userSignUp(
      {required SignUpRequestModel request});

  Future<UpdateAccountResponseModel?> verifyPhone({required String idToken});

  Future<void> resetPasswordPhone(
      {required String idToken, required String newPassword});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiHandler _apiHandler;

  AuthRemoteDataSourceImpl(this._apiHandler);

  @override
  Future<LoginResponseModel?> appLogin(
      {required String phone, required String password}) async {
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

  @override
  Future<SignUpResponseModel?> userSignUp(
      {required SignUpRequestModel request}) async {
    Map<String, dynamic> body = request.toJson();
    BaseResponseModel<SignUpResponseModel> result = await _apiHandler.post(
      UrlEndPoint.auth.signUp,
      body: body,
      parser: (json) => SignUpResponseModel.fromJson(json),
    );
    return result.data;
  }

  @override
  Future<UpdateAccountResponseModel?> verifyPhone(
      {required String idToken}) async {
    Map<String, String> body = {};
    body['idToken'] = idToken;
    BaseResponseModel<UpdateAccountResponseModel> response =
        await _apiHandler.post(
      UrlEndPoint.auth.verifyPhone,
      body: body,
      parser: (json) => UpdateAccountResponseModel.fromJson(json),
    );
    return response.data;
  }

  @override
  Future<void> resetPasswordPhone(
      {required String idToken, required String newPassword}) async {
    Map<String, String> body = {};
    body['idToken'] = idToken;
    body['password'] = newPassword;
    await _apiHandler.post(
      UrlEndPoint.auth.resetPassword,
      body: body,
      parser: (json) => json,
    );
  }
}
