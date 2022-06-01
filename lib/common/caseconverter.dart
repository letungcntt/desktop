import 'package:flutter/material.dart';

class CaseChange {
  static String toUpperCase(String input, BuildContext context) {
    Locale locale = const Locale('en');
    if (locale.languageCode == 'tr') {
      input = input.replaceAll("i", "İ");
    } else if (locale.languageCode == 'de') {
      input = input.replaceAll("ß", "SS");
    }
    return input.toUpperCase();
  }
}