import 'package:delivery_go/core/common/enum.dart';

abstract class RoleOwner {
  int? get id;

  String? get name;

  List<RoleOwnerShop>? get rights;

  String? get type;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
