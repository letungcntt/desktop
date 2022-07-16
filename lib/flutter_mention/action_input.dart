import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/message_item/attachments/sticker_file.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/workspaces/list_sticker.dart';


class ActionInput extends StatefulWidget {
  const ActionInput({Key? key, required this.openFileSelector, required this.selectEmoji, this.isThreadTab = false, this.showRecordMessage, required this.selectSticker}) : super(key: key);

  final Function? showRecordMessage;
  final Function openFileSelector;
  final Function selectEmoji;
  final bool isThreadTab;
  final Function selectSticker;

  @override
  State<ActionInput> createState() => _ActionInputState();
}

class _ActionInputState extends State<ActionInput> {
  final JustTheController _controller = JustTheController(value: TooltipStatus.isHidden);
  List stickers = ducks + pepeStickers + otherSticker;

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
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
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
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
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
            width: 30,
            height: 30,
            margin: EdgeInsets.only(bottom: widget.isThreadTab ? 10 : 0),
            child: HoverItem(
              colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
              child: JustTheTooltip(
                controller: _controller,
                preferredDirection: AxisDirection.up,
                isModal: true,
                content: Emoji(
                  workspaceId: "direct",
                  onSelect: (emoji){
                    widget.selectEmoji(emoji);
                  },
                  onClose: (){
                    _controller.hideTooltip();
                  }
                ),
                child: TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                  ),
                  child: Icon(CupertinoIcons.smiley, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                  onPressed: () {
                    _controller.showTooltip();
                  }
                ),
              ),
            )
          ),
          SizedBox(width: 4),
          ContextMenu(
            contextMenu: Container(
              decoration: BoxDecoration(
                color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
                border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)),
                borderRadius: BorderRadius.all(Radius.circular(8))
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75))
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Sticker',
                            style: TextStyle(
                              color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                              fontWeight: FontWeight.w500, fontSize: 16
                            ),
                          )
                        ),
                        InkWell(
                          child: Icon(
                            PhosphorIcons.xCircle,
                          size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                          ),
                          onTap: () => context.contextMenuOverlay.close(),
                        ),
                      ],
                    )
                  ),
                  SingleChildScrollView(
                    child: Container(
                      width: 300, height: 400,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 100,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: stickers.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 80, height: 80,
                            child: TextButton(
                              onPressed: () {
                                widget.selectSticker(stickers[index]);
                                context.contextMenuOverlay.close();
                              },
                              child: StickerFile(data: stickers[index], isPreview: true)
                            )
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            child: Container(
              width: 30,
              height: 30,
              margin: EdgeInsets.only(bottom: widget.isThreadTab ? 10 : 0),
              child: HoverItem(
                colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                child: Icon(PhosphorIcons.sticker, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
              )
            ),
          )
        ],
      ),
    );
  }
}