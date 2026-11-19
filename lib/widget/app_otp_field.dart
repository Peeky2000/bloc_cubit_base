// pin_code_fields 8 builds on package:flutter/material.dart; its TextFormField
// needs a legacy Material ancestor, which a material_ui Scaffold does not
// provide. Replace with pin_code_fields 10 (MaterialPinField) and drop the
// legacy import when the OTP screens are reworked.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy show Material, MaterialType;
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
    return legacy.Material(
      type: legacy.MaterialType.transparency,
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          selectedColor: App.appColor?.primaryColor,
          inactiveColor: App.appColor?.borderColor,
          activeFillColor: App.appColor?.primaryColor,
          activeColor: App.appColor?.primaryColor,
          borderRadius: BorderRadius.circular(SliRadii.sm),
          fieldHeight: 32.w,
          fieldWidth: 32.w,
        ),
        textStyle: App.appStyle?.semiBold18,
        cursorHeight: 16.w,
        animationType: AnimationType.scale,
        keyboardType: TextInputType.number,
        autoDisposeControllers: false,
        onChanged: (String value) {},
        onCompleted: onCompleted,
      ),
    );
  }
}
