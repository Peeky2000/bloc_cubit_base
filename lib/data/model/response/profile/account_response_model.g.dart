// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountResponseModel _$AccountResponseModelFromJson(
        Map<String, dynamic> json) =>
    AccountResponseModel(
      id: json['id'] as int?,
      role: json['role'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      isPhoneVerified: json['isPhoneVerified'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActived'] as bool?,
      updatedAt: const TimeIso8601JsonConverter()
          .fromJson(json['updatedAt'] as String?),
      createdAt: const TimeIso8601JsonConverter()
          .fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$AccountResponseModelToJson(
        AccountResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'isEmailVerified': instance.isEmailVerified,
      'isPhoneVerified': instance.isPhoneVerified,
      'isDeleted': instance.isDeleted,
      'email': instance.email,
      'phone': instance.phone,
      'isActived': instance.isActive,
      'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
      'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
    };
