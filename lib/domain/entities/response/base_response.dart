abstract class BaseResponse<T> {
  T? get data;

  String get message;

  int? get code;
}
