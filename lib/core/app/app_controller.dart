import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/domain/use_case/auth_use_case.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:sli_common/sli_common.dart';

class AppController {
  BuildContext? get context => SLIRouting.key.currentContext;

  bool get isDarkMode => (theme.brightness == Brightness.dark);

  ThemeData get theme {
    var theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }

  Future<void> showSessionEnd() async {
    if (!DialogUtil.isShowingDialog &&
        Injector.getIt.get<AuthUseCase>().isAppLogin()) {
      BuildContext? context = Injector.getIt.get<AppController>().context;
      DialogUtil.alert(
        context!,
        content: context.l10n.sessionExpired,
        submit: context.l10n.logout,
        onSubmit: () async {
          await Injector.getIt.get<AuthUseCase>().logout();
        },
      );
    }
  }
}
