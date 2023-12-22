import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyle {
  TextStyle? regular10;
  TextStyle? medium10;
  TextStyle? semiBold10;
  TextStyle? bold10;

  TextStyle? regular12;
  TextStyle? medium12;
  TextStyle? semiBold12;
  TextStyle? bold12;

  TextStyle? regular14;
  TextStyle? medium14;
  TextStyle? semiBold14;
  TextStyle? bold14;

  TextStyle? regular16;
  TextStyle? medium16;
  TextStyle? semiBold16;
  TextStyle? bold16;

  TextStyle? regular18;
  TextStyle? medium18;
  TextStyle? semiBold18;
  TextStyle? bold18;

  TextStyle? regular20;
  TextStyle? medium20;
  TextStyle? semiBold20;
  TextStyle? bold20;

  TextStyle? regular24;
  TextStyle? medium24;
  TextStyle? semiBold24;
  TextStyle? bold24;

  AppStyle() {
    regular10 = TextStyle(fontSize: 10.sp, fontWeight: FontWeight.normal);
    medium10 = TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500);
    semiBold10 = TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600);
    bold10 = TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold);

    regular12 = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal);
    medium12 = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500);
    semiBold12 = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600);
    bold12 = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold);

    regular14 = TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal);
    medium14 = TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500);
    semiBold14 = TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600);
    bold14 = TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold);

    regular16 = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal);
    medium16 = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500);
    semiBold16 = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600);
    bold16 = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold);

    regular18 = TextStyle(fontSize: 18.sp, fontWeight: FontWeight.normal);
    medium18 = TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500);
    semiBold18 = TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600);
    bold18 = TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold);

    regular20 = TextStyle(fontSize: 20.sp, fontWeight: FontWeight.normal);
    medium20 = TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500);
    semiBold20 = TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600);
    bold20 = TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold);

    regular24 = TextStyle(fontSize: 24.sp, fontWeight: FontWeight.normal);
    medium24 = TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500);
    semiBold24 = TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600);
    bold24 = TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold);
  }
}
