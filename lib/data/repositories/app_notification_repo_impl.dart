import 'package:bloc_cubit_base/data/datasource/remote/app_notification_remote_data_source.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/entities/response/base_list_response.dart';
import 'package:bloc_cubit_base/domain/repositories/app_notification_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppNotificationRepo)
class AppNotificationRepoImpl implements AppNotificationRepo {
  AppNotificationRepoImpl(this._remote);

  final AppNotificationRemoteDataSource _remote;

  @override
  Future<BaseListResponse<AppNotification>> getNotifications({
    required int page,
    required int pageSize,
  }) => _remote.getNotifications(page: page, pageSize: pageSize);
}
