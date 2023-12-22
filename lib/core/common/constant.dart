import 'package:flutter_screenutil/flutter_screenutil.dart';

final double kRadiusButton = 20.0.r;
final double kRadiusTextField = 20.0.r;

class Constant {
  static final RegExp passwordRegexp = RegExp(
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$%^&*()<>?~_+|=;:]).{8,}$');
  static final RegExp emailRegexp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  static final RegExp phoneRegexp = RegExp(r'(^(?:[+0]9)?[0-9]{10,12}$)');
  static const int timePeriodOTP = 60;
}

class Pagination {
  static const int firstPage = 1;
  static const int jiraListIssuePageSize = 20;
}
