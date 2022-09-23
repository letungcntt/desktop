import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/message_item/attachments/sticker_file.dart';
import 'package:workcake/components/render_list_emoji.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/workspaces/list_sticker.dart';

import '../providers/providers.dart';

  class AddSticker extends StatefulWidget {
    AddSticker({
      Key? key,
      required this.workspaceId,
      required this.channelId
    }) : super(key: key);

    final channelId;
    final workspaceId;

    @override
    _AddStickerState createState() => _AddStickerState();
  }

class _AddStickerState extends State<AddSticker> {
  String contentUrl = "";
  bool isSticker = true;
  String? character;
  TextEditingController nameController = TextEditingController();
  TextEditingController tagsController = TextEditingController();
  bool isGuideView = false;
  List otherSticker = [];
  List data = [];

  @override
  void initState() {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    List stickers = Provider.of<Channels>(context, listen: false).getStickerChannel(currentChannel['id']).where((e) => e['user_id'] != auth.userId).toList();
    data = (Map.fromIterable(
      stickers,
      key: (e) => e["content_url"],
      value: (e) => e as Map)
    ).values.toList();
    otherSticker = data;
    super.initState();
  }

  uploadSticker(workspaceId, channelId, token) {
    final Map data = {
      'name': nameController.text,
      'tags': tagsController.text,
      'type': isSticker ? 'sticker' : 'static',
      'character': character ?? '',
      'content_url': contentUrl
    };

    if(!Utils.checkedTypeEmpty(contentUrl) || !Utils.checkedTypeEmpty(nameController.text) || !Utils.checkedTypeEmpty(tagsController.text)) {
      sl.get<Auth>().showAlertMessage("Vui lòng điền đầy đủ thông tin!", true);
      return;
    }

    Provider.of<Channels>(context, listen: false).uploadSticker(workspaceId, channelId, token, data);
    Navigator.pop(context);
  }

  loadAsset() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final List file = await Utils.openFilePicker([
      XTypeGroup(extensions: ['jpg', 'jpeg', 'png', 'json', 'webp', 'gif', 'tgs'])
    ]);

    Map fileUpload = file[0];
    String type = file[0]['type'];
    if(type == 'tgs') {
      List<int> inflated = gzip.decode(file[0]['file']);
      fileUpload = {
        "name": file[0]['name'].toString().replaceAll('tgs', 'json'),
        "type": 'json',
        "mime_type": 'json',
        "path": '',
        'file': inflated,
      };

      type = 'json';
    }
    isSticker = type == 'json';
    var uploadFile = await Provider.of<Work>(context, listen: false).getUploadData(fileUpload);
    var response = await Provider.of<Work>(context, listen: false).uploadImage(token, 0, uploadFile, type, (v){});

    if (response['success']) {
      setState(() => contentUrl = response['content_url']);
    }
  }

  Widget renderAddSticker(bool isDark, workspaceId) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              showModal(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        contentPadding: EdgeInsets.zero,
                        content: Container(
                          width: 550, height: 500,
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
                                        'Other Sticker',
                                        style: TextStyle(
                                          color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                          fontWeight: FontWeight.w500, fontSize: 18
                                        ),
                                      )
                                    ),
                                    HoverItem(
                                      colorHover: Palette.hoverColorDefault,
                                      child: InkWell(
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            PhosphorIcons.xCircle,
                                          size: 22, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                          ),
                                        ),
                                        onTap: () => Navigator.pop(context),
                                      ),
                                    )
                                  ],
                                )
                              ),
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
                                        otherSticker = data.where((e) => e['name'].toLowerCase().contains(keyword) || e['tags'].toString().contains(keyword) || (e['character'] ?? '').contains(keyword)).toList();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 500,
                                  child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 100,
                                      childAspectRatio: 1,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                    ),
                                    itemCount: otherSticker.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: 80, height: 80,
                                        child: TextButton(
                                          onPressed: () {
                                            this.setState(() {
                                              character = otherSticker[index]['character'];
                                              nameController.text = otherSticker[index]['name'];
                                              tagsController.text = otherSticker[index]['tags'];
                                              contentUrl = otherSticker[index]['content_url'];
                                              isSticker = otherSticker[index]['type'] == 'sticker';
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: StickerFile(data: otherSticker[index], isPreview: true)
                                        )
                                      );
                                    }
                                  )
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  );
                }
              );
            },
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(vertical: 8),
              width: 420,
              decoration: BoxDecoration(
                color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                borderRadius: BorderRadius.circular(4)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.magnifyingGlassThin, size: 16,
                  ),
                  SizedBox(width: 8),
                  Container(
                    child: Text('Find/search sticker')
                  ),
                ],
              )
            ),
          ),
          InkWell(
            onTap: loadAsset,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            child: Utils.checkedTypeEmpty(contentUrl) ? Container(
              height: 390,
              child: isSticker ? LottieBuilder.network(
                contentUrl,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 390, width: 390,
                    decoration: BoxDecoration(
                      color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Icon(
                          PhosphorIcons.prohibit,
                          size: 400.0,
                          color: (isDark ? Palette.defaultTextDark : Palette.defaultTextLight).withOpacity(0.25),
                        ),
                        Center(
                          child: Text(
                            'Không hỗ trợ định dạng này\n    Vui lòng chọn file khác!',
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        )
                      ],
                    )
                  );
                }
              ) : ExtendedImage.network(contentUrl)
            ) : Container(
              height: 390, width: 390,
              decoration: BoxDecoration(
                color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'No Image/Sticker',
                    ),
                    WidgetSpan(
                      child: Container()
                    ),
                    WidgetSpan(
                      child: Icon(
                        PhosphorIcons.imageThin, size: 250,
                      ),
                    ),
                  ]
                ),
                textAlign: TextAlign.center,
              )
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                child: Text('Name sticker: ')
              ),
              SizedBox(width: 10),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                ),
                height: 36, width: 520,
                child: Focus(
                  onFocusChange: (value) {
                    Provider.of<Windows>(context, listen: false).isOtherFocus = value;
                  },
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Name sticker",
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
                  ),
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                child: Text('Tags sticker: ')
              ),
              SizedBox(width: 10),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                ),
                height: 36, width: 520,
                child: Focus(
                  onFocusChange: (value) {
                    Provider.of<Windows>(context, listen: false).isOtherFocus = value;
                  },
                  child: TextFormField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      hintText: "Tags sticker",
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
                  ),
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                child: Text('Character sticker: ')
              ),
              SizedBox(width: 10),
              ContextMenu(
                contextMenu: Container(
                  width: 400, height: 556.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color:isDark ? const Color(0xFF3D3D3D) : const Color(0xFFFFFFFF),
                    border: Border.all(width: 0.3, color:isDark ? Colors.grey[700]! :  Colors.grey)
                  ),
                  child: ListEmojiWidget(
                    workspaceId: workspaceId,
                    onSelect: (ItemEmoji emoji) => setState(() => character = emoji.value),
                    onClose: () => context.contextMenuOverlay.close()
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                  ),
                  height: 36, width: 520,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: character != null ? 0 : 8),
                          child: Text(
                            character ?? 'Choose Emoji',
                            style: TextStyle(
                              fontSize: character != null ? 26 : 14,
                              color: character != null ? null : (isDark ? Palette.calendulaGold : Palette.dayBlue)
                            ),
                          )
                        ),
                      ),
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            PhosphorIcons.xCircle,
                            size: 18, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65),
                          ),
                        ),
                        onTap: () =>setState(() => character = null),
                      ),
                    ],
                  )
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
        ],
      )
    );
  }

  Widget renderGuildView(bool isDark) {
    return CustomSelectionArea(
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: RichTextWidget(
            TextSpan(
              style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
              children: [
                TextSpan(
                  text: 'All users ',
                  style: TextStyle(fontWeight: FontWeight.w500)
                ),
                TextSpan(
                  text: 'can create and send custom artwork using '
                ),
                TextSpan(
                  text: 'PancakeChat',
                  style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontWeight: FontWeight.w500, fontSize: 15),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launch('https://work.pancake.vn');
                  }
                ),
                TextSpan(
                  text: ' open Sticker Platform.\nStickers take many forms from basic images to stunning vector animations.'
                ),
                TextSpan(
                  text: '\nBy default',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: ', Sticker render with 60 FPS. If you want to add a new Sticker, you need to use JSON <LOTTIE> or TGS File. \n'
                ),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '\n*  JSON File:   ',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                    TextSpan(
                      text: 'You need to check the file at this '
                    ),
                    TextSpan(
                      text: 'link. \n',
                      style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        launch('https://lottiefiles.com/tools/json-editor');
                      }
                    )
                  ],
                ),
                WidgetSpan(
                  child: Container(
                    width: 140, height: 140,
                    margin: EdgeInsets.only(left: 30),
                    child: LottieBuilder.network(ducks[0]['content_url'])
                  )
                ),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '\n*  TGS File:     ',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                    TextSpan(
                      text: 'You need to check and convert the file to json at this '
                    ),
                    TextSpan(
                      text: 'link.\n',
                      style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        launch('https://michielp1807.github.io/lottie-editor/#/');
                      }
                    )
                  ],
                ),
                WidgetSpan(
                  child: Container(
                    width: 140, height: 140,
                    margin: EdgeInsets.only(left: 30),
                    child: LottieBuilder.network(emojis[0]['content_url'])
                  )
                ),
                TextSpan(
                  text: '\n\n*  Image File: ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                WidgetSpan(
                  child: Container(
                    width: 54, height: 54,
                    margin: EdgeInsets.only(left: 30),
                    child: ExtendedImage.network('https://statics.pancake.vn/panchat-dev/2022/7/26/68b020c99d254013316f6bae09064593cffc6d95.jpg')
                  )
                ),
                TextSpan(
                  text: '      < Static >'
                ),
                TextSpan(
                  text: '\n\n*  Gif File: ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                WidgetSpan(
                  child: Container(
                    width: 54, height: 54,
                    margin: EdgeInsets.only(left: 54),
                    child: ExtendedImage.network('https://upload.wikimedia.org/wikipedia/commons/b/b9/Youtube_loading_symbol_1_(wobbly).gif')
                  )
                ),
                TextSpan(
                  text: '      < Static >'
                ),
                TextSpan(
                  text: '\n\n*  ',
                  style: TextStyle(fontWeight: FontWeight.w500,),
                ),
                TextSpan(
                  text: 'Once convert successfully, you can upload it to Add Sticker and use it one the current channel.',
                ),
                TextSpan(
                  text: '\n\n*  Sticker name',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: ' explains the sticker.   Ex:   '
                ),
                TextSpan(
                  text: '\'DUCK_HAHA\' , \'DUCK_CRY\', \'PEPE_KISS_AIR\' ...',
                  style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                ),
                TextSpan(
                  text: '\n\n*  Sticker tags',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: ' is used to categorize.   Ex:  ['
                ),
                TextSpan(
                  text: ' SMILE , HAPPY , FUN , ANGRY , ... ',
                  style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                ),
                TextSpan(
                  text: '] .'
                ),
                TextSpan(
                  text: '\n\n*  Sticker emoji',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: ' shows the emoji it represents.   Ex:  ( ❤️ or 🔥 ... )    It will show sticker preview in snippet, and you can search by emoji.',
                ),
                TextSpan(
                  text: '\n\n*  ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: 'YOU MUST ADD FULL FIELDS: NAME, TAGS, EMOJI AND STICKER TO CREATE A NEW STICKER.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Palette.errorColor),
                ),
                TextSpan(
                  text: '\n\n*  ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                TextSpan(
                  text: 'Thank you and good luck!  😉',
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final bool isDark = auth.theme == ThemeType.DARK;

    return Column(
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
              if(isGuideView) InkWell(
                child: Icon(
                  PhosphorIcons.arrowLeft,
                size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                ),
                onTap: () => setState(() => isGuideView = false),
              ),
              Container(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  isGuideView ? 'Guide add sticker' : 'Add sticker',
                  style: TextStyle(
                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                    fontWeight: FontWeight.w500, fontSize: 18
                  ),
                )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if(!isGuideView) HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: InkWell(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.question,
                          size: 22, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                        ),
                      ),
                      onTap: () => setState(() => isGuideView = true),
                    ),
                  ),
                  SizedBox(width: 4),
                  HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: InkWell(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.xCircle,
                          size: 22, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                        ),
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  )
                ],
              )
            ],
          )
        ),
        Expanded(
          child: !isGuideView ? renderAddSticker(isDark, widget.workspaceId) : renderGuildView(isDark)
        ),
        if(!isGuideView) Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor)
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              HoverItem(
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                    overlayColor: MaterialStateProperty.all(Colors.blue[400]),
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(width: 1, color:Colors.blue, style: BorderStyle.solid)
                      ),
                    ),
                  ),
                  onPressed: () {
                    uploadSticker(widget.workspaceId, widget.channelId, auth.token);
                  },
                  child: Text(S.current.save, style: TextStyle(color: Colors.white))
                ),
              ),
              SizedBox(width: 8),
              HoverItem(
                colorHover: Color(0xffFF7875).withOpacity(0.2),
                child: TextButton(
                  style: ButtonStyle(
                    // overlayColor: MaterialStateProperty.all(Colors.red[100]),
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(width: 1, color: Colors.red, style: BorderStyle.solid)
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child:Text(S.current.cancel, style: TextStyle(color: Colors.red))
                ),
              )
            ],
          )
        )
      ],
    );
  }
}