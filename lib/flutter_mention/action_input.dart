import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/sticker_emojis.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class ActionInput extends StatefulWidget {
  const ActionInput({
    Key? key,
    required this.openFileSelector,
    required this.selectEmoji,
    this.isThreadTab = false,
    this.showRecordMessage,
    required this.selectSticker
  }) : super(key: key);

  final Function? showRecordMessage;
  final Function openFileSelector;
  final Function selectEmoji;
  final bool isThreadTab;
  final Function selectSticker;

  @override
  State<ActionInput> createState() => _ActionInputState();
}

class _ActionInputState extends State<ActionInput> {

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: EdgeInsets.only(left: 5, bottom: widget.isThreadTab ? 10 : 0),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
              ),
              child: Icon(CupertinoIcons.plus, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
              onPressed: () {
                widget.openFileSelector();
              }
            )
          ),
          if (!widget.isThreadTab && Platform.isMacOS) Container(
            width: 30,
            height: 30,
            margin: EdgeInsets.only(left: 4),
            child: HoverItem(
              colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
              child: TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
                ),
                // child: const Icon(Icons.mic, color: Colors.grey, size: 23),
                child: Icon(CupertinoIcons.mic, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                onPressed: () {
                  widget.showRecordMessage!(true);
                }
              ),
            )
          ),
          SizedBox(width: 4),
          Container(
            margin: EdgeInsets.only(bottom: widget.isThreadTab ? 10 : 0),
            child: StickerEmojiWidget(
              data: [],
              selectSticker: widget.selectSticker,
              channelId: 0,
              workspaceId: 0,
              onSelect: (emoji){
                widget.selectEmoji(emoji);
              },
              isCreateSticker: false
            ),
          )
        ],
      ),
    );
  }
}