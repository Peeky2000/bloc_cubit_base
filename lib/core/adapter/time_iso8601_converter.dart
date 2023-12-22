import 'package:json_annotation/json_annotation.dart';

class TimeIso8601JsonConverter extends JsonConverter<DateTime?, String?> {
  const TimeIso8601JsonConverter();

  @override
  DateTime? fromJson(String? json) {
    return json == null ? null : DateTime.tryParse(json);
  }

  @override
  String? toJson(DateTime? object) {
    return object?.toIso8601String();
  }
}
