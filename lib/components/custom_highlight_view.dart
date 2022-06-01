import 'package:flutter/material.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:highlighter/highlighter.dart' show highlight, Node;
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/widget_text.dart';

import '../models/models.dart';

class CustomHighlightView extends StatelessWidget {
  final String source;

  final String? language;

  final Map<String, TextStyle> theme;

  final EdgeInsetsGeometry? padding;

  final TextStyle? textStyle;

  final Color? backgroundColor;

  final bool isIssue;

  CustomHighlightView(
    String input, {
    this.language,
    this.theme = const {},
    this.padding,
    this.textStyle,
    int tabSize = 8,
    this.backgroundColor,
    this.isIssue = true
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    _traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        node.children!.forEach((n) {
          _traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        });
      }
    }

    for (var node in nodes) {
      _traverse(node);
    }

    return spans;
  }

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  // static const _defaultBackgroundColor = Color(0xffffffff);

  // See: https://github.com/flutter/flutter/issues/39998
  // So we just use monospace here for now
  static const _defaultFontFamily = 'monospace';

  @override
  Widget build(BuildContext context) {

    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    var _textStyle = TextStyle(
      fontFamily: _defaultFontFamily,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    
    if (textStyle != null) {
      _textStyle = _textStyle.merge(textStyle);
    }

    return Container(
      color: backgroundColor ?? (!isDark ? source.trim() == "" ? Palette.backgroundTheardLight : atomOneLightTheme[_rootKey]?.backgroundColor : source.trim() == "" ? Palette.backgroundTheardDark : atomOneDarkTheme[_rootKey]?.backgroundColor),
      // color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      padding: padding,
      child: isIssue ? RichTextWidget(
        TextSpan(
          style: _textStyle,
          children:
              _convert(highlight.parse(source, language: language).nodes!),
        ),
        isDark: isDark
      ) : SelectableText.rich(
        TextSpan(
          style: _textStyle,
          children:
              _convert(highlight.parse(source, language: language).nodes!),
        ),
      )
    );
  }
}