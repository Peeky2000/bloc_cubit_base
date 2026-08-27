import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/widget/bottom_2_button.dart';

class DeliveryGoBottom2Button extends StatelessWidget {
  final String? title1;
  final String? title2;
  final double? height;
  final VoidCallback? onTapButton1;
  final VoidCallback? onTapButton2;
  final bool isDisableButton1;
  final bool isDisableButton2;
  final bool? isDivider;

  const DeliveryGoBottom2Button({
    super.key,
    required this.title1,
    required this.title2,
    this.onTapButton1,
    this.onTapButton2,
    this.height,
    this.isDisableButton1 = false,
    this.isDisableButton2 = false,
    this.isDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Bottom2Button(
      title1: title1,
      title2: title2,
      onTapButton1: onTapButton1,
      onTapButton2: onTapButton2,
      height: (height ?? 48.h).toDouble(),
      isDisableButton1: isDisableButton1,
      isDisableButton2: isDisableButton2,
      textColorButton1: Colors.white,
      textColorButton2: App.appColor?.textColor,
      radius: kRadiusButton,
      fontSize: 16.sp,
      button1Color: App.appColor?.primaryColor,
      button2Color: Colors.white,
      isDivider: isDivider,
      elevation: 1.0,
    );
  }
}
