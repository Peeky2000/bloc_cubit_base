import 'package:mOrder/core/adapter/time_iso8601_converter.dart';
import 'package:mOrder/core/common/enum.dart';
import 'package:mOrder/domain/entities/role/role_owner.dart';
import 'package:json_annotation/json_annotation.dart';

part 'role_owner_response_model.g.dart';

@JsonSerializable()
class RoleOwnerResponseModel implements RoleOwner {
  RoleOwnerResponseModel({
    this.id,
    this.name,
    this.rights,
    this.type,
    this.updatedAt,
    this.createdAt,
  });

  @override
  @JsonKey(name: 'id')
  final int? id;

  @override
  @JsonKey(name: 'name')
  final String? name;

  @override
  @JsonKey(name: 'rights')
  final List<RoleOwnerShop>? rights;

  @override
  @JsonKey(name: 'type')
  final String? type;

  @override
  @JsonKey(name: 'updatedAt')
  @TimeIso8601JsonConverter()
  final DateTime? updatedAt;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  factory RoleOwnerResponseModel.fromJson(Map<String, dynamic> json) =>
      _$RoleOwnerResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoleOwnerResponseModelToJson(this);
}
