import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_highlight_view.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';

import '../providers/providers.dart';

class FileItems extends StatefulWidget{
  final removeFile;
  final onChangedTypeFile;
  final files;
  final Function? setShareMessage;

  const FileItems({Key? key, @required files, this.removeFile, this.onChangedTypeFile, this.setShareMessage})
  : files = files,
  super(key: key);

  @override
  State<FileItems> createState() => _FileItemsState();
}

class _FileItemsState extends State<FileItems> {
  bool isPreview = false;

@override
  initState() {
    super.initState();
    RawKeyboard.instance.addListener(handleEvent);
  }

  KeyEventResult handleEvent(RawKeyEvent event) {
    if(event is RawKeyDownEvent && event.isKeyPressed(LogicalKeyboardKey.escape)) {
      if (widget.setShareMessage != null && !isPreview) {
        widget.setShareMessage!(false);
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleEvent);
    super.dispose();
  }

  parseTime(dynamic time) {
    var messageLastTime = "";
    if (time != null) {
      DateTime dateTime = DateTime.parse(time);
      final messageTime = DateFormat('kk:mm').format(DateTime.parse(time).add(Duration(hours: 7)));
      final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, "en");

      messageLastTime = "$dayTime at $messageTime";
      return messageLastTime;
    }
  }

  renderTextMention(att, isDark) {
    return att["data"].map((e){
      if (e["type"] == "text" && Utils.checkedTypeEmpty(e["value"])) return e["value"];
      if (e["name"] == "all" || e["type"] == "all") return "@all ";

      if (e["type"] == "issue") {
        return "";
      } else {
        return Utils.checkedTypeEmpty(e["name"]) ? "@${e["name"]} " : "";
      }
    }).toList().join("");
  }

