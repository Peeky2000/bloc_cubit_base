import 'package:sli_common/sli_common.dart' show SliSpacing;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/constant.dart';
import 'package:bloc_cubit_base/widget/app_ink_well_button.dart';

class AppPrimaryButton extends StatelessWidget {
  final String? title;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool isDisable;
  final Color? colorButton;
  final Color? titleColor;
  final Color? borderColor;
  final Widget? icon;
  final bool isWrapContentChild;
  final EdgeInsetsGeometry? padding;

  const AppPrimaryButton({
    super.key,
    required this.title,
    this.width,
    this.onTap,
    this.height,
    this.isDisable = false,
    this.colorButton,
    this.titleColor,
    this.borderColor,
    this.icon,
    this.isWrapContentChild = false,
    this.padding,
  });

  Widget _buildLabel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SliSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: SliSpacing.xl),
          SizedBox(width: SliSpacing.sm),
          Expanded(
            child: Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: titleColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: SliSpacing.sm),
          icon!,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppInkWellButton(
      title: icon == null ? title : null,
      labelWidget: icon == null ? null : _buildLabel(),
      buttonColor: colorButton ?? App.appColor?.primaryColor,
      isWrapContentChild: isWrapContentChild,
      height: height ?? 48.h,
      width: width,
      elevation: 1.0,
      textColor: titleColor ?? Colors.white,
      fontSize: 16.sp,
      radius: kRadiusButton,
      fontWeight: FontWeight.w500,
      padding: padding ?? EdgeInsets.zero,
      onTap: onTap,
      isDisable: isDisable,
      borderColor: borderColor,
    );
  }
}
