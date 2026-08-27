import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InkWellButton extends StatelessWidget {
  final String? title;
  final Widget? labelWidget;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Color? buttonColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double radius;
  final bool isDisable;
  final bool isWrapContentChild;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double elevation;

  const InkWellButton({
    super.key,
    this.title,
    this.labelWidget,
    this.onTap,
    this.width,
    this.height = 48,
    this.buttonColor,
    this.textColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.radius = 8,
    this.isDisable = false,
    this.isWrapContentChild = false,
    this.padding,
    this.borderColor,
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget child =
        labelWidget ??
        Text(
          title ?? '',
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: fontWeight,
            color: textColor,
          ),
        );

    Widget button = Container(
      width: isWrapContentChild ? null : (width ?? double.infinity),
      height: height.h,
      padding: padding,
      decoration: BoxDecoration(
        color: isDisable ? Colors.grey[300] : buttonColor,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisable ? null : onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: isWrapContentChild
                ? Padding(
                    padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );

    return button;
  }
}
