// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workcake/common/palette.dart';

class Themes {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Roboto',
    backgroundColor: Palette.lightBG,
    primaryColor: Palette.lightPrimary,
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Palette.lightBG,
      labelType: NavigationRailLabelType.selected,
    ),
    scaffoldBackgroundColor: Palette.lightBG,
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(
        color: Palette.darkBG,
      ),
      color: Palette.lightBG,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Palette.darkBG
      ),
      toolbarTextStyle: TextStyle(
        color: Palette.darkBG
      ),
      titleTextStyle:TextStyle(
        color: Palette.darkBG,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    fontFamily: 'Roboto',
    brightness: Brightness.dark,
    backgroundColor: Colors.red,
    primaryColor: Palette.darkPrimary,
    scaffoldBackgroundColor: Color(0xff353a3e),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Palette.darkBG,
      labelType: NavigationRailLabelType.selected,
    ),
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(
        color: Palette.lightBG,
      ),
      color: Palette.darkPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Palette.lightAccent
      ),
      toolbarTextStyle: TextStyle(
        color: Palette.lightBG
      ),
      titleTextStyle:TextStyle(
        color: Palette.lightBG,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
      ),
    ),
  );


  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.light(),
    primaryColor: Colors.white,
    primarySwatch: Colors.blue,
    disabledColor: Colors.grey,
    cardColor: Colors.white,
    canvasColor: Colors.grey[50],
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    primaryColorBrightness: Brightness.light,
    backgroundColor:Colors.white,
    buttonTheme: ButtonThemeData(
      buttonColor: Palette.accentColor,     //  <-- light color
      textTheme: ButtonTextTheme.primary, //  <-- this auto selects the right color
    ),
    appBarTheme: AppBarTheme(elevation: 0.0),
    fontFamily: 'SF-Pro',
    bottomSheetTheme:  BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0))
  );
  
  static final dark = ThemeData(
    colorScheme: ColorScheme.dark(),
    primaryColor: Colors.black,
    primarySwatch: Colors.blue,
    disabledColor: Colors.grey,
    cardColor: Color(0xff191919),
    canvasColor: Colors.grey[50],
    backgroundColor:Color(0xff191919),
    scaffoldBackgroundColor: Colors.black,
    brightness: Brightness.dark,
    primaryColorBrightness: Brightness.dark,
    buttonTheme: ButtonThemeData(
      buttonColor: Palette.accentColor,     //  <-- dark color
      textTheme: ButtonTextTheme.primary, //  <-- this auto selects the right color
    ),
    appBarTheme: AppBarTheme(elevation: 0.0),
    fontFamily: 'SF-Pro',
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0))
  );
}