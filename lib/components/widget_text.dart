// ignore_for_file: override_on_non_overriding_member

import 'package:flutter/material.dart';
// import "package:collection/collection.dart";
import 'package:better_selection/better_selection.dart';

class TextWidget extends StatelessWidget {
  const TextWidget(
    this.text, {
    Key? key,
    this.style,
  }) : super(key: key);

  final String text;
  final TextStyle? style;

  @override
  bool shouldRebuild(covariant TextWidget oldWidget) {
    return oldWidget.text != text || oldWidget.style != style;
  }

  @override
  Widget build(BuildContext context) {
    return TextSelectable(
      textSpan: TextSpan(
        text: text,
        style: style ?? const TextStyle(
          color: Colors.black,
        ),
      ),
    );
  }
}

class RichTextWidget extends StatelessWidget {
  const RichTextWidget(
    this.textSpan, {
    Key? key,
    required this.isDark
  }) : super(key: key);

  final TextSpan textSpan;
  final bool isDark;

  @override
  bool shouldRebuild(covariant RichTextWidget oldWidget) {
    return oldWidget.textSpan.toPlainText() != textSpan.toPlainText() || oldWidget.isDark != isDark || textSpan.style != oldWidget.textSpan.style;
  }

  @override
  Widget build(BuildContext context) {
    return TextSelectable(
      textSpan: textSpan,
    );
  }
}

class ImageSelection extends StatelessWidget {
  const ImageSelection(
    this.child, {
    Key? key,
    this.text = ''
  }) : super(key: key);

  final Widget child;

  final String text;

  @override
  bool shouldRebuild(covariant ImageSelection oldWidget) {
    return oldWidget.text != text;
  }

  @override
  Widget build(BuildContext context) {
    return BoxSelectable(
      child: child,
      text: text,
    );
  }
}

// Note truoc khi run can them shouldRebuild theo PR: https://github.com/flutter/flutter/pull/25246/files