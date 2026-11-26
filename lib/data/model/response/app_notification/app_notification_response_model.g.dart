// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotificationResponseModel _$AppNotificationResponseModelFromJson(
  Map<String, dynamic> json,
) => AppNotificationResponseModel(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String? ?? '',
  createdAt: const TimeIso8601JsonConverter().fromJson(
    json['createdAt'] as String?,
  ),
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$AppNotificationResponseModelToJson(
  AppNotificationResponseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'createdAt': const TimeIso8601JsonConverter().toJson(instance.createdAt),
  'isRead': instance.isRead,
};
