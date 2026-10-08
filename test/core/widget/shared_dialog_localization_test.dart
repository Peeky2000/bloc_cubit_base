import 'package:bloc_cubit_base/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sli_common/l10n/arb/app_localizations.dart' as sli_l10n;
import 'package:sli_common/sli_common.dart' show DialogUtil;

/// The app now uses DialogUtil from sli_common. Its default button labels come
/// from sli_common's own localizations, which MainApp registers next to the
/// app's. Without that delegate the dialog would throw on open.
void main() {
  Future<void> pumpApp(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          sli_l10n.AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  testWidgets('confirm dialog shows localized default buttons in Vietnamese', (
    tester,
  ) async {
    await pumpApp(tester, const Locale('vi'));
    final context = tester.element(find.byType(Scaffold));

    DialogUtil.confirm<void>(context, content: 'Xoá đơn?');
    await tester.pumpAndSettle();

    expect(find.text('Xoá đơn?'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
    expect(DialogUtil.isShowingDialog, isTrue);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(DialogUtil.isShowingDialog, isFalse);
  });
}
