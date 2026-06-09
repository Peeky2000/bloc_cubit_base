import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Bottom2Button extends StatelessWidget {
  final String? title1;
  final String? title2;
  final VoidCallback? onTapButton1;
  final VoidCallback? onTapButton2;
  final double? height;
  final bool isDisableButton1;
  final bool isDisableButton2;
  final Color? textColorButton1;
  final Color? textColorButton2;
  final double radius;
  final double fontSize;
  final Color? button1Color;
  final Color? button2Color;
  final bool? isDivider;
  final double elevation;

  const Bottom2Button({
    Key? key,
    this.title1,
    this.title2,
    this.onTapButton1,
    this.onTapButton2,
    this.height = 48,
    this.isDisableButton1 = false,
    this.isDisableButton2 = false,
    this.textColorButton1,
    this.textColorButton2,
    this.radius = 8,
    this.fontSize = 16,
    this.button1Color,
    this.button2Color,
    this.isDivider,
    this.elevation = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: Offset(0, -elevation),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDivider == true) Divider(height: 1, thickness: 1),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: (height ?? 48).h,
                  child: ElevatedButton(
                    onPressed: isDisableButton1 ? null : onTapButton1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: button1Color,
                      foregroundColor: textColorButton1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(radius),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      title1 ?? '',
                      style: TextStyle(fontSize: fontSize.sp),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: (height ?? 48).h,
                color: Colors.grey[300],
              ),
              Expanded(
                child: SizedBox(
                  height: (height ?? 48).h,
                  child: ElevatedButton(
                    onPressed: isDisableButton2 ? null : onTapButton2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: button2Color,
                      foregroundColor: textColorButton2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(radius),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      title2 ?? '',
                      style: TextStyle(fontSize: fontSize.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
