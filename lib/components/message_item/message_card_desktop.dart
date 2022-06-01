import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/validators.dart';
import 'package:workcake/components/link_preview.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/models/models.dart';
import 'package:dart_emoji/dart_emoji.dart';

List charCodeIcon = [":)", "=)", ":D", "<3", ":*", ";)", ":(", ":(("];
List replaceIcon = [":slightly_smiling_face:", ":smiley:", ":smile:", ":heart:", ":kissing_heart:", ":wink:", ":disappointed:", ":cry:"];
class MessageCardDesktop extends StatefulWidget {
  final message;
  final id;
  final onlyPreview;
  final lastEditedAt;

  const MessageCardDesktop({
    Key? key,
    @required this.message,
    @required this.id,
    this.onlyPreview = false,
    this.lastEditedAt
  }) : super(key: key);

  @override
  _MessageCardDesktopState createState() => _MessageCardDesktopState();
}

class _MessageCardDesktopState extends State<MessageCardDesktop> {
  List listUrl = [];
  bool isShift = false;

  @override
  void initState() {
    super.initState();
    initialize();
    RawKeyboard.instance.addListener(handleKey);
  }

  handleKey(RawKeyEvent event) {
    if (isShift != event.isShiftPressed) setState(() => isShift = event.isShiftPressed);
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleKey);
    super.dispose();
  }

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id || oldWidget.message != widget.message) {
      initialize();
    }
  }

  initialize() async {
    setState(() { listUrl = []; });
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    Iterable<RegExpMatch> matches = exp.allMatches(widget.message);
    List list = [];

    if (matches.toList().isNotEmpty) {
      for (var match in matches) {
        var url = widget.message.substring(match.start, match.end);

        if (url.contains("http")) {
          list.add(url);
        }
      }

      if (list.isNotEmpty) {
        setState(() { listUrl = list; });
      }
    }
  }

  void openLink(e, bool isEmail) async{
    if (isEmail) {
      Clipboard.setData(ClipboardData(text: e));
    } else {
      if (await canLaunch(e.toString().trim())) {
        await launch(e.toString().trim());
      } else {
        throw 'Could not launch $e';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List list = widget.message.replaceAll("\n", " \n").split(" ");
    var parser = EmojiParser();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(!widget.onlyPreview) RichTextWidget(
          TextSpan(
            children: [
              TextSpan(
                style: const TextStyle(fontSize: 14.5, height: 1.5),
                children: list.map<TextSpan>((e){
                  Iterable<RegExpMatch> matches = exp.allMatches(e);
                  bool isLink = false;
                  bool isEmail = Validators.validateEmail(e);
                  if (e.startsWith('\n')) {
                    isLink = e.startsWith('\nhttp');
                  } else {
                    isLink = e.startsWith('http');
                  }
                  if ((matches.isNotEmpty && isLink) || isEmail) {
                    return TextSpan(
                      children: [
                        TextSpan(
                          text: e,
                          style: matches.isNotEmpty || isEmail
                            ? TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline)
                            : TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                          recognizer: TapGestureRecognizer()..onTapUp = (matches.isNotEmpty || isEmail) && !isShift ? (_) {
                            openLink(e, isEmail);
                          } : null,
                        ),
                        const TextSpan(text: " ")
                      ]
                    );
                  } else {
                    int indexIcon = charCodeIcon.indexWhere((element) => element == e);
                    if(indexIcon != -1) {
                      e = replaceIcon[indexIcon];
                    }
                    return TextSpan(text: "${parser.emojify(e)} ", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: list.length == 1 && EmojiUtil.hasTextOnlyEmojis(e) ? 22 : 14.5, height: EmojiUtil.hasTextOnlyEmojis(e) ? 1.2 : 1.5));
                  }
                }).toList()
              ),
              TextSpan(
                text: widget.lastEditedAt != null ? '(edited)' : '',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xff6c6f71))
              )
            ]
          ),
          isDark: isDark,
          key: Key('MessageItem${widget.id}')
        ),
        if (listUrl.isNotEmpty) Container(
          child: LinkPreview(url: listUrl.first, key: Key(widget.id.toString()))
        )
      ]
    );
  }
}

class CustomBorder extends ShapeBorder {
  final bool usePadding;

  CustomBorder({this.usePadding = true});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 18);

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    throw UnimplementedError();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    rect = Rect.fromPoints(rect.topLeft - const Offset(0, 10), rect.bottomRight - const Offset(0, 10));
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)))
      ..moveTo(rect.bottomCenter.dx - 5, rect.bottomCenter.dy)
      ..relativeLineTo(5, 7)
      ..relativeLineTo(5, -7)
      ..close();
  }
}
