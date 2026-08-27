import 'package:bloc_cubit_base/core/app/app_controller.dart';
import 'package:bloc_cubit_base/core/error/error_to_string_mapper.dart';
import 'package:bloc_cubit_base/core/widget/dialog_util.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';

void handleErrorResponse(dynamic error, {Function()? onRetry}) {
  if (!DialogUtil.isShowingDialog) {
    DialogUtil.error(
      Injector.getIt.get<AppController>().context!,
      title: Injector.getIt<AppController>().context?.l10n.error ?? '',
      content: ErrorMapper.parse(error),
      closeText: Injector.getIt<AppController>().context?.l10n.close ?? '',
      retryText: Injector.getIt<AppController>().context?.l10n.retry ?? '',
      isShowRetry: onRetry != null,
      onTapRetry: () async {
        if (onRetry != null) {
          await onRetry();
        }
      },
    );
  }
}
