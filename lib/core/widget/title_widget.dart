import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  static TextStyle? defaultTitleStyle;
  static TextStyle? defaultValueStyle;

  final String? title;
  final TextStyle? titleStyle;
  final String? value;
  final TextStyle? valueStyle;
  final Widget? titleWidget;
  final Widget? valueWidget;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const TitleWidget({
    Key? key,
    required this.title,
    this.titleStyle,
    this.titleWidget,
    this.value,
    this.valueStyle,
    this.valueWidget,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        titleWidget ??
            Text(
              title ?? '',
              style: titleStyle ??
                  defaultTitleStyle ??
                  TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
            ),
        const SizedBox(width: 24),
        Expanded(
            child: valueWidget ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: valueStyle ??
                      defaultValueStyle ??
                      const TextStyle(fontSize: 14, color: Colors.grey),
                ))
      ],
    );
  }
}
