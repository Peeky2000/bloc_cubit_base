import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sli_common/sli_common.dart' show SliRadii;

/// Six-digit OTP input shared by the confirm-information and reset-password
/// screens.
class AppOtpField extends StatelessWidget {
  const AppOtpField({super.key, required this.onCompleted});

  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    return MaterialPinField(
      length: 6,
      keyboardType: TextInputType.number,
      theme: MaterialPinTheme(
        shape: MaterialPinShape.outlined,
        cellSize: Size(32.w, 32.w),
        borderRadius: BorderRadius.circular(SliRadii.sm),
        borderColor: App.appColor?.borderColor,
        focusedBorderColor: App.appColor?.primaryColor,
        filledBorderColor: App.appColor?.primaryColor,
        cursorColor: App.appColor?.primaryColor,
        textStyle: App.appStyle?.semiBold18,
        entryAnimation: MaterialPinAnimation.scale,
      ),
      onCompleted: onCompleted,
    );
  }
}
