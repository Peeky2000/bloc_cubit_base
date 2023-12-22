import 'package:delivery_go/core/adapter/time_iso8601_converter.dart';
import 'package:delivery_go/domain/entities/auth/token_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_auth_response_model.g.dart';

@JsonSerializable()
class TokenAuthResponseModel implements TokenAuth {
  TokenAuthResponseModel({this.token, this.expires});

  @override
  @JsonKey(name: 'token')
  final String? token;

  @override
  @JsonKey(name: 'expires')
  @TimeIso8601JsonConverter()
  final DateTime? expires;

  factory TokenAuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TokenAuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenAuthResponseModelToJson(this);
}
