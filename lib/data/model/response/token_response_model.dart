import 'package:delivery_go/data/model/response/auth/token_wrapper_response_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:delivery_go/domain/entities/response/token_response.dart';

part 'token_response_model.g.dart';

@JsonSerializable()
class TokenResponseModel implements TokenResponse {
  @override
  @JsonKey(name: 'accessToken')
  final String? accessToken;

  @override
  @JsonKey(name: 'refreshToken')
  final String? refreshToken;

  TokenResponseModel({this.accessToken, this.refreshToken});

  factory TokenResponseModel.fromTokenWrapperResponse(
      TokenWrapperResponseModel? tokenWrapper) {
    return TokenResponseModel(
      accessToken: tokenWrapper?.access?.token,
      refreshToken: tokenWrapper?.refresh?.token,
    );
  }

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseModelToJson(this);
}
