import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';

abstract class UserProfile {
  int? get id;

  int? get accountId;

  String? get industry;

  ScaleLevel? get shippingScale;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
