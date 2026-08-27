import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/entities/profile/user_profile.dart';
import 'package:bloc_cubit_base/domain/entities/role/role_employee.dart';
import 'package:bloc_cubit_base/domain/entities/role/role_owner.dart';
import 'package:bloc_cubit_base/domain/entities/shop/shop.dart';
import 'package:bloc_cubit_base/domain/entities/shop/shop_employee.dart';

abstract class SignUp {
  Account? get account;
  UserProfile? get userProfile;
  Shop? get shop;
  RoleOwner? get defaultShopOwnerRole;
  RoleEmployee? get defaultShopEmployeeRole;
  ShopEmployee? get shopEmployee;
}
