import 'package:delivery_go/data/model/response/auth/token_auth_response_model.dart';
import 'package:delivery_go/domain/entities/auth/token_wrapper.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_wrapper_response_model.g.dart';

@JsonSerializable()
class TokenWrapperResponseModel implements TokenWrapper {
  TokenWrapperResponseModel({this.access, this.refresh});

  @override
  @JsonKey(name: 'access')
  final TokenAuthResponseModel? access;

  @override
  @JsonKey(name: 'refresh')
  final TokenAuthResponseModel? refresh;

  factory TokenWrapperResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TokenWrapperResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenWrapperResponseModelToJson(this);
}
