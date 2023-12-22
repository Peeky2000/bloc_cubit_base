abstract class BaseListResponse<T> {
  String? get message;

  int? get page;

  int? get perPage;

  int? get totalResults;

  List<T>? get data;
}
