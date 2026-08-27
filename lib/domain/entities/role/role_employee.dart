import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';

abstract class RoleEmployee {
  int? get id;

  String? get name;

  List<RoleEmployeeShop>? get rights;

  String? get type;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
