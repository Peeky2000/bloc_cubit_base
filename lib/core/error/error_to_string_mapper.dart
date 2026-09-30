import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:dio/dio.dart' as dio;

abstract final class ErrorMapper {
  static String parse(
    Object error, {
    required String fallbackMessage,
    required String noNetworkMessage,
  }) {
    if (error is NetworkIssueException) {
      return noNetworkMessage;
    }
    if (error is GeneralException) {
      final message = error.messages?.trim();
      return message == null || message.isEmpty ? fallbackMessage : message;
    }
    if (error is ServerException && error.hasError) {
      final response = (error.error as dio.DioException).response;
      final data = response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    return fallbackMessage;
  }
}
