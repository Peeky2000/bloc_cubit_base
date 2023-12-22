import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SuccessScreen extends StatelessWidget {
  final Widget? icon;
  final String? title;
  final String? subtitle;

  const SuccessScreen({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.appColor?.primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: double.infinity,
          ),
          icon ?? Assets.images.imgLogoSmall.image(width: 196.w),
          SizedBox(
            height: 32.h,
          ),
          Text(
            title ?? '',
            style: App.appStyle?.bold20?.copyWith(
              color: App.appColor?.textColorButton,
            ),
          ),
          SizedBox(
            height: 16.h,
          ),
          Text(
            subtitle ?? '',
            style: App.appStyle?.medium14?.copyWith(
              color: App.appColor?.textColorButton,
            ),
          ),
        ],
      ),
    );
  }
}
