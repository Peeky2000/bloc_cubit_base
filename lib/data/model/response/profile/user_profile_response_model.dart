import 'package:delivery_go/core/adapter/time_iso8601_converter.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/domain/entities/profile/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_response_model.g.dart';

@JsonSerializable()
class UserProfileResponseModel implements UserProfile {
  UserProfileResponseModel({
    this.id,
    this.accountId,
    this.industry,
    this.shippingScale,
    this.updatedAt,
    this.createdAt,
  });

  @override
  @JsonKey(name: 'id')
  final int? id;

  @override
  @JsonKey(name: 'accountId')
  final int? accountId;

  @override
  @JsonKey(name: 'industry')
  final String? industry;

  @override
  @JsonKey(name: 'shippingScale')
  final ScaleLevel? shippingScale;

  @override
  @JsonKey(name: 'updatedAt')
  @TimeIso8601JsonConverter()
  final DateTime? updatedAt;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  factory UserProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileResponseModelToJson(this);
}
