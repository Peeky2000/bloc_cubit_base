import 'package:bloc_cubit_base/core/adapter/time_iso8601_converter.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_notification_response_model.g.dart';

@JsonSerializable()
class AppNotificationResponseModel implements AppNotification {
  AppNotificationResponseModel({
    required this.id,
    required this.title,
    this.body = '',
    this.createdAt,
    this.isRead = false,
  });

  @override
  @JsonKey(name: 'id')
  final String id;

  @override
  @JsonKey(name: 'title')
  final String title;

  @override
  @JsonKey(name: 'body', defaultValue: '')
  final String body;

  @override
  @JsonKey(name: 'createdAt')
  @TimeIso8601JsonConverter()
  final DateTime? createdAt;

  @override
  @JsonKey(name: 'isRead', defaultValue: false)
  final bool isRead;

  factory AppNotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationResponseModelToJson(this);
}
