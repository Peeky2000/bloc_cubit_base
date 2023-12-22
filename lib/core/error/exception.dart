import 'package:dio/dio.dart';

class ServerException implements Exception {
  ServerException(this.error);

  final dynamic error;

  @override
  String toString() {
    return 'Server exception';
  }

  bool get hasError => error != null && error is DioException;
}

class CacheException implements Exception {}

class NetworkIssueException implements Exception {
  NetworkIssueException();

  @override
  String toString() {
    return 'Timeout Exception';
  }
}

class GeneralException implements Exception {
  String? messages;

  GeneralException({this.messages});

  @override
  String toString() {
    return messages ?? '';
  }
}
