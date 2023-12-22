import 'package:delivery_go/data/model/response/profile/account_response_model.dart';
import 'package:delivery_go/data/model/response/profile/user_profile_response_model.dart';
import 'package:delivery_go/data/model/response/role/role_employee_response_model.dart';
import 'package:delivery_go/data/model/response/role/role_owner_response_model.dart';
import 'package:delivery_go/data/model/response/shop/shop_employee_response_model.dart';
import 'package:delivery_go/data/model/response/shop/shop_response_model.dart';
import 'package:delivery_go/domain/entities/auth/sign_up.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sign_up_response_model.g.dart';

@JsonSerializable()
class SignUpResponseModel implements SignUp {
  SignUpResponseModel({
    this.account,
    this.userProfile,
    this.shop,
    this.defaultShopOwnerRole,
    this.defaultShopEmployeeRole,
    this.shopEmployee,
  });

  @override
  @JsonKey(name: 'account')
  final AccountResponseModel? account;

  @override
  @JsonKey(name: 'userProfile')
  final UserProfileResponseModel? userProfile;

  @override
  @JsonKey(name: 'shop')
  final ShopResponseModel? shop;

  @override
  @JsonKey(name: 'defaultShopOwnerRole')
  final RoleOwnerResponseModel? defaultShopOwnerRole;

  @override
  @JsonKey(name: 'defaultShopEmployeeRole')
  final RoleEmployeeResponseModel? defaultShopEmployeeRole;

  @override
  @JsonKey(name: 'shopEmployee')
  final ShopEmployeeResponseModel? shopEmployee;

  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SignUpResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpResponseModelToJson(this);
}
