// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseListResponseModel<T> _$BaseListResponseModelFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    BaseListResponseModel<T>(
      message: json['message'] as String?,
      page: json['page'] as int?,
      perPage: json['perPage'] as int?,
      totalResults: json['totalResults'] as int?,
      data: (json['data'] as List<dynamic>?)?.map(fromJsonT).toList(),
    );

Map<String, dynamic> _$BaseListResponseModelToJson<T>(
  BaseListResponseModel<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'message': instance.message,
      'page': instance.page,
      'perPage': instance.perPage,
      'totalResults': instance.totalResults,
      'data': instance.data?.map(toJsonT).toList(),
    };
