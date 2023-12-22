// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseModel _$LoginResponseModelFromJson(Map<String, dynamic> json) =>
    LoginResponseModel(
      json['account'] == null
          ? null
          : AccountResponseModel.fromJson(
              json['account'] as Map<String, dynamic>),
      json['tokens'] == null
          ? null
          : TokenWrapperResponseModel.fromJson(
              json['tokens'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseModelToJson(LoginResponseModel instance) =>
    <String, dynamic>{
      'account': instance.account,
      'tokens': instance.token,
    };