  onShowFile(file, isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 820, height: 1000,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor)
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          file['name'],
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[800]
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              isPreview = false;
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              PhosphorIcons.xCircle, size: 20,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          )
                        ],
                      )
                    ],
                  )
                ),
                Expanded(
                  child: SfPdfViewer.memory(
                    file['file'],
                    initialZoomLevel: 1.35,
                    onZoomLevelChanged: (PdfZoomDetails zoomDetails) { },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    ).then((e) => isPreview = false);
  }

  onEditFile(file, index, isDark) {
    String type = file['mime_type'];
    TextEditingController controller = TextEditingController(text: file['name'].toString().replaceAll(RegExp(".$type"), ''));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String language = Utils.getLanguageFile(type);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
              insetPadding: const EdgeInsets.all(0),
              contentPadding: const EdgeInsets.all(0),
              content: Container(
                width: 750,
                height: 710,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.current.changeFile,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              isPreview = false;
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              PhosphorIcons.xCircle,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).dividerColor),
                          top: BorderSide(color: Theme.of(context).dividerColor)
                        )
                      ),
                      child: Row(
                        children: [
                          Text(S.current.nameFile),
                          SizedBox(width: 8),
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              color: isDark ? Palette.backgroundTheardDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isDark ? Border() : Border.all(
                                color: Color(0xffA6A6A6), width: 0.5
                              ),
                            ),
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                constraints: BoxConstraints(maxHeight: 38),
                                contentPadding: EdgeInsets.all(8),
                                hintStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14, fontWeight: FontWeight.w300),
                                border: InputBorder.none,
                                suffix:  Container(
                                  width: 50,
                                  child: DropdownButtonFormField<String>(
                                    // icon: const Visibility(visible: false, child: Icon(Icons.arrow_downward)),
                                    icon: Icon(PhosphorIcons.caretDown, size: 14,),
                                    decoration: InputDecoration(border: InputBorder.none),
                                    value: type,
                                    elevation: 16,
                                    focusColor: Colors.transparent,
                                    items: <String>['txt', 'ex', 'js', 'ts', 'dart', 'json', 'sql'].map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text('.$value'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        type = value!;
                                      });
                                    }
                                  ),
                                ),
                              ),
                            )
                          ),
                        ]
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16, top: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        padding: EdgeInsets.all(8),
                        child: Text(S.current.previewText, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[800]),)
                      ),
                    ),
                    SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB)
                        ),
                        alignment: Alignment.topLeft,
                        height: 500,
                        width: double.infinity,
                        child: CustomHighlightView(
                          file['preview'],
                          language: language,
                          backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
                          theme: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                              .platformBrightness == Brightness.dark
                              ? atomOneLightTheme
                              : atomOneDarkTheme,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: GoogleFonts.robotoMono(color: isDark ? Colors.white70 : Colors.grey[800], fontSize: 14),
                          isIssue: false,
                        )
                      ),
                    ),
                    Container(
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
                                widget.onChangedTypeFile(index, controller.text, type);
                                Navigator.pop(context);
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
                ),
              )
            );
          }
        );
      }
    ).then((e) => isPreview = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;
    final shareMessage = widget.files.where((ele) => ele["mime_type"] == "share").toList();
    final indexShareMessage = widget.files.indexWhere((ele) => ele["mime_type"] == "share");
    final filesMessage = widget.files.where((ele) => ele["mime_type"] != "share").toList();

    return Column(
      children: [
        if (shareMessage.length > 0) Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5)
            )
          ),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(0xffd0d0d0),
                      width: 4.0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrowshape_turn_up_left_fill, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17),
                          SizedBox(width: 5,),
                          Text(S.current.shareMessage, style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      child: Row(
                        children: [
                          CachedAvatar(
                            shareMessage[0]["data"]["avatarUrl"],
                            height: 20, width: 20,
                            isRound: true,
                            name: shareMessage[0]["data"]["fullName"],
                            isAvatar: true,
                            fontSize: 13,
                          ),
                          SizedBox(width: 5),
                          Text(shareMessage[0]["data"]["fullName"])
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    Utils.checkedTypeEmpty(shareMessage[0]["data"]["isUnsent"])
                      ? Container(
                        height: 19,
                        child: Text(
                          S.current.thisMessageDeleted,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(isDark ? 0xffe8e8e8 : 0xff898989)
                          ),
                        )
                      )
                      : (shareMessage[0]["data"]["message"] != "" && shareMessage[0]["data"]["message"] != null)
                        ? Container(
                          padding: EdgeInsets.only(left: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shareMessage[0]["data"]["message"]),
                              shareMessage[0]["data"]["attachments"] != null && shareMessage[0]["data"]["attachments"].length > 0
                                ? Text("Attachments")
                                // ? AttachmentCardDesktop(attachments: shareMessage[0]["data"]["attachments"], isChannel: shareMessage[0]["data"]["isChannel"], id: shareMessage[0]["data"]["id"], isChildMessage: false, isThread: shareMessage[0]["data"]["isThread"], lastEditedAt: parseTime(shareMessage[0]["data"]["lastEditedAt"]))
                                : Container()
                            ],
                          ),
                        )
                        : shareMessage[0]["data"]["attachments"] != null && shareMessage[0]["data"]["attachments"].length > 0
                          ? Container(
                            padding: EdgeInsets.only(left: 3),
                            child: Text(
                              Utils.checkedTypeEmpty(shareMessage[0]["data"]["message"])
                                ? shareMessage[0]["data"]["message"]
                                : shareMessage[0]["data"]["attachments"][0]["type"] == "mention"
                                    ? renderTextMention(shareMessage[0]["data"]["attachments"][0], isDark)
                                    : shareMessage[0]["data"]["attachments"][0]["mime_type"] == "image"
                                        ? shareMessage[0]["data"]["attachments"][0]["name"]
                                        : "Parent message",
                            )
                          )
                          : Container(),
                  ],
                )
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  width: 15,
                  height: 15,
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                      backgroundColor: MaterialStateProperty.all(Color(0xFF282c2e)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)))
                    ),
                    onPressed: () {
                      widget.removeFile(indexShareMessage);
                    },
                    child: Icon(Icons.close, size: 10, color: Colors.grey[200])
                  ),
                )
              )
            ],
          ),
        ),
        if (filesMessage.length > 0) Container(
          height: 90,
          padding: EdgeInsets.only(left: 10, right: 10, bottom: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filesMessage.length,
            itemBuilder: (context, index) {
              Map file =  filesMessage[index];
              var tag = Utils.getRandomString(10);
              switch (file["type"]) {
                case "image":
                  return  InkWell(
                    onTap: () {
                      isPreview = true;
                      Navigator.push(context, PageRouteBuilder(
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.7),
                        opaque: false,
                        pageBuilder: (context, a,b){
                        return Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Hero(
                              tag: tag,
                              child: Container(
                                child: file["file"] == null
                                  ? Image.network(file["content_url"], fit: BoxFit.cover,)
                                  : Image.memory(
                                      file["file"],
                                      fit: BoxFit.cover,
                                    )
                              ),
                            ),
                          ),
                        );
                      })).then((value) => isPreview = false);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(6),
                            child: Hero(
                              tag: tag,
                              child: Container(
                                child: file["file"] == null
                                  ? Image.network(file["content_url"], height: 100, width: 100,)
                                  : Image.memory(
                                      file["file"],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    )
                              ),
                            )
                          ),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              width: 15,
                              height: 15,
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                                  backgroundColor: MaterialStateProperty.all(Color(0xFF282c2e)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)))
                                ),
                                onPressed: () {
                                  widget.removeFile(shareMessage.length > 0 ? index + 1 : index);
                                },
                                child: Icon(Icons.close, size: 10, color: Colors.grey[200])
                              ),
                            )
                          )
                        ],
                      ),
                    ),
                  );
                default:
                  int indexChecking = ['ex','js', 'ts', 'dart', 'json', 'txt', 'sql'].indexWhere((e) => e == file['mime_type']);
                  bool isEdit = widget.onChangedTypeFile != null && indexChecking != -1 && file['preview'] != null;

                  return Container(
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    width: 90,
                    child: Stack(children: [
                      ListAction(
                        action: isEdit
                          ? 'Click to edit file'
                          : file['mime_type'] == 'pdf' ? 'Show File' : '',
                        isDark: isDark,
                        colorHover: Colors.transparent,
                        arrowTipDistance: 2.5,
                        tooltipDirection: TooltipDirection.up,
                        child: InkWell(
                          onTap:  () {
                            isPreview = true;
                            if(isEdit) {
                              onEditFile(file, index, isDark);
                            } else if(file['mime_type'] == 'pdf') {
                               onShowFile(file, isDark);
                            }
                          },
                          mouseCursor: isEdit || file['mime_type'] == 'pdf' ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                child: Icon(CupertinoIcons.doc_fill)
                              ),
                              SizedBox(height: 6),
                              Center(
                                child: Text(
                                  (file["mime_type"] ?? "").toString().toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          width: 16,
                          height: 16,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                              backgroundColor: MaterialStateProperty.all(Color(0xFF282c2e)),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)))
                            ),
                            onPressed: () {
                              isPreview = false;
                              widget.removeFile(shareMessage.length > 0 ? index + 1 : index);
                            },
                            child: Icon(Icons.close, size: 10, color: Colors.grey[200])
                          ),
                        )
                      )
                    ]),
                  );
              }
            }
          )
        ),
      ],
    );
  }
}