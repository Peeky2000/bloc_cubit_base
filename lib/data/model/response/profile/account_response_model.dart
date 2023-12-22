import 'package:delivery_go/core/adapter/time_iso8601_converter.dart';
import 'package:delivery_go/domain/entities/profile/account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_response_model.g.dart';

@JsonSerializable()
class AccountResponseModel implements Account {
  AccountResponseModel({
    this.id,
    this.role,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.isDeleted,
    this.email,
    this.phone,
    this.isActive,
    this.updatedAt,
    this.createdAt,
  });

  @override
  @JsonKey(name: 'id')
  final int? id;

  @override
  @JsonKey(name: 'role')
  final String? role;

  @override
  @JsonKey(name: 'isEmailVerified')
  final bool? isEmailVerified;

  @override
  @JsonKey(name: 'isPhoneVerified')
  final bool? isPhoneVerified;

  @override
  @JsonKey(name: 'isDeleted')
  final bool? isDeleted;

  @override
  @JsonKey(name: 'email')
  final String? email;

  @override
  @JsonKey(name: 'phone')
  final String? phone;

  @override
  @JsonKey(name: 'isActived')
  final bool? isActive;

  @override
  @JsonKey(name: 'updatedAt')
  @TimeIso8601JsonConverter()
  final DateTime? updatedAt;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  factory AccountResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AccountResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccountResponseModelToJson(this);
}
