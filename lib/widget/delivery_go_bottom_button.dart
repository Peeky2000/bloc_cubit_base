import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/core/widget/bottom_button.dart';

class DeliveryGoBottomButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final bool isLightButton;
  final bool isDisable;
  final bool showDivider;

  const DeliveryGoBottomButton({
    super.key,
    required this.title,
    required this.onTap,
    this.width,
    this.height,
    this.isLightButton = false,
    this.isDisable = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return BottomButton(
      title: title,
      onTap: onTap,
      width: width,
      height: height ?? 48.h,
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      buttonColor: App.appColor?.primaryColor,
      textColor: App.appColor?.textColorButton,
      radius: kRadiusButton,
      isDisable: isDisable,
      isDivider: showDivider,
      elevation: 1.0,
    );
  }
}
