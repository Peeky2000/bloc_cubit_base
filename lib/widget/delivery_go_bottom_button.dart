import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sli_common/sli_common.dart';
import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/common/constant.dart';

class DeliveryGoBottomButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final bool isLightButton;
  final bool isDisable;
  final bool showDivider;

  const DeliveryGoBottomButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.width,
    this.height,
    this.isLightButton = false,
    this.isDisable = false,
    this.showDivider = true,
  }) : super(key: key);

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
