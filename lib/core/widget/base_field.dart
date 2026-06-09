import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BaseField extends StatelessWidget {
  static BaseFieldStyle baseFieldStyle = const BaseFieldStyle();

  final String? title;
  final String? value;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final Widget? titleWidget;
  final Widget? valueWidget;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;
  final BaseFieldType type;

  const BaseField({
    Key? key,
    this.title,
    this.value,
    this.titleWidget,
    this.valueWidget,
    this.titleStyle,
    this.valueStyle,
    this.padding,
    this.showDivider = true,
    this.crossAxisAlignment,
    this.mainAxisAlignment,
    this.type = BaseFieldType.horizontal,
  }) : super(key: key);

  Widget _buildBaseHorizontal() {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.spaceBetween,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: [
        titleWidget ??
            Text(
              title ?? '',
              style: titleStyle ?? baseFieldStyle.titleDefaultStyle,
            ),
        valueWidget ??
            Text(
              value ?? '',
              style: valueStyle ?? baseFieldStyle.valueDefaultStyle,
            )
      ],
    );
  }

  Widget _buildBaseVertical() {
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      children: [
        titleWidget ??
            Text(
              title ?? '',
              style: titleStyle ?? baseFieldStyle.titleDefaultStyle,
            ),
        SizedBox(
          height: 8.0.h,
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: valueStyle ?? baseFieldStyle.valueDefaultStyle,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.symmetric(vertical: 16.w),
          child: type == BaseFieldType.horizontal ? _buildBaseHorizontal() : _buildBaseVertical(),
        ),
        if (showDivider)
          const Divider(
            thickness: 1.0,
            height: 0.0,
          )
      ],
    );
  }
}

enum BaseFieldType { vertical, horizontal }

class BaseFieldStyle {
  final TextStyle? titleDefaultStyle;
  final TextStyle? valueDefaultStyle;

  const BaseFieldStyle(
      {this.titleDefaultStyle =
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
      this.valueDefaultStyle =
          const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.grey)});
}
