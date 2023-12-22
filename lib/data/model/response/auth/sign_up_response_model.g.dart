// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpResponseModel _$SignUpResponseModelFromJson(Map<String, dynamic> json) =>
    SignUpResponseModel(
      account: json['account'] == null
          ? null
          : AccountResponseModel.fromJson(
              json['account'] as Map<String, dynamic>),
      userProfile: json['userProfile'] == null
          ? null
          : UserProfileResponseModel.fromJson(
              json['userProfile'] as Map<String, dynamic>),
      shop: json['shop'] == null
          ? null
          : ShopResponseModel.fromJson(json['shop'] as Map<String, dynamic>),
      defaultShopOwnerRole: json['defaultShopOwnerRole'] == null
          ? null
          : RoleOwnerResponseModel.fromJson(
              json['defaultShopOwnerRole'] as Map<String, dynamic>),
      defaultShopEmployeeRole: json['defaultShopEmployeeRole'] == null
          ? null
          : RoleEmployeeResponseModel.fromJson(
              json['defaultShopEmployeeRole'] as Map<String, dynamic>),
      shopEmployee: json['shopEmployee'] == null
          ? null
          : ShopEmployeeResponseModel.fromJson(
              json['shopEmployee'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SignUpResponseModelToJson(
        SignUpResponseModel instance) =>
    <String, dynamic>{
      'account': instance.account,
      'userProfile': instance.userProfile,
      'shop': instance.shop,
      'defaultShopOwnerRole': instance.defaultShopOwnerRole,
      'defaultShopEmployeeRole': instance.defaultShopEmployeeRole,
      'shopEmployee': instance.shopEmployee,
    };
