import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';

abstract class RoleOwner {
  int? get id;

  String? get name;

  List<RoleOwnerShop>? get rights;

  String? get type;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
