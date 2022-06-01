import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';

class Decorations {

  static InputDecoration getInputDecoration({String hint = "", @required context}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color:Theme.of(context).hintColor),
      contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Theme.of(context).hintColor,
            width: 0.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Theme.of(context).hintColor,
            width: 0.1),
      ),
    );
  }

  static InputDecoration getInputDecorationLight({String hint = "", @required context}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color:Theme.of(context).hintColor),
      contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Palette.primaryColor,
            width: 0.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Palette.primaryColor,
            width: 0.1),
      ),
    );
  }
}