import 'package:delivery_go/core/common/enum.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sign_up_request_model.g.dart';

@JsonSerializable()
class SignUpRequestModel {
  SignUpRequestModel({
    required this.email,
    required this.password,
    required this.phone,
    required this.industry,
    required this.shippingScale,
    required this.shopName,
  });

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'phone')
  final String phone;

  @JsonKey(name: 'industry')
  final String industry;

  @JsonKey(name: 'shippingScale')
  final ScaleLevel shippingScale;

  @JsonKey(name: 'shopName')
  final String shopName;

  factory SignUpRequestModel.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpRequestModelToJson(this);
}
