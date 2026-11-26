import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/datasource/remote/url_end_point.dart';
import 'package:bloc_cubit_base/data/model/response/app_notification/app_notification_response_model.dart';
import 'package:bloc_cubit_base/data/model/response/base_list_response_model.dart';
import 'package:injectable/injectable.dart';

abstract class AppNotificationRemoteDataSource {
  Future<BaseListResponseModel<AppNotificationResponseModel>> getNotifications({
    required int page,
    required int pageSize,
  });
}

@LazySingleton(as: AppNotificationRemoteDataSource)
class AppNotificationRemoteDataSourceImpl
    implements AppNotificationRemoteDataSource {
  AppNotificationRemoteDataSourceImpl(this._apiHandler);

  final ApiHandler _apiHandler;

  @override
  Future<BaseListResponseModel<AppNotificationResponseModel>> getNotifications({
    required int page,
    required int pageSize,
  }) {
    return _apiHandler.getList<AppNotificationResponseModel>(
      UrlEndPoint.notification.list,
      queryParameters: {'page': page, 'perPage': pageSize},
      parser: AppNotificationResponseModel.fromJson,
    );
  }
}
