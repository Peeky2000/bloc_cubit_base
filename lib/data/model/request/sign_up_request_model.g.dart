// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpRequestModel _$SignUpRequestModelFromJson(Map<String, dynamic> json) =>
    SignUpRequestModel(
      email: json['email'] as String,
      password: json['password'] as String,
      phone: json['phone'] as String,
      industry: json['industry'] as String,
      shippingScale: $enumDecode(_$ScaleLevelEnumMap, json['shippingScale']),
      shopName: json['shopName'] as String,
    );

Map<String, dynamic> _$SignUpRequestModelToJson(SignUpRequestModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'industry': instance.industry,
      'shippingScale': _$ScaleLevelEnumMap[instance.shippingScale]!,
      'shopName': instance.shopName,
    };

const _$ScaleLevelEnumMap = {
  ScaleLevel.KHONG_THUONG_XUYEN: 'KHONG_THUONG_XUYEN',
  ScaleLevel.DUOI_150_THANG: 'DUOI_150_THANG',
  ScaleLevel.DUOI_900_THANG: 'DUOI_900_THANG',
  ScaleLevel.DUOI_3000_THANG: 'DUOI_3000_THANG',
  ScaleLevel.DUOI_6000_THANG: 'DUOI_6000_THANG',
  ScaleLevel.TREN_6000_THANG: 'TREN_6000_THANG',
};
