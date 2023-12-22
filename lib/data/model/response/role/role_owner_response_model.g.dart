// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_owner_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleOwnerResponseModel _$RoleOwnerResponseModelFromJson(
        Map<String, dynamic> json) =>
    RoleOwnerResponseModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      rights: (json['rights'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$RoleOwnerShopEnumMap, e))
          .toList(),
      type: json['type'] as String?,
      updatedAt: const TimeIso8601JsonConverter()
          .fromJson(json['updatedAt'] as String?),
      createdAt: const TimeIso8601JsonConverter()
          .fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$RoleOwnerResponseModelToJson(
        RoleOwnerResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rights':
          instance.rights?.map((e) => _$RoleOwnerShopEnumMap[e]!).toList(),
      'type': instance.type,
      'updatedAt': const TimeIso8601JsonConverter().toJson(instance.updatedAt),
      'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
    };

const _$RoleOwnerShopEnumMap = {
  RoleOwnerShop.COD_REPORT_COMING_SOON: 'COD_REPORT_COMING_SOON',
  RoleOwnerShop.REPORT_COD_IN_PROGRESS: 'REPORT_COD_IN_PROGRESS',
  RoleOwnerShop.CURRENT_DAY_OPERATING_ORDER_REPORT:
      'CURRENT_DAY_OPERATING_ORDER_REPORT',
  RoleOwnerShop.EXCEL_MENU: 'EXCEL_MENU',
  RoleOwnerShop.VIEW_HISTORY_ON_EXCEL_MENU: 'VIEW_HISTORY_ON_EXCEL_MENU',
  RoleOwnerShop.VIEW_REMITTANCE_VERSION_DETAILS:
      'VIEW_REMITTANCE_VERSION_DETAILS',
  RoleOwnerShop.VIEW_TRANSFER_VERSION_LIST: 'VIEW_TRANSFER_VERSION_LIST',
  RoleOwnerShop.UPDATE_STORE: 'UPDATE_STORE',
  RoleOwnerShop.ADD_STAFF_TO_THE_STORE: 'ADD_STAFF_TO_THE_STORE',
  RoleOwnerShop.ADD_USER_TO_GROUP_WITH_PERMISSIONS:
      'ADD_USER_TO_GROUP_WITH_PERMISSIONS',
  RoleOwnerShop.VIEW_STORE: 'VIEW_STORE',
  RoleOwnerShop.VIEW_A_LIST_OF_STORE_EMPLOYEES:
      'VIEW_A_LIST_OF_STORE_EMPLOYEES',
  RoleOwnerShop.DELETE_EMPLOYEE_FROM_STORE: 'DELETE_EMPLOYEE_FROM_STORE',
  RoleOwnerShop.COD_EDITING_ONLY: 'COD_EDITING_ONLY',
  RoleOwnerShop.NO_NEED_TO_ENTER_OTP: 'NO_NEED_TO_ENTER_OTP',
  RoleOwnerShop.EDIT_ORDER_ONLY_EXCLUDING_COD: 'EDIT_ORDER_ONLY_EXCLUDING_COD',
  RoleOwnerShop.CANCEL_ORDER: 'CANCEL_ORDER',
  RoleOwnerShop.IN_ORDER: 'IN_ORDER',
  RoleOwnerShop.CREATE_ORDER: 'CREATE_ORDER',
  RoleOwnerShop.VIEW_ORDER_DETAILS: 'VIEW_ORDER_DETAILS',
  RoleOwnerShop.VIEW_FEES: 'VIEW_FEES',
  RoleOwnerShop.VIEW_ORDER_LIST: 'VIEW_ORDER_LIST',
  RoleOwnerShop.VIEW_ORDER_HISTORY: 'VIEW_ORDER_HISTORY',
  RoleOwnerShop.EXPORT_EXCEL_FILE: 'EXPORT_EXCEL_FILE',
  RoleOwnerShop.REQUEST_FOR_MENU_REDELIVERY: 'REQUEST_FOR_MENU_REDELIVERY',
  RoleOwnerShop.RETURN_REQUEST: 'RETURN_REQUEST',
  RoleOwnerShop.UPDATE_REQUEST_TICKET: 'UPDATE_REQUEST_TICKET',
  RoleOwnerShop.CREATE_REQUEST_TICKET: 'CREATE_REQUEST_TICKET',
  RoleOwnerShop.VIEW_REQUEST_TICKET_DETAILS: 'VIEW_REQUEST_TICKET_DETAILS',
  RoleOwnerShop.VIEW_TICKET_REQUEST_LIST: 'VIEW_TICKET_REQUEST_LIST',
};
