import 'package:flutter/material.dart';
import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/di/injection.dart';

class AppColor {
  Color? primaryColor;
  Color? secondary1;
  Color? secondary2;
  Color? backgroundColor;
  Color? textColor;
  Color? textColorButton;
  Color? textColorLight;
  Color? textColorPrimary;
  Color? borderColor;
  Color? redBase;
  Color? iconColor;

  AppColor() {
    if (Injector.getIt.get<AppController>().isDarkMode) {
      setupDarkMode();
    } else {
      setupLightMode();
    }
  }

  void setupLightMode() {
    primaryColor = const Color(0xFF2BCB57);
    secondary1 = const Color(0xFF379237);
    secondary2 = const Color(0xFF82CD47);
    backgroundColor = const Color(0xFFFFFFFF);
    textColor = const Color(0xFF505050);
    textColorButton = const Color(0xFFFFFFFF);
    textColorLight = const Color(0xFFCECECE);
    textColorPrimary = const Color(0xFF2BCB57);
    borderColor = const Color(0xFFCECECE);
    redBase = const Color(0xFFF84F31);
    iconColor = const Color(0xFF5C5C5C);
  }

  void setupDarkMode() {
    primaryColor = const Color(0xFF2BCB57);
    secondary1 = const Color(0xFF379237);
    secondary2 = const Color(0xFF82CD47);
    backgroundColor = const Color(0xFFFFFFFF);
    textColor = const Color(0xFF505050);
    textColorButton = const Color(0xFFFFFFFF);
    textColorLight = const Color(0xFFCECECE);
    textColorPrimary = const Color(0xFF2BCB57);
    borderColor = const Color(0xFFCECECE);
    redBase = const Color(0xFFF84F31);
    iconColor = const Color(0xFF5C5C5C);
  }
}
