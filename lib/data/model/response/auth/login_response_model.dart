import 'package:delivery_go/data/model/response/auth/token_wrapper_response_model.dart';
import 'package:delivery_go/data/model/response/profile/account_response_model.dart';
import 'package:delivery_go/domain/entities/auth/login.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_response_model.g.dart';

@JsonSerializable()
class LoginResponseModel implements Login {
  LoginResponseModel(this.account, this.token);

  @override
  @JsonKey(name: 'account')
  final AccountResponseModel? account;

  @override
  @JsonKey(name: 'tokens')
  final TokenWrapperResponseModel? token;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}
