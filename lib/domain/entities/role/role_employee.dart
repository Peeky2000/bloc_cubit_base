import 'package:delivery_go/core/common/enum.dart';

abstract class RoleEmployee {
  int? get id;

  String? get name;

  List<RoleEmployeeShop>? get rights;

  String? get type;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
