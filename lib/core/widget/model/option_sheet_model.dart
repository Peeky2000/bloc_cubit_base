import 'package:flutter/cupertino.dart';

class OptionSheetModel {
  String title;
  TextStyle? style;
  Function()? onTap;

  OptionSheetModel({required this.title, this.style, this.onTap});
}
