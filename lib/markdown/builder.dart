// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/video_player.dart';
import 'package:workcake/components/custom_highlight_view.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/providers/providers.dart';

import '../components/message_item/attachments/text_file.dart';
import '_functions_io.dart' if (dart.library.html) '_functions_web.dart';
import 'style_sheet.dart';
import 'widget.dart';

const List<String> _kBlockTags = const <String>[
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
  'pre',
  'ol',
  'ul',
  'hr',
  'table',
  'thead',
  'tbody',
  'tr'
];

const List<String> _kListTags = const <String>['ul', 'ol'];

bool _isBlockTag(String? tag) => _kBlockTags.contains(tag);

bool _isListTag(String tag) => _kListTags.contains(tag);

class _BlockElement {
  _BlockElement(this.tag);

  final String? tag;
  final List<Widget> children = <Widget>[];

  int nextListIndex = 0;
}

class _TableElement {
  final List<TableRow> rows = <TableRow>[];
}

/// A collection of widgets that should be placed adjacent to (inline with)
/// other inline elements in the same parent block.
///
/// Inline elements can be textual (a/em/strong) represented by [RichText]
/// widgets or images (img) represented by [Image.network] widgets.
///
/// Inline elements can be nested within other inline elements, inheriting their
/// parent's style along with the style of the block they are in.
///
/// When laying out inline widgets, first, any adjacent RichText widgets are
/// merged, then, all inline widgets are enclosed in a parent [Wrap] widget.
class _InlineElement {
  _InlineElement(this.tag, {this.style});

  final String? tag;

  /// Created by merging the style defined for this element's [tag] in the
  /// delegate's [MarkdownStyleSheet] with the style of its parent.
  final TextStyle? style;

  final List<Widget> children = <Widget>[];
}

abstract class MarkdownBuilderDelegate {
  /// Returns a gesture recognizer to use for an `a` element with the given
  /// text, `href` attribute, and title.
  GestureRecognizer createLink(String text, String? href, String title);

  /// Returns formatted text to use to display the given contents of a `pre`
  /// element.
  ///
  /// The `styleSheet` is the value of [MarkdownBuilder.styleSheet].
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code);
}

/// Builds a [Widget] tree from parsed Markdown.
///
/// See also:
///
///  * [Markdown], which is a widget that parses and displays Markdown.
class MarkdownBuilder implements md.NodeVisitor {
  /// Creates an object that builds a [Widget] tree from parsed Markdown.
  MarkdownBuilder({
    required this.delegate,
    required this.selectable,
    required this.styleSheet,
    required this.imageDirectory,
    required this.imageBuilder,
    required this.checkboxBuilder,
    required this.bulletBuilder,
    required this.builders,
    required this.listItemCrossAxisAlignment,
    this.fitContent = false,
    this.onTapText,
    required this.context,
    required this.isViewMention,
    this.softLineBreak = false,
  });

  final bool isViewMention;

  final BuildContext context;

  /// A delegate that controls how link and `pre` elements behave.
  final MarkdownBuilderDelegate delegate;

  /// If true, the text is selectable.
  ///
  /// Defaults to false.
  final bool selectable;

  /// Defines which [TextStyle] objects to use for each type of element.
  final MarkdownStyleSheet styleSheet;

  /// The base directory holding images referenced by Img tags with local or network file paths.
  final String? imageDirectory;

  /// Call when build an image widget.
  final MarkdownImageBuilder? imageBuilder;

  /// Call when build a checkbox widget.
  final checkboxBuilder;

  /// Called when building a custom bullet.
  final MarkdownBulletBuilder? bulletBuilder;

  /// Call when build a custom widget.
  final Map<String, MarkdownElementBuilder> builders;

  /// Whether to allow the widget to fit the child content.
  final bool fitContent;

  /// Controls the cross axis alignment for the bullet and list item content
  /// in lists.
  ///
  /// Defaults to [MarkdownListItemCrossAxisAlignment.baseline], which
  /// does not allow for intrinsic height measurements.
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  /// Default tap handler used when [selectable] is set to true
  final VoidCallback? onTapText;

  final List<String> _listIndents = <String>[];
  final List<_BlockElement> _blocks = <_BlockElement>[];
  final List<_TableElement> _tables = <_TableElement>[];
  final List<_InlineElement> _inlines = <_InlineElement>[];
  final List<GestureRecognizer> _linkHandlers = <GestureRecognizer>[];
  String? _currentBlockTag;
  String? _lastTag;
  bool _isInBlockquote = false;
  final bool softLineBreak;

  /// Returns widgets that display the given Markdown nodes.
  ///
  /// The returned widgets are typically used as children in a [ListView].
  List<Widget> build(List<md.Node> nodes) {
    _listIndents.clear();
    _blocks.clear();
    _tables.clear();
    _inlines.clear();
    _linkHandlers.clear();
    _isInBlockquote = false;

    _blocks.add(_BlockElement(null));

    for (md.Node node in nodes) {
      assert(_blocks.length == 1);
      node.accept(this);
    }

    assert(_tables.isEmpty);
    assert(_inlines.isEmpty);
    assert(!_isInBlockquote);
    return _blocks.single.children;
  }

  @override
  bool visitElementBefore(md.Element element) {
    final String tag = element.tag;
    if (_currentBlockTag == null) _currentBlockTag = tag;

    if (builders.containsKey(tag)) {
      builders[tag]!.visitElementBefore(element);
    }

    var start;
    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded();
      if (_isListTag(tag)) {
        _listIndents.add(tag);
        if (element.attributes["start"] != null)
          start = int.parse(element.attributes["start"]!) - 1;
      } else if (tag == 'blockquote') {
        _isInBlockquote = true;
      } else if (tag == 'table') {
        _tables.add(_TableElement());
      } else if (tag == 'tr') {
        final length = _tables.single.rows.length;
        BoxDecoration? decoration =
            styleSheet.tableCellsDecoration as BoxDecoration?;
        if (length == 0 || length % 2 == 1) decoration = null;
        _tables.single.rows.add(TableRow(
          decoration: decoration,
          children: <Widget>[],
        ));
      }
      var bElement = _BlockElement(tag);
      if (start != null) bElement.nextListIndex = start;
      _blocks.add(bElement);
    } else {
      if (tag == 'a') {
        String? text = extractTextFromElement(element);
        // Don't add empty links
        if (text == null) {
          return false;
        }
        String? destination = element.attributes['href'];
        String title = element.attributes['title'] ?? "";

        _linkHandlers.add(
          delegate.createLink(text, destination, title),
        );
      }

      _addParentInlineIfNeeded(_blocks.last.tag);

      // The Markdown parser passes empty table data tags for blank
      // table cells. Insert a text node with an empty string in this
      // case for the table cell to get properly created.
      if (element.tag == 'td' &&
          element.children != null &&
          element.children!.isEmpty) {
        element.children!.add(md.Text(''));
      }

      TextStyle parentStyle = _inlines.last.style!;
      _inlines.add(_InlineElement(
        tag,
        style: parentStyle.merge(styleSheet.styles[tag]),
      ));
    }

    return true;
  }

  String? extractTextFromElement(element) {
    return element is md.Element && (element.children?.isNotEmpty ?? false)
        ? element.children!
            .map((e) => e is md.Text ? e.text : extractTextFromElement(e))
            .join("")
        : ((element.attributes?.isNotEmpty ?? false)
            ? element.attributes["alt"]
            : "");
  }

  @override
  void visitText(md.Text text) {
    // Don't allow text directly under the root.
    if (_blocks.last.tag == null) return;

    _addParentInlineIfNeeded(_blocks.last.tag);

    // Define trim text function to remove spaces from text elements in
    // accordance with Markdown specifications.
    final trimText = (String text) {
      // The leading spaces pattern is used to identify spaces
      // at the beginning of a line of text.
      final _leadingSpacesPattern = RegExp(r'^ *');

      // The soft line break pattern is used to identify the spaces at the end of a
      // line of text and the leading spaces in the immediately following the line
      // of text. These spaces are removed in accordance with the Markdown
      // specification on soft line breaks when lines of text are joined.
      final RegExp _softLineBreak = RegExp(r' ?\n *');

      // Leading spaces following a hard line break are ignored.
      // https://github.github.com/gfm/#example-657
      if (_lastTag == 'br') {
        text = text.replaceAll(_leadingSpacesPattern, '');
      }

      if (softLineBreak) {
        return text;
      }
      return text.replaceAll(_softLineBreak, ' ');
    };

    Widget? child;
    if (_blocks.isNotEmpty && builders.containsKey(_blocks.last.tag)) {
      child = builders[_blocks.last.tag!]!
          .visitText(text, styleSheet.styles[_blocks.last.tag!]);
    } else if (_blocks.last.tag == 'pre') {
      if (text.text.split("\n").length > 40) {
        child = _buildRichText(delegate.formatText(styleSheet, text.text));
      } else {
        child = _buildRichText(delegate.formatText(styleSheet, text.text));
      }
    } else {
      String renderWhiteSpace = _inlines.last.tag == 'code' ? ' ' : '';
      TextSpan textSpan = TextSpan(
        style: _isInBlockquote
          ? styleSheet.blockquote!.merge(_inlines.last.style)
          : _inlines.last.style,
        text: _isInBlockquote ? text.text : renderWhiteSpace + trimText(text.text) + renderWhiteSpace,
        recognizer: _linkHandlers.isNotEmpty ? _linkHandlers.last : null,
      );

      child = _buildRichText(
        textSpan,
        textAlign: _textAlignForBlockTag(_currentBlockTag),
      );
    }
    if (child != null) {
      _inlines.last.children.add(child);
    }
  }

  @override
  void visitElementAfter(md.Element element) {
    final String tag = element.tag;

    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded();

      final _BlockElement current = _blocks.removeLast();
      Widget child;

      if (current.children.isNotEmpty) {
        child = Column(
          crossAxisAlignment: fitContent
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          children: current.children,
        );
      } else {
        child = const SizedBox();
      }

      if (_isListTag(tag)) {
        assert(_listIndents.isNotEmpty);
        _listIndents.removeLast();
      } else if (tag == 'li') {
        if (_listIndents.isNotEmpty) {
          if (element.children!.length == 0) {
            element.children!.add(md.Text(''));
          }
          Widget bullet;
          dynamic el = element.children![0];
          if (el is md.Element && el.attributes['type'] == 'checkbox') {
            bool val = el.attributes['checked'] != 'false';
            var elText = (element.children!.length > 1) ? element.children![1].textContent : "";

            bullet = _buildCheckbox(val, elText);
          } else {
            bullet = _buildBullet(_listIndents.last);
          }
          child = Row(
            textBaseline: listItemCrossAxisAlignment ==
                    MarkdownListItemCrossAxisAlignment.start
                ? null
                : TextBaseline.alphabetic,
            crossAxisAlignment: listItemCrossAxisAlignment ==
                    MarkdownListItemCrossAxisAlignment.start
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.baseline,
            children: <Widget>[
              SizedBox(
                width: styleSheet.listIndent! +
                    styleSheet.listBulletPadding!.left +
                    styleSheet.listBulletPadding!.right,
                child: bullet,
              ),
              Expanded(child: child)
            ],
          );
        }
      } else if (tag == 'table') {
        child = Table(
          defaultColumnWidth: styleSheet.tableColumnWidth!,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: styleSheet.tableBorder,
          children: _tables.removeLast().rows,
        );
      } else if (tag == 'blockquote') {
        _isInBlockquote = false;
        child = DecoratedBox(
          decoration: styleSheet.blockquoteDecoration!,
          child: Padding(
            padding: styleSheet.blockquotePadding!,
            child: child,
          ),
        );
      } else if (tag == 'pre') {
        var language = 'javascript';
        String lg = element.textContent;
        var list = lg.split("\n");
        List languages = ["java", "c", "dart","text"];
        final auth = Provider.of<Auth>(context, listen: true);
        final isDark = auth.theme == ThemeType.DARK;
        bool validateLanguage = false;

        if (list.length > 0 && languages.contains(list[0].trim())) {
          validateLanguage = true;
          language = list[0].trim();
        }

        child = SizedBox(
          width: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width,
          child: element.textContent== "" ? SizedBox(): CustomHighlightView(
            list.sublist(validateLanguage ? 1 : 0).join("\n"),
            language: language,
            backgroundColor: Colors.transparent,
            theme: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
              .platformBrightness == Brightness.dark
              ? atomOneLightTheme
              : atomOneDarkTheme,
            textStyle: GoogleFonts.robotoMono(color: isDark ? Color(0xffEAE8E8) : Color(0xff3D3D3D)),
            padding: EdgeInsets.symmetric(horizontal: 6)
          ),
        );
      } else if (tag == 'hr') {
        child = Container(decoration: styleSheet.horizontalRuleDecoration);
      }

      _addBlockChild(child);
    } else {
      final _InlineElement current = _inlines.removeLast();
      final _InlineElement parent = _inlines.last;

      if (builders.containsKey(tag)) {
        final Widget? child =
            builders[tag]!.visitElementAfter(element, styleSheet.styles[tag]);
        if (child != null) current.children[0] = child;
      } else if (tag == 'img') {
        // create an image widget for this image
        current.children.add(_buildImage(
          element.attributes['src']!,
          element.attributes['title'],
          element.attributes['alt'],
        ));
      } else if (tag == 'br') {
        current.children.add(_buildRichText(const TextSpan(text: '\n')));
      } else if (tag == 'th' || tag == 'td') {
        TextAlign? align;
        String? style = element.attributes['style'];
        if (style == null) {
          align = tag == 'th' ? styleSheet.tableHeadAlign : TextAlign.left;
        } else {
          RegExp regExp = RegExp(r'text-align: (left|center|right)');
          Match match = regExp.matchAsPrefix(style)!;
          switch (match[1]) {
            case 'left':
              align = TextAlign.left;
              break;
            case 'center':
              align = TextAlign.center;
              break;
            case 'right':
              align = TextAlign.right;
              break;
          }
        }
        Widget child = _buildTableCell(
          _mergeInlineChildren(current.children, align),
          textAlign: align,
        );
        _tables.single.rows.last.children!.add(child);
      } else if (tag == 'a') {
        _linkHandlers.removeLast();
      }

      if (current.children.isNotEmpty) {
        parent.children.addAll(current.children);
      }
    }
    if (_currentBlockTag == tag) _currentBlockTag = null;
    _lastTag = tag;
  }

  Widget _buildImage(String src, String? title, String? alt) {
    final List<String> parts = src.split('#');
    if (parts.isEmpty) return const SizedBox();

    final String path = parts.first;
    double? width;
    double? height;
    if (parts.length == 2) {
      final List<String> dimensions = parts.last.split('x');
      if (dimensions.length == 2) {
        width = double.parse(dimensions[0]);
        height = double.parse(dimensions[1]);
      }
    }

    Uri uri = Uri.parse(path);
    Widget child;

    List<String> list = src.split('.');
    String type = Utils.getLanguageFile((list.length > 1 ? list.last : '').toLowerCase());
    int index = Utils.languages.indexWhere((ele) => ele == type);
    if(index != -1) {
      final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

      child = FutureBuilder<String>(
        future: Utils.onRenderSnippet(src),
        builder: (ctx, snapshotString) {
          String data = snapshotString.data ?? 'On loading data ...';

          return snapshotString.connectionState == ConnectionState.waiting ? Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB)
            ),
            width: 150, height: 150,
            child: SpinKitFadingCircle(
              color: isDark ? Colors.white60 : const Color(0xff096DD9),
              size: 35,
            ),
          ) : TextFile(
            att: {
              'content_url': src,
              'mime_type': src.split('.').last,
              'preview': data.length >= 1000 ? data.substring(0, 1000) + ' ...'  : data,
              'name': alt
            },
            isChannel: true,
          );
        }
      );
    } else if (['mp4', 'mov', 'flv', 'avi'].contains(type)) {
      child = VideoPlayer(
        att: {
          'content_url': uri.toString(),
          'name': src.split('/').last,
          'url_thumbnail': 'https://statics.pancake.vn/panchat-dev/2022/7/13/a09eefc0163c17427affb4b6bf939e337aeb54da.mp4',
          'image_data': {
            'width': 720,
            'height': 480
          }
        }
      );
    } else if (imageBuilder != null) {
      child = imageBuilder!(uri, title, alt);
    } else {
      child = kDefaultImageBuilder(uri, imageDirectory, width, height);
    }

    if (_linkHandlers.isNotEmpty) {
      TapGestureRecognizer recognizer =
          _linkHandlers.last as TapGestureRecognizer;
      return GestureDetector(child: child, onTap: recognizer.onTap);
    } else {
      return child;
    }
  }

  Widget _buildCheckbox(bool checked, list) {
    if (checkboxBuilder != null) {
      return checkboxBuilder!(checked, list);
    }
    return Padding(
      padding: styleSheet.listBulletPadding!,
      child: Icon(
        checked ? Icons.check_box : Icons.check_box_outline_blank,
        size: styleSheet.checkbox!.fontSize,
        color: styleSheet.checkbox!.color,
      ),
    );
  }

  Widget _buildBullet(String listTag) {
    final int index = _blocks.last.nextListIndex;
    final bool isUnordered = listTag == 'ul';

    if (bulletBuilder != null) {
      return Padding(
        padding: styleSheet.listBulletPadding!,
        child: bulletBuilder!(index,
            isUnordered ? BulletStyle.unorderedList : BulletStyle.orderedList),
      );
    }

    if (isUnordered) {
      return Padding(
        padding: styleSheet.listBulletPadding!,
        child: Text(
          '•',
          textAlign: TextAlign.center,
          style: styleSheet.listBullet,
        ),
      );
    }

    return Padding(
      padding: styleSheet.listBulletPadding!,
      child: Text(
        '${index + 1}.',
        textAlign: TextAlign.right,
        style: styleSheet.listBullet,
      ),
    );
  }

  Widget _buildTableCell(List<Widget?> children, {TextAlign? textAlign}) {
    return TableCell(
      child: Padding(
        padding: styleSheet.tableCellsPadding!,
        child: DefaultTextStyle(
          style: styleSheet.tableBody!,
          textAlign: textAlign,
          child: Wrap(children: children as List<Widget>),
        ),
      ),
    );
  }

  void _addParentInlineIfNeeded(String? tag) {
    if (_inlines.isEmpty) {
      _inlines.add(_InlineElement(
        tag,
        style: styleSheet.styles[tag!],
      ));
    }
  }

  void _addBlockChild(Widget child) {
    final _BlockElement parent = _blocks.last;
    if (parent.children.isNotEmpty) {
      parent.children.add(SizedBox(height: styleSheet.blockSpacing));
    }
    parent.children.add(child);
    parent.nextListIndex += 1;
  }

  void _addAnonymousBlockIfNeeded() {
    if (_inlines.isEmpty) return;

    TextAlign textAlign = TextAlign.start;
    if (_isBlockTag(_currentBlockTag)) {
      textAlign = _textAlignForBlockTag(_currentBlockTag);
    }

    final _InlineElement inline = _inlines.single;
    if (inline.children.isNotEmpty) {
      List<Widget> mergedInlines = _mergeInlineChildren(
        inline.children,
        textAlign,
      );
      final wrap = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // crossAxisAlignment: WrapCrossAlignment.center,
        children: mergedInlines,
        mainAxisAlignment: MainAxisAlignment.start,
        // alignment: blockAlignment,
      );
      _addBlockChild(wrap);
      _inlines.clear();
    }
  }

  /// Merges adjacent [TextSpan] children
  List<Widget> _mergeInlineChildren(
    List<Widget> children,
    TextAlign? textAlign,
  ) {
    List<Widget> mergedTexts = <Widget>[];
    for (Widget child in children) {
      if (mergedTexts.isNotEmpty && mergedTexts.last is RichText && child is RichText) {
        RichText previous = mergedTexts.removeLast() as RichText;
        TextSpan previousTextSpan = previous.text as TextSpan;
        List<TextSpan> children = previousTextSpan.children != null
            ? List.from(previousTextSpan.children!)
            : [previousTextSpan];
        children.add(child.text as TextSpan);
        TextSpan? mergedSpan = _mergeSimilarTextSpans(children);
        mergedTexts.add(_buildRichText(
          mergedSpan,
          textAlign: textAlign,
        ));
      } else if (mergedTexts.isNotEmpty && mergedTexts.last is SelectableText && child is SelectableText) {
        SelectableText previous = mergedTexts.removeLast() as SelectableText;
        TextSpan previousTextSpan = previous.textSpan!;
        List<TextSpan> children = previousTextSpan.children != null
            ? List.from(previousTextSpan.children!)
            : [previousTextSpan];
        if (child.textSpan != null) {
          children.add(child.textSpan!);
        }
        TextSpan? mergedSpan = _mergeSimilarTextSpans(children);
        mergedTexts.add(
          _buildRichText(
            mergedSpan,
            textAlign: textAlign,
          ),
        );
      } else if (mergedTexts.isNotEmpty && mergedTexts.last is RichTextWidget && child is RichTextWidget) {
        RichTextWidget previous = mergedTexts.removeLast() as RichTextWidget;
        TextSpan previousTextSpan = previous.textSpan;
        List<TextSpan> children = previousTextSpan.children != null
            ? List.from(previousTextSpan.children!)
            : [previousTextSpan];
        children.add(child.textSpan);
        TextSpan? mergedSpan = _mergeSimilarTextSpans(children);
        mergedTexts.add(_buildRichText(
          mergedSpan,
          textAlign: textAlign,
        ));
      } else {
        mergedTexts.add(child);
      }
    }
    return mergedTexts;
  }

  TextAlign _textAlignForBlockTag(String? blockTag) {
    WrapAlignment wrapAlignment = _wrapAlignmentForBlockTag(blockTag);
    switch (wrapAlignment) {
      case WrapAlignment.start:
        return TextAlign.start;
      case WrapAlignment.center:
        return TextAlign.center;
      case WrapAlignment.end:
        return TextAlign.end;
      case WrapAlignment.spaceAround:
        return TextAlign.justify;
      case WrapAlignment.spaceBetween:
        return TextAlign.justify;
      case WrapAlignment.spaceEvenly:
        return TextAlign.justify;
    }
  }

  WrapAlignment _wrapAlignmentForBlockTag(String? blockTag) {
    if (blockTag == "p") return styleSheet.textAlign;
    if (blockTag == "h1") return styleSheet.h1Align;
    if (blockTag == "h2") return styleSheet.h2Align;
    if (blockTag == "h3") return styleSheet.h3Align;
    if (blockTag == "h4") return styleSheet.h4Align;
    if (blockTag == "h5") return styleSheet.h5Align;
    if (blockTag == "h6") return styleSheet.h6Align;
    if (blockTag == "ul") return styleSheet.unorderedListAlign;
    if (blockTag == "ol") return styleSheet.orderedListAlign;
    if (blockTag == "blockquote") return styleSheet.blockquoteAlign;
    if (blockTag == "pre") return styleSheet.codeblockAlign;
    if (blockTag == "hr") print("Markdown did not handle hr for alignment");
    if (blockTag == "li") print("Markdown did not handle li for alignment");
    return WrapAlignment.start;
  }

  /// Combine text spans with equivalent properties into a single span.
  TextSpan? _mergeSimilarTextSpans(List<TextSpan>? textSpans) {
    if (textSpans == null || textSpans.length < 2) {
      return TextSpan(children: textSpans);
    }

    List<TextSpan> mergedSpans = <TextSpan>[textSpans.first];

    for (int index = 1; index < textSpans.length; index++) {
      TextSpan? nextChild = textSpans[index];
      if (nextChild.recognizer == mergedSpans.last.recognizer && nextChild.semanticsLabel == mergedSpans.last.semanticsLabel && nextChild.style == mergedSpans.last.style) {
        TextSpan previous = mergedSpans.removeLast();
        mergedSpans.add(TextSpan(
          text: previous.toPlainText() + nextChild.toPlainText(),
          recognizer: previous.recognizer,
          semanticsLabel: previous.semanticsLabel,
          style: previous.style,
        ));
      } else {
        mergedSpans.add(nextChild);
      }
    }

    // When the mergered spans compress into a single TextSpan return just that
    // TextSpan, otherwise bundle the set of TextSpans under a single parent.
    return mergedSpans.length == 1
        ? mergedSpans.first
        : TextSpan(children: mergedSpans);
  }

  parseMention(TextSpan? textSpan) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final userId = Provider.of<User>(context, listen: false).currentUser["id"];
    var text = textSpan!.text != null ? textSpan.text!.trim() : "";
    var r =  Provider.of<Messages>(context, listen: false).checkMentions(text);
    if (r["success"] == false){
      r = [{
        "type": "text",
        "value": text
      }];
    } else r = r["data"];
    return TextSpan(
      text: "",
      children: r.map<TextSpan>((ele) {
        if (ele["type"] == "user" || ele["type"] == "issue") {
          return TextSpan(
            text: ele["trigger"] + ele["name"],
            style: textSpan.style!.merge(TextStyle(
                color: isDark ? Palette.calendulaGold : Palette.dayBlue,
                fontSize: isViewMention ? 15.5 : textSpan.style!.fontSize,
                height: 1.3)),
            recognizer: userId != ele["id"] && ele["id"] != null
                ? (TapGestureRecognizer()..onTap = () {
                    ele["type"] == "user" ? onShowUserInfo(ele["id"], context) : onShowIssueInfo(ele);
                  })
                : null,
          );
        }
        return TextSpan(
            text: ele["value"],
            style: textSpan.style == null ? null : textSpan.style!.merge(TextStyle(
                fontSize: isViewMention ? 15.5 : textSpan.style!.fontSize)),
            recognizer: textSpan.recognizer,
            children: textSpan.children,
            semanticsLabel: textSpan.semanticsLabel);
      }).toList()
    );
  }

  onShowIssueInfo(issue) {
    Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...issue, 'type': 'edited', 'comments': [], 'timelines': [], 'fromMentions': true, "is_closed": false});
    final isOpen = Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.isDrawerOpen;
    if (!isOpen) Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
  }

  onShowUserInfo(id, context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
          insetPadding: EdgeInsets.all(0),
          contentPadding: EdgeInsets.all(0),
          content: UserProfileDesktop(userId: id),
        );
      }
    );
  }

  Widget _buildRichText(TextSpan? text, {TextAlign? textAlign}) {
    TextSpan newText = text == null ? text : (text.text ?? "").contains(RegExp(r'={7}[@|#]')) ? parseMention(text) : text;

    if (selectable) {
      return RichTextWidget(
        newText,
      );
    } else {
      return RichText(
        text: newText,
        textScaleFactor: styleSheet.textScaleFactor!,
        textAlign: textAlign ?? TextAlign.start,
      );
    }
  }
}
