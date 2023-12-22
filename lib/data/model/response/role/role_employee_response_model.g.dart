// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_employee_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleEmployeeResponseModel _$RoleEmployeeResponseModelFromJson(
        Map<String, dynamic> json) =>
    RoleEmployeeResponseModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      rights: (json['rights'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$RoleEmployeeShopEnumMap, e))
          .toList(),
      type: json['type'] as String?,
      updatedAt: const TimeIso8601JsonConverter()
          .fromJson(json['updatedAt'] as String?),
      createdAt: const TimeIso8601JsonConverter()
          .fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$RoleEmployeeResponseModelToJson(
        RoleEmployeeResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rights':
          instance.rights?.map((e) => _$RoleEmployeeShopEnumMap[e]!).toList(),
      'type': instance.type,
      'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
      'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
    };

const _$RoleEmployeeShopEnumMap = {
  RoleEmployeeShop.EXCEL_MENU: 'EXCEL_MENU',
  RoleEmployeeShop.VIEW_HISTORY_ON_EXCEL_MENU: 'VIEW_HISTORY_ON_EXCEL_MENU',
  RoleEmployeeShop.EDIT_COD: 'EDIT_COD',
  RoleEmployeeShop.EDIT_ORDER_DOES_NOT_INCLUDE_COD:
      'EDIT_ORDER_DOES_NOT_INCLUDE_COD',
  RoleEmployeeShop.CANCEL_ORDER: 'CANCEL_ORDER',
  RoleEmployeeShop.PRINT_ORDER: 'PRINT_ORDER',
  RoleEmployeeShop.CREATE_ORDER: 'CREATE_ORDER',
  RoleEmployeeShop.VIEW_ORDER_DETAILS: 'VIEW_ORDER_DETAILS',
  RoleEmployeeShop.VIEW_FARES: 'VIEW_FARES',
  RoleEmployeeShop.VIEW_ORDER_LIST: 'VIEW_ORDER_LIST',
  RoleEmployeeShop.VIEW_ORDER_HISTORY: 'VIEW_ORDER_HISTORY',
  RoleEmployeeShop.EXPORT_EXCEL_FILE: 'EXPORT_EXCEL_FILE',
  RoleEmployeeShop.RETURN_ORDER_REQUEST: 'RETURN_ORDER_REQUEST',
  RoleEmployeeShop.RETURN_REQUEST: 'RETURN_REQUEST',
};
