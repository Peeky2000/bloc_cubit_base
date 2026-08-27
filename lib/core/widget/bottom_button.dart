import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomButton extends StatelessWidget {
  final String? title;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? buttonColor;
  final Color? textColor;
  final double radius;
  final bool isDisable;
  final bool? isDivider;
  final double elevation;

  const BottomButton({
    super.key,
    this.title,
    this.onTap,
    this.width,
    this.height = 48,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.buttonColor,
    this.textColor,
    this.radius = 8,
    this.isDisable = false,
    this.isDivider,
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: Offset(0, -elevation),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDivider == true) Divider(height: 1, thickness: 1),
          SizedBox(
            width: width,
            height: height.h,
            child: ElevatedButton(
              onPressed: isDisable ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                elevation: 0,
              ),
              child: Text(
                title ?? '',
                style: TextStyle(fontSize: fontSize.sp, fontWeight: fontWeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
