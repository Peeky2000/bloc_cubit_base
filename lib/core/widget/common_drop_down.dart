import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bloc_cubit_base/core/extension/string_extension.dart';

class CommonDropDown extends StatelessWidget {
  static CommonDropDownStyle commonDropDownStyle = const CommonDropDownStyle();

  final String? title;
  final String hint;
  final String? value;
  final TextStyle? titleStyle;
  final TextStyle? hintStyle;
  final TextStyle? valueStyle;
  final TextStyle? errorStyle;
  final Widget? valueWidget;
  final double? width;
  final double? radius;
  final Widget? trailingIcon;
  final BoxBorder? border;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool enable;
  final int? maxLine;
  final String? error;
  final Color? backgroundColor;

  const CommonDropDown({
    super.key,
    this.title,
    this.hint = '',
    this.value,
    this.titleStyle,
    this.hintStyle,
    this.valueStyle,
    this.errorStyle,
    this.valueWidget,
    this.width,
    this.radius,
    this.trailingIcon,
    this.border,
    this.padding,
    this.onTap,
    this.enable = true,
    this.maxLine,
    this.error,
    this.backgroundColor,
  });

  EdgeInsets get _padding => padding ?? commonDropDownStyle.padding!;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotNullOrEmpty)
          Padding(
            padding:
                commonDropDownStyle.titlePadding ??
                const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title!,
              style: titleStyle ?? commonDropDownStyle.titleStyle!,
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enable ? onTap : null,
            borderRadius: BorderRadius.circular(
              radius ?? commonDropDownStyle.radius,
            ),
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: backgroundColor ?? commonDropDownStyle.backgroundColor,
                borderRadius: BorderRadius.circular(
                  radius ?? commonDropDownStyle.radius,
                ),
                border:
                    border ??
                    Border.all(
                      color: enable && error.isNullOrEmpty
                          ? commonDropDownStyle.borderColor!
                          : enable && error.isNotNullOrEmpty
                          ? commonDropDownStyle.errorBorderColor!
                          : commonDropDownStyle.disableBorderColor!,
                      width: commonDropDownStyle.borderWidth ?? 1.0,
                    ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: _padding.top,
                        right: 0,
                        left: _padding.left,
                        bottom: _padding.bottom,
                      ),
                      child:
                          valueWidget ??
                          (value.isNullOrEmpty
                              ? Text(
                                  hint,
                                  style:
                                      hintStyle ??
                                      commonDropDownStyle.hintStyle!,
                                )
                              : Text(
                                  value!,
                                  style:
                                      valueStyle ??
                                      commonDropDownStyle.valueStyle!,
                                  maxLines: maxLine,
                                  overflow: TextOverflow.ellipsis,
                                )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  enable
                      ? Padding(
                          padding: EdgeInsets.only(right: _padding.right),
                          child:
                              trailingIcon ??
                              Transform.rotate(
                                angle: -pi / 2,
                                child: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 16,
                                  color: Color(0xFFA6A6A6),
                                ),
                              ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
        if (enable && error.isNotNullOrEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: _padding.left),
            child: Text(
              error ?? '',
              style: errorStyle ?? commonDropDownStyle.errorStyle,
            ),
          ),
      ],
    );
  }
}

class CommonDropDownStyle {
  final TextStyle? titleStyle;
  final TextStyle? hintStyle;
  final TextStyle? valueStyle;
  final TextStyle? errorStyle;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? disableBorderColor;
  final Color? errorBorderColor;
  final double radius;
  final EdgeInsetsGeometry? titlePadding;
  final double? borderWidth;

  const CommonDropDownStyle({
    this.titleStyle = const TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    this.valueStyle = const TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    this.hintStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    this.errorStyle = const TextStyle(
      color: Colors.redAccent,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor = Colors.transparent,
    this.borderColor = const Color(0xFFA6A6A6),
    this.disableBorderColor = const Color(0xFFA6A6A6),
    this.errorBorderColor = Colors.redAccent,
    this.radius = 8.0,
    this.titlePadding,
    this.borderWidth,
  });
}
