// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenAuthResponseModel _$TokenAuthResponseModelFromJson(
        Map<String, dynamic> json) =>
    TokenAuthResponseModel(
      token: json['token'] as String?,
      expires:
          const TimeIso8601JsonConverter().fromJson(json['expires'] as String?),
    );

Map<String, dynamic> _$TokenAuthResponseModelToJson(
        TokenAuthResponseModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expires': const TimeIso8601JsonConverter().toJson(instance.expires),
    };
