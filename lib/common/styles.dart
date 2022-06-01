import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';

class Constants {
  static TextStyle numberPickerHeading = TextStyle(
    fontSize: 30,
        color: Palette.primaryTextColorLight
  );

  static TextStyle questionLight = TextStyle(
      color: Palette.primaryTextColorLight,
      fontSize: 16);

  static TextStyle subHeadingLight = TextStyle(
      color: Palette.primaryTextColorLight,
      fontSize: 14);

  static TextStyle textLight = TextStyle(
    color: Palette.secondaryTextColorLight
  );

  static Color checkColorRole(roleId, isDark) {
    switch (roleId) {
      case 1:
        return Color(0xffFF7A45);
      case 2:
        return Color(0xff73D13D);
      case 3:
        return Color(0xff36CFC9);
      case 4:
        return isDark ? Color(0xffFFFFFF) : Color(0xff3D3D3D);
      default:
        return Color(0xffb7b4b4);
    }
  }
}
