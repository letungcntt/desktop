// ignore_for_file: override_on_non_overriding_member

import 'package:flutter/material.dart';
class TextWidget extends StatelessWidget {
  const TextWidget(
    this.text, {
    Key? key,
    this.style,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.start
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);

    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }

    return RichText(
      text: TextSpan(
        text: text,
        style: effectiveTextStyle,
      ),
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

class RichTextWidget extends StatelessWidget {
  const RichTextWidget(
    this.textSpan, {
    Key? key,
  }) : super(key: key);

  final TextSpan textSpan;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textSpan,
    );
  }
}

// Note truoc khi run can them shouldRebuild theo PR: https://github.com/flutter/flutter/pull/25246/files