// ignore_for_file: camel_case_types

import 'package:context_menus/context_menus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/create_sticker.dart';
import 'package:workcake/components/message_item/attachments/sticker_file.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/workspaces/list_sticker.dart';

import '../providers/providers.dart';

enum TYPE_STICKER {
  DUCKS, PEPE, PANDA, EMOJI, OTHER
}

class ListStickersWidget extends StatefulWidget {
  final List data;
  final selectSticker;
  final bool isCreateSticker;
  final channelId;
  final workspaceId;

  const ListStickersWidget({
    Key? key,
    required this.data,
    required this.selectSticker,
    required this.isCreateSticker,
    required this.workspaceId,
    required this.channelId
  }) : super(key: key);

  @override
  _ListStickersWidgetState createState() => _ListStickersWidgetState();
}

class _ListStickersWidgetState extends State<ListStickersWidget> {
  List stickers = [];
  TYPE_STICKER type = TYPE_STICKER.DUCKS;

  @override
  void initState() {
    setState(() {
      stickers = ducks;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget renderItem(data, TYPE_STICKER typeData, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          stickers = data;
          type = typeData;
        });
      },
      child: Container(
        width: 52, height: 52,
        padding: EdgeInsets.all(6),
        color: typeData == type ? (isDark ? Color(0xffE5E5E5).withOpacity(0.25) : Color(0xffF3F3F3)) : Colors.transparent,
        child: typeData != TYPE_STICKER.PANDA ? Lottie.network(
          typeData == TYPE_STICKER.OTHER ? emojis.last['content_url'] : data[0]["content_url"],
          animate: false,
        ) : ExtendedImage.network(data[0]["content_url"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    bool isDark = auth.theme == ThemeType.DARK;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
          ),
          height: 36,
          child: Focus(
            onFocusChange: (value) {
              Provider.of<Windows>(context, listen: false).isOtherFocus = value;
            },
            child: TextFormField(
              decoration: InputDecoration(
                hintText: "Search stickers",
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass,
                  color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 16
                ),
                contentPadding: EdgeInsets.only(left: 12),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                  borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                  borderRadius: BorderRadius.all(Radius.circular(4))
                )
              ),
              cursorColor: isDark ? Colors.white : null,
              style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
              onChanged: (value) {
                String keyword = value.toLowerCase();
                setState(() {
                  switch (type) {
                    case TYPE_STICKER.DUCKS:
                      stickers = ducks.where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').contains(keyword)).toList();
                      break;
                    case TYPE_STICKER.PEPE:
                      stickers = pepeStickers.where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').contains(keyword)).toList();
                      break;
                    case TYPE_STICKER.PANDA:
                      stickers = pandaStickers.where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').contains(keyword)).toList();
                      break;
                    case TYPE_STICKER.EMOJI:
                      stickers = (emojis + otherSticker).where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').contains(keyword)).toList();
                      break;
                    case TYPE_STICKER.OTHER:
                      stickers = widget.data.where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').toString().contains(keyword)).toList();
                      break;
                    default:
                      stickers = ducks;
                  }
                });
              },
            ),
          ),
        ),
        SingleChildScrollView(
          child: Container(
            width: 400, height: 415,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
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
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.75,
                color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)
              )
            )
          ),
          child: Row(
            children: [
              InkWell(
                child: SvgPicture.asset("assets/icons/recent.svg", color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)
                      ),
                      right: BorderSide(
                        color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)
                      )
                    )
                  ),
                  child: Row(
                    children: [
                      renderItem(ducks, TYPE_STICKER.DUCKS, isDark),
                      SizedBox(width: 4),
                      renderItem(pepeStickers, TYPE_STICKER.PEPE, isDark),
                      SizedBox(width: 4),
                      renderItem(emojis + otherSticker, TYPE_STICKER.EMOJI, isDark),
                      SizedBox(width: 4),
                      renderItem(pandaStickers, TYPE_STICKER.PANDA, isDark),
                      SizedBox(width: 4),
                      if(widget.data.isNotEmpty) renderItem(widget.data, TYPE_STICKER.OTHER, isDark),
                    ],
                  ),
                ),
              ),
              HoverItem(
                colorHover: Palette.hoverColorDefault,
                child: InkWell(
                  onTap: widget.isCreateSticker ? () => onAddNewSticker(isDark) : null,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      PhosphorIcons.plus, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  onAddNewSticker(bool isDark) {
    context.contextMenuOverlay.close();
    showModal(
      context: context, builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          content: Container(
            width: 700, height: 700,
            child: ContextMenuOverlay(child: AddSticker(workspaceId: widget.workspaceId, channelId: widget.channelId,))
          ),
        );
      }
    );
  }
}
