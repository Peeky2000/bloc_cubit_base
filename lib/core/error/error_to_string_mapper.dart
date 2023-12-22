import 'package:dio/dio.dart' as dio;
import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/error/exception.dart';
import 'package:delivery_go/data/model/response/base_response_model.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/l10n/l10n.dart';

part 'error_mapper_item.dart';

class ErrorMapper {
  ErrorMapper._(this._items);

  // Singleton
  static final ErrorMapper instance = ErrorMapper._([
    NoNetworkMapperItem(),
    HttpErrorResponseMapperItem(),
    GeneralErrorMapperItem(),
  ]);

  final List<ErrorToStringMapperItem> _items;

  String _map(dynamic error, [List<ErrorToStringMapperItem>? customItems]) {
    final item = _findItem(error, customItems);
    return item.getDisplay(error);
  }

  static String parse(dynamic error,
      [List<ErrorToStringMapperItem>? customItems]) {
    return instance._map(error, customItems);
  }

  ErrorToStringMapperItem _findItem(
      dynamic exception, List<ErrorToStringMapperItem>? customItems) {
    if (customItems != null && customItems.isNotEmpty) {
      final index =
          customItems.indexWhere((element) => element.isMatch(exception));
      if (index >= 0) {
        return customItems[index];
      }
    }
    return _items.firstWhere((element) => element.isMatch(exception));
  }
}
