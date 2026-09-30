import 'package:bloc_cubit_base/core/error/error_to_string_mapper.dart';
import 'package:bloc_cubit_base/core/widget/dialog_util.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

void handleErrorResponse(
  BuildContext context,
  Object error, {
  Future<void> Function()? onRetry,
}) {
  if (!DialogUtil.isShowingDialog) {
    DialogUtil.error(
      context,
      title: context.l10n.error,
      content: ErrorMapper.parse(
        error,
        fallbackMessage: context.l10n.errGeneral,
        noNetworkMessage: context.l10n.noInternet,
      ),
      closeText: context.l10n.close,
      retryText: context.l10n.retry,
      isShowRetry: onRetry != null,
      onTapRetry: () async {
        await onRetry?.call();
      },
    );
  }
}
