// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_account_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAccountResponseModel _$UpdateAccountResponseModelFromJson(
        Map<String, dynamic> json) =>
    UpdateAccountResponseModel(
      account: json['account'] == null
          ? null
          : AccountResponseModel.fromJson(
              json['account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateAccountResponseModelToJson(
        UpdateAccountResponseModel instance) =>
    <String, dynamic>{
      'account': instance.account,
    };
