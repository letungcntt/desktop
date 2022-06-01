import 'package:flutter/material.dart';
// import 'package:bitsdojo_window/bitsdojo_window.dart';

// final buttonColors = WindowButtonColors(
//     iconNormal: Color(0xFFDEE1E6),
//     mouseOver: Color(0xFF434D57),
//     mouseDown: Color(0xFF434D57),
//     iconMouseOver: Colors.white,
//     iconMouseDown: Colors.white);

// final closeButtonColors = WindowButtonColors(
//     mouseOver: Color(0xFFfc4c4c),
//     mouseDown: Color(0xFFfc4c4c),
//     iconNormal: Color(0xFFDEE1E6),
//     iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // MinimizeWindowButton(colors: buttonColors),
        // MaximizeWindowButton(colors: buttonColors),
        // CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}