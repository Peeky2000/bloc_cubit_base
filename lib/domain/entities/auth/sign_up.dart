import 'package:mOrder/domain/entities/profile/account.dart';
import 'package:mOrder/domain/entities/profile/user_profile.dart';
import 'package:mOrder/domain/entities/role/role_employee.dart';
import 'package:mOrder/domain/entities/role/role_owner.dart';
import 'package:mOrder/domain/entities/shop/shop.dart';
import 'package:mOrder/domain/entities/shop/shop_employee.dart';

abstract class SignUp {
  Account? get account;
  UserProfile? get userProfile;
  Shop? get shop;
  RoleOwner? get defaultShopOwnerRole;
  RoleEmployee? get defaultShopEmployeeRole;
  ShopEmployee? get shopEmployee;
}
