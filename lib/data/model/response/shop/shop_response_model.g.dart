// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopResponseModel _$ShopResponseModelFromJson(Map<String, dynamic> json) =>
    ShopResponseModel(
      id: json['id'] as int?,
      ownerId: json['ownerId'] as int?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      isDefault: json['isDefault'] as bool?,
      updatedAt: const TimeIso8601JsonConverter()
          .fromJson(json['updatedAt'] as String?),
      createdAt: const TimeIso8601JsonConverter()
          .fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$ShopResponseModelToJson(ShopResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'phone': instance.phone,
      'isDefault': instance.isDefault,
      'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
      'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
    };
