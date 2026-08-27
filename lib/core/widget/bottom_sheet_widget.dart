import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomSheetWidget extends StatelessWidget {
  final String? title;
  final Widget? child;
  final bool isIntrinsicHeight;
  final double? height;

  const BottomSheetWidget({
    super.key,
    this.title,
    this.child,
    this.isIntrinsicHeight = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child ?? SizedBox.shrink();

    if (title != null && title!.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              title!,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          content,
        ],
      );
    }

    return Container(
      height: isIntrinsicHeight ? null : (height ?? 400.h),
      constraints: isIntrinsicHeight
          ? BoxConstraints(maxHeight: height ?? 400.h)
          : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: content,
    );
  }
}
