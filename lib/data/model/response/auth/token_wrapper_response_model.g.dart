// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_wrapper_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenWrapperResponseModel _$TokenWrapperResponseModelFromJson(
        Map<String, dynamic> json) =>
    TokenWrapperResponseModel(
      access: json['access'] == null
          ? null
          : TokenAuthResponseModel.fromJson(
              json['access'] as Map<String, dynamic>),
      refresh: json['refresh'] == null
          ? null
          : TokenAuthResponseModel.fromJson(
              json['refresh'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TokenWrapperResponseModelToJson(
        TokenWrapperResponseModel instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
    };
