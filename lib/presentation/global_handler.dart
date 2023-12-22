import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/error/error_to_string_mapper.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:sli_common/sli_common.dart';

void handleErrorResponse(dynamic error, {Function()? onRetry}) {
  if (!DialogUtil.isShowingDialog) {
    DialogUtil.error(Injector.getIt.get<AppController>().context!,
        title: Injector.getIt<AppController>().context?.l10n.error ?? '',
        content: ErrorMapper.parse(error),
        closeText: Injector.getIt<AppController>().context?.l10n.close ?? '',
        retryText: Injector.getIt<AppController>().context?.l10n.retry ?? '',
        isShowRetry: onRetry != null, onTapRetry: () async {
      if (onRetry != null) {
        await onRetry();
      }
    });
  }
}
