import 'package:json_annotation/json_annotation.dart';

class StringToIntJsonConverter extends JsonConverter<int?, String?> {
  const StringToIntJsonConverter();

  @override
  int? fromJson(String? json) {
    return json == null ? null : int.tryParse(json);
  }

  @override
  String? toJson(int? object) {
    return object?.toString();
  }
}
