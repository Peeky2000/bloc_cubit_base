import 'package:delivery_go/core/common/enum.dart';

abstract class UserProfile {
  int? get id;

  int? get accountId;

  String? get industry;

  ScaleLevel? get shippingScale;

  DateTime? get updatedAt;

  DateTime? get createdAt;
}
