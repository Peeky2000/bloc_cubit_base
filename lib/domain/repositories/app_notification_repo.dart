import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/entities/response/base_list_response.dart';

abstract class AppNotificationRepo {
  /// Returns one page, newest first. [page] starts at `Pagination.firstPage`.
  /// Transport failures are thrown unchanged.
  Future<BaseListResponse<AppNotification>> getNotifications({
    required int page,
    required int pageSize,
  });
}
