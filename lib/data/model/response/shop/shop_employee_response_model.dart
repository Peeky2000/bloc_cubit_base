import 'package:delivery_go/core/adapter/time_iso8601_converter.dart';
import 'package:delivery_go/domain/entities/shop/shop_employee.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop_employee_response_model.g.dart';

@JsonSerializable()
class ShopEmployeeResponseModel implements ShopEmployee {
  ShopEmployeeResponseModel({
    this.id,
    this.accountId,
    this.shopId,
    this.shopRoleId,
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
  @JsonKey(name: 'shopId')
  final int? shopId;

  @override
  @JsonKey(name: 'shopRoleId')
  final int? shopRoleId;

  @override
  @JsonKey(name: 'updatedAt')
  @TimeIso8601JsonConverter()
  final DateTime? updatedAt;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  factory ShopEmployeeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ShopEmployeeResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopEmployeeResponseModelToJson(this);
}
