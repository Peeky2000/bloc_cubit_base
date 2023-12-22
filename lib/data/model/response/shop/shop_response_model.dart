import 'package:delivery_go/core/adapter/time_iso8601_converter.dart';
import 'package:delivery_go/domain/entities/shop/shop.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop_response_model.g.dart';

@JsonSerializable()
class ShopResponseModel implements Shop {
  ShopResponseModel({
    this.id,
    this.ownerId,
    this.name,
    this.phone,
    this.isDefault,
    this.updatedAt,
    this.createdAt,
  });

  @override
  @JsonKey(name: 'id')
  final int? id;

  @override
  @JsonKey(name: 'ownerId')
  final int? ownerId;

  @override
  @JsonKey(name: 'name')
  final String? name;

  @override
  @JsonKey(name: 'phone')
  final String? phone;

  @override
  @JsonKey(name: 'isDefault')
  final bool? isDefault;

  @override
  @JsonKey(name: 'updatedAt')
  @TimeIso8601JsonConverter()
  final DateTime? updatedAt;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  factory ShopResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ShopResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopResponseModelToJson(this);
}
