import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/render_list_emoji.dart';
import 'package:workcake/components/render_list_sticker.dart';
import 'package:workcake/emoji/emoji.dart';

import '../providers/providers.dart';

class StickerEmojiWidget extends StatefulWidget {
  final List data;
  final selectSticker;
  final onClose;
  final onSelect;
  final workspaceId;
  final channelId;
  final bool isCreateSticker;


  const StickerEmojiWidget({
    Key? key,
    required this.data,
    required this.selectSticker,
    required this.isCreateSticker,
    required this.workspaceId,
    required this.channelId,
    this.onClose,
    this.onSelect,
  }) : super(key: key);

  @override
  _StickerEmojiWidgetState createState() => _StickerEmojiWidgetState();
}

class _StickerEmojiWidgetState extends State<StickerEmojiWidget> {
  bool isEmoji = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    bool isDark = auth.theme == ThemeType.DARK;

    return ContextMenu(
      contextMenu: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            width: 400, height: 556.75,
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)),
              borderRadius: BorderRadius.all(Radius.circular(8))
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75))
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => isEmoji = false),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1.75,
                                    color: !isEmoji ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent
                                  )
                                ),
                              ),
                              child: Text(
                                'Sticker',
                                style: TextStyle(
                                  color: !isEmoji ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                  fontWeight: FontWeight.w500, fontSize: 16
                                ),
                              )
                            ),
                          ),
                          SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => isEmoji = true),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1.75,
                                    color: isEmoji ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : Colors.transparent
                                  )
                                ),
                              ),
                              child: Text(
                                'Emoji',
                                style: TextStyle(
                                  color: isEmoji ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                  fontWeight: FontWeight.w500, fontSize: 16
                                ),
                              )
                            ),
                          ),
                        ],
                      ),
                      HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        child: InkWell(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              PhosphorIcons.x,
                            size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                            ),
                          ),
                          onTap: () => context.contextMenuOverlay.close(),
                        ),
                      ),
                    ],
                  )
                ),
                isEmoji ? Expanded(
                  child: ListEmojiWidget(
                    onClose: () => context.contextMenuOverlay.close(),
                    onSelect: widget.onSelect,
                    workspaceId: widget.workspaceId
                  )
                ) : ListStickersWidget(
                  workspaceId: widget.workspaceId,
                  channelId: widget.channelId,
                  data: widget.data.where((e) => e['user_id'] == auth.userId).toList(),
                  selectSticker: widget.selectSticker,
                  isCreateSticker: widget.isCreateSticker
                )
              ],
            ),
          );
        }
      ),
      onTap: () => setState(() => isEmoji = false),
      child: Container(
        width: 30, height: 30,
        child: HoverItem(
          colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
          child: Container(
            padding: EdgeInsets.all(6),
            child: SvgPicture.asset(
              "assets/icons/Sticker.svg",
              color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65),
            ),
          )
        )
      ),
    );
  }
}
