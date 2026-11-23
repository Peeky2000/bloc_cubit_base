import 'package:bloc_cubit_base/widget/app_otp_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// pin_code_fields 10 is built on material_ui, so AppOtpField renders inside
/// the same app shell as MainApp without a legacy Material ancestor.
void main() {
  testWidgets('OTP field renders and completes inside a material_ui app', (
    tester,
  ) async {
    String? completed;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) =>
              // ignore: deprecated_member_use
              MaterialUiCompatibilityBridge(child: child!),
          home: Scaffold(
            body: Center(
              child: AppOtpField(onCompleted: (value) => completed = value),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(EditableText), '123456');
    // The blinking cursor never settles; pump past the entry animation.
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(completed, '123456');
  });
}
