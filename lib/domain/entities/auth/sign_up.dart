import 'package:delivery_go/domain/entities/profile/account.dart';
import 'package:delivery_go/domain/entities/profile/user_profile.dart';
import 'package:delivery_go/domain/entities/role/role_employee.dart';
import 'package:delivery_go/domain/entities/role/role_owner.dart';
import 'package:delivery_go/domain/entities/shop/shop.dart';
import 'package:delivery_go/domain/entities/shop/shop_employee.dart';

abstract class SignUp {
  Account? get account;
  UserProfile? get userProfile;
  Shop? get shop;
  RoleOwner? get defaultShopOwnerRole;
  RoleEmployee? get defaultShopEmployeeRole;
  ShopEmployee? get shopEmployee;
}
