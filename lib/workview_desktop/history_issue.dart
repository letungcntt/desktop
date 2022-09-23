import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/markdown/style_sheet.dart';
import 'package:workcake/markdown/widget.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workview_desktop/markdown_checkbox.dart';

import '../components/message_item/attachments/images_gallery.dart';
import '../components/message_item/chat_item_macOS.dart';

class HistoryIssue extends StatefulWidget {
  HistoryIssue({
    Key? key,
    required this.images,
    required this.history,
    required this.editor,
    required this.text,
    required this.dateTime
  }) : super(key: key);

  final Map history;
  final List images;
  final Map editor;
  final String text;
  final String dateTime;

  @override
  _HistoryIssueState createState() => _HistoryIssueState();
}

class _HistoryIssueState extends State<HistoryIssue> {
  String previewText = '';
  bool isExpanded = false;
  String fullText = '';
  bool canExpanded = false;

  @override
  void initState() {
    final List<String> splitSnippet =  widget.text.trim().split('\n');
    previewText = splitSnippet.length > 8 ? splitSnippet.sublist(0, 8).join('\n').trimRight() : widget.text.trimRight();
    fullText = widget.text;
    if(previewText == '') previewText = "_No description provided._";

    if(splitSnippet.length > 8) {
      canExpanded = true;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant HistoryIssue oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final bool isDark = auth.theme == ThemeType.DARK;
    final List images = widget.images;
    final Map history = widget.history;
    final Map editor = widget.editor;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (auth.userId != history['user_id']) {
                    onShowUserInfo(context, history['user_id']);
                  }
                },
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                child: CachedAvatar(
                  editor["avatar_url"],
                  height: 36, width: 36,
                  isRound: true,
                  name: editor["full_name"],
                  isAvatar: true,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (auth.userId != history['user_id']) {
                    onShowUserInfo(context, history['user_id']);
                  }
                },
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                child: Text(
                  editor["full_name"],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                widget.dateTime,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Color(0xFF323F4B)),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(left: 48),
            child: CustomSelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Markdown(
                    softLineBreak: true,
                    physics: const NeverScrollableScrollPhysics(),
                    imageBuilder: (uri, title, alt) {
                      return const SizedBox();
                    },
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                      ),
                      a: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline, fontSize: 14.5),
                      code: const TextStyle(fontSize: 13, color: Color(0xff40A9FF), fontFamily: "Menlo", height: 1.3),
                      codeblockDecoration: BoxDecoration()
                    ),
                    onTapLink: (link, url, uri) async {
                      if (await canLaunch(url ?? "")) {
                        await launch(url ?? "");
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    selectable: true,
                    checkboxBuilder: (value, variable) {
                      return MarkdownCheckbox( value: value, variable: variable, onChangeCheckBox: (_, __, ___) {}, isDark: isDark, isBlockCheckBox: true);
                    },
                    data: isExpanded ? fullText : previewText,
                  ),
                  if(canExpanded) InkWell(
                    onTap: () => setState(() => isExpanded = !isExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      margin: const EdgeInsets.only(top: 16),
                      width: 88,
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? PhosphorIcons.caretUp : PhosphorIcons.caretRight,
                            color: isDark ? Palette.calendulaGold : Palette.dayBlue,
                            size: 18,
                          ),
                          Text(
                            isExpanded ? ' Collapse' : ' Expand',
                            style: TextStyle(
                              color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ),
          if (images.isNotEmpty) Container(
            padding: const EdgeInsets.only(left: 14, right: 16),
            child: Column(
              children: [
                SizedBox(height: 16),
                Container(
                  height: 1,
                  color: isDark ? const Color(0xff5E5E5E) : const Color(0xffCBD2D9),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: 30.6,
                          child: Icon(
                            Icons.attachment_sharp,
                            color: isDark ? Palette.calendulaGold : Palette.dayBlue,
                            size: 18,
                          )
                        ),
                        const SizedBox(width: 8),
                        Text(S.current.attachments, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, color: isDark ? Palette.calendulaGold : Palette.dayBlue, height: 1.2)),
                      ]
                    )
                  ]
                ),
                ImagesGallery(
                  isChildMessage: false, att: {"data": images},
                  isThread: false,
                  fromIssue: true,
                  isConversation: false,
                )
              ]
            ),
          )
        ],
      )
    );

  }
}