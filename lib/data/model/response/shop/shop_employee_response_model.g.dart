// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_employee_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopEmployeeResponseModel _$ShopEmployeeResponseModelFromJson(
  Map<String, dynamic> json,
) => ShopEmployeeResponseModel(
  id: (json['id'] as num?)?.toInt(),
  accountId: (json['accountId'] as num?)?.toInt(),
  shopId: (json['shopId'] as num?)?.toInt(),
  shopRoleId: (json['shopRoleId'] as num?)?.toInt(),
  updatedAt: const TimeIso8601JsonConverter().fromJson(
    json['updatedAt'] as String?,
  ),
  createdAt: const TimeIso8601JsonConverter().fromJson(
    json['createdAt'] as String?,
  ),
);

Map<String, dynamic> _$ShopEmployeeResponseModelToJson(
  ShopEmployeeResponseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'accountId': instance.accountId,
  'shopId': instance.shopId,
  'shopRoleId': instance.shopRoleId,
  'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
  'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
};
