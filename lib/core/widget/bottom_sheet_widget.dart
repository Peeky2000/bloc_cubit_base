import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sli_common/sli_common.dart' as sli;

@Deprecated(
  'Use SliBottomSheetFrame and showSliBottomSheet from '
  'package:sli_common/sli_common.dart.',
)
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
    final hasTitle = title != null && title!.isNotEmpty;
    return sli.SliBottomSheetFrame(
      title: hasTitle ? title : null,
      showCloseButton: false,
      showDivider: false,
      titleTextAlign: TextAlign.start,
      titleStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      headerPadding: EdgeInsets.all(16.w),
      height: isIntrinsicHeight ? null : (height ?? 400.h),
      maxHeight: isIntrinsicHeight ? (height ?? 400.h) : null,
      safeAreaBottom: false,
      backgroundColor: Colors.white,
      borderRadius: 16,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
