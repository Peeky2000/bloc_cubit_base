import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/entities/common/page_result.dart';
import 'package:bloc_cubit_base/domain/repositories/app_notification_repo.dart';

/// Registered in lib/di/register_module.dart; no DI annotation here.
class AppNotificationUseCase {
  AppNotificationUseCase(this._repo);

  final AppNotificationRepo _repo;

  Future<PageResult<AppNotification>> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    final response = await _repo.getNotifications(
      page: page,
      pageSize: pageSize,
    );
    return PageResult<AppNotification>.fromResponse(
      response,
      page: page,
      pageSize: pageSize,
    );
  }
}
