// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileResponseModel _$UserProfileResponseModelFromJson(
        Map<String, dynamic> json) =>
    UserProfileResponseModel(
      id: json['id'] as int?,
      accountId: json['accountId'] as int?,
      industry: json['industry'] as String?,
      shippingScale:
          $enumDecodeNullable(_$ScaleLevelEnumMap, json['shippingScale']),
      updatedAt: const TimeIso8601JsonConverter()
          .fromJson(json['updatedAt'] as String?),
      createdAt: const TimeIso8601JsonConverter()
          .fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$UserProfileResponseModelToJson(
        UserProfileResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'industry': instance.industry,
      'shippingScale': _$ScaleLevelEnumMap[instance.shippingScale],
      'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
      'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
    };

const _$ScaleLevelEnumMap = {
  ScaleLevel.KHONG_THUONG_XUYEN: 'KHONG_THUONG_XUYEN',
  ScaleLevel.DUOI_150_THANG: 'DUOI_150_THANG',
  ScaleLevel.DUOI_900_THANG: 'DUOI_900_THANG',
  ScaleLevel.DUOI_3000_THANG: 'DUOI_3000_THANG',
  ScaleLevel.DUOI_6000_THANG: 'DUOI_6000_THANG',
  ScaleLevel.TREN_6000_THANG: 'TREN_6000_THANG',
};
