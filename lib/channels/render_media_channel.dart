import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/media_conversation/dm_media.dart';

import '../providers/providers.dart';

class RenderMediaChannel extends StatefulWidget {
  final List data;
  final type;
  final bool isPreview;
  final Function? onChanged;
  final int count;

  RenderMediaChannel({
    Key? key,
    required this.data,
    required this.count,
    this.type,
    this.isPreview = true,
    this.onChanged
  }) : super(key: key);

  @override
  _RenderMediaChannelState createState() => _RenderMediaChannelState();
}

class _RenderMediaChannelState extends State<RenderMediaChannel> {
  ScrollController controller = ScrollController();
  List data = [];
  List loadMoreFile = [];
  bool isBlock = false;
  @override
  void initState() {
    super.initState();
    data = widget.data;
    controller.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(!listEquals(widget.data, oldWidget.data)) {
      data = widget.data + loadMoreFile;
    }

    if(widget.type != oldWidget.type) {
      data = widget.data;
      loadMoreFile = [];
      isBlock = false;
    }
  }

  @override
  void dispose() {
    super.dispose();

    controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (widget.isPreview) return;
    if (controller.position.atEdge) {
      bool isBottom = controller.position.pixels != 0;
      if (isBottom && !isBlock) {
        onHandleLoadMore();
      }
    }
  }

  onHandleLoadMore() {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      loadMoreFilesChannel(auth.token, currentWorkspace['id'], currentChannel['id'], data[data.length -1]['id']).then(
        (value) => setState(() {
          data += value;
          loadMoreFile += value;
          isBlock = value.length == 0;
        }));
  }

  jumpToMessage(messageId, channelId, workspaceId) async{
    final token = Provider.of<Auth>(context, listen: false).token;
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/get_info_message?token=$token';

    try {
      var response = await Dio().post(url, data: {'channel_id': channelId, 'workpsace_id': workspaceId, 'message_id': messageId});
      var resData = response.data;
      if (resData["success"] == true) {
        final message = {
          ...resData['message'],
          'workspace_id': workspaceId,
          'channel_id': channelId
        };

        if (!Utils.checkedTypeEmpty(message["channel_thread_id"])){
          await Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(message, context);
        } else {
          int workspaceId = message["workspace_id"];
          int channelId = message["channel_id"];
          final url =  Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/thread?message_id=${message["channel_thread_id"]}&token=$token';
          final response = await Dio().get(url);
          Map parentMessage  = response.data["parent_message"] ?? {};
          Map parentMessageData = {
            "id": parentMessage["id"],
            "channelId": channelId,
            "workspaceId": workspaceId,
            "userId": parentMessage["user_id"],
            "fullName": parentMessage["fullName"],
            "avatarUrl": parentMessage["avatarUrl"],
            "isChannel": true,
            "attachments": parentMessage["attachments"],
            "insertedAt": message["inserted_at"],
            "message": parentMessage["message"],
            "current_time": parentMessage["current_time"],
            "idMessageToJump": message["id"]
          };
          Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessageData);
          await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessageData, token);
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<List> loadMoreFilesChannel(token, workspaceId, channelId, id) async{
    final String url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/load_more_files_channel?token=$token';
    final type = widget.type;

    try {
      final response = await Dio().post(url, data: {
        'id': id,
        'type': type
      });
      final responseData = response.data;
      if (responseData["success"]) {
        return responseData['files'];
      }
    } catch (e) {
      print(e.toString());
    }

    return [];
  }

  int getCountInView(double width) {
    int count = 3;

    if(width < 361) {
      count = 3;
    } else if (width > 361 && width < 444.0) {
      count = 4;
    } else if (width > 444.0 && width < 528.0) {
      count = 5;
    } else if (width > 528 && width < 612.0) {
      count = 6;
    } else {
      count = 7;
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final type = widget.type;
    final double scrollAreaHeight = MediaQuery.of(context).size.height - 208;
    return LayoutBuilder(
      builder: (context, constraints) {
        int itemCountInRow = getCountInView(constraints.maxWidth);
        int itemCountInColumn = (data.length/itemCountInRow).round();
        bool isFill = scrollAreaHeight < itemCountInColumn*84;

        return Stack(
          children: [
            (!widget.isPreview && type == 'file') ? Container(  
              height: scrollAreaHeight,
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: data.map<Widget>((e) {
                    bool isVideo = false;
                    PhosphorIconData icon = PhosphorIcons.files;

                    switch (e['type']) {
                      case 'mp4':
                      case 'mov':
                      case 'flv':
                      case 'avi':
                      case 'video':
                        isVideo = true;
                        icon = PhosphorIcons.fileVideo;
                        break;
                      case 'mp3':
                      case 'm4a':
                      case 'record':
                        isVideo = true;
                        icon = PhosphorIcons.fileAudio;
                        break;
                      case 'doc':
                      case 'docx':
                        icon = PhosphorIcons.fileDoc;
                        break;
                      case 'xlsx':
                      case 'xls':
                        icon = PhosphorIcons.fileXls;
                        break;
                      case 'ppt':
                        icon = PhosphorIcons.filePpt;
                        break;
                      case 'js':
                      case 'ts':
                      case 'dart':
                      case 'ex':
                      case 'c':
                      case 'cc':
                      case 'sql':
                      case 'json':
                        icon = PhosphorIcons.fileCode;
                        break;
                      case 'pdf':
                        icon = PhosphorIcons.filePdf;
                        break;
                      case 'zip':
                        icon = PhosphorIcons.fileZip;
                        break;
                      case 'txt':
                      case 'text':
                        icon = PhosphorIcons.fileText;
                        break;
                      default:
                    }

                    return ContextMenuRegion(
                      contextMenu: GenericContextMenu(
                        buttonConfigs: [
                          ContextMenuButtonConfig(
                            "Download file",
                            onPressed: () => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": e['content_url'], "name": e['file_name'],  "key_encrypt": ''}),
                          ),
                          ContextMenuButtonConfig(
                            "Jump to message",
                            onPressed: () {
                              jumpToMessage(e['message_id'], e['channel_id'], e['workspace_id']);
                            }
                          )
                        ],
                      ),
                      child: HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        isRound: true, radius: 4.0,
                        child: InkWell(
                          onTap: isVideo ? () {
                            Utils.isWinOrLinux()
                              ? Process.runSync('start', ['/d', '%ProgramFiles(x86)%\Windows Media Player', 'wmplayer.exe', e["content_url"]], runInShell: true)
                              : Process.runSync('open', [ '-a', 'QuickTime\ Player.app', e['content_url']]);
                          } : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xFF3d3d3d) : Color(0xFFbfbfbf),
                                    borderRadius: BorderRadius.all(Radius.circular(4))
                                  ),
                                  child: Icon(icon, size: 24.0),
                                ),
                                Container(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e['file_name'].toString(), style: TextStyle(overflow: TextOverflow.ellipsis, color: isDark ?  Color(0xFFDBDBDB) : Color(0xFF262626))),
                                      Container(height: 10,),
                                      Container(
                                        width: 60,
                                        child: Text(".${e['type'].toString().toUpperCase()}", style: TextStyle( fontSize: 12,color: Color(0xFF828282))),
                                      )
                                    ]
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ) : Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                children: [
                  widget.isPreview ? Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                            ),
                            children: [
                              WidgetSpan(
                                child: Container(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    type == 'file' ? PhosphorIcons.filesThin : PhosphorIcons.imageSquareThin,
                                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 22
                                  ),
                                )
                              ),
                              TextSpan(
                                text: type == 'file' ? 'Files' :'Photo/Video'
                              ),
                              TextSpan(
                                text: ' (${widget.count})',
                                style: TextStyle(fontSize: 12)
                              ),
                            ]
                          )
                        ),
                        HoverItem(
                          colorHover: data.length > 0 ? Palette.hoverColorDefault : null, radius: 4.0, isRound: true,
                          child: InkWell(
                            onTap: data.length == 0 ? null : () {

                              if(widget.onChanged != null) widget.onChanged!();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(
                                'View all',
                                style: TextStyle(fontSize: 12.5, color: Color(0xff838383)),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ) : Container(),
                  data.length == 0 ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 44, vertical: 22),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
                      borderRadius: BorderRadius.all(Radius.circular(2))
                    ),
                    child: Text(
                      'No file is shared in this channel',
                      style: TextStyle(
                        color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                        fontSize: 13.5
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ) : Container(
                    height: widget.isPreview ? (data.length >= 5 ? 168 : (data.length >= 1 ? 84 : 0)) : scrollAreaHeight,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: data.map((e) {
                          int index = data.indexWhere((ele) => ele == e);
                          bool isVideo= false;
                          PhosphorIconData icon = PhosphorIcons.files;

                          switch (e['type']) {
                            case 'mp4':
                            case 'mov':
                            case 'flv':
                            case 'avi':
                            case 'video':
                              isVideo = true;
                              icon = PhosphorIcons.fileVideo;
                              break;
                            case 'mp3':
                            case 'm4a':
                            case 'record':
                              isVideo = true;
                              icon = PhosphorIcons.fileAudio;
                              break;
                            case 'doc':
                            case 'docx':
                              icon = PhosphorIcons.fileDoc;
                              break;
                            case 'xlsx':
                            case 'xls':
                              icon = PhosphorIcons.fileXls;
                              break;
                            case 'ppt':
                              icon = PhosphorIcons.filePpt;
                              break;
                            case 'js':
                            case 'ts':
                            case 'dart':
                            case 'ex':
                            case 'c':
                            case 'cc':
                            case 'sql':
                            case 'json':
                              icon = PhosphorIcons.fileCode;
                              break;
                            case 'pdf':
                              icon = PhosphorIcons.filePdf;
                              break;
                            case 'zip':
                              icon = PhosphorIcons.fileZip;
                              break;
                            case 'txt':
                            case 'text':
                              icon = PhosphorIcons.fileText;
                              break;
                            default:
                          }

                          return ContextMenuRegion(
                            contextMenu: GenericContextMenu(
                              buttonConfigs: [
                                ContextMenuButtonConfig(
                                  "Download file",
                                  onPressed: () => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": e['content_url'], "name": e['file_name'],  "key_encrypt": ''}),
                                ),
                                ContextMenuButtonConfig(
                                  "Jump to message",
                                  onPressed: () {
                                    jumpToMessage(e['message_id'], e['channel_id'], e['workspace_id']);
                                  }
                                )
                              ],
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                              width: 84, height: 84,
                              child: HoverItem(
                                colorHover: isDark ? Palette.calendulaGold : Palette.dayBlue,
                                isRound: type != 'image', radius: 4.0,
                                child: (type == 'image' ? InkWell(
                                  onTap: () {
                                    if(e['type'] != "image") {
                                      Utils.isWinOrLinux()
                                        ? Process.runSync('start', ['/d', '%ProgramFiles(x86)%\Windows Media Player', 'wmplayer.exe', e["content_url"]], runInShell: true)
                                        : Process.runSync('open', [ '-a', 'QuickTime\ Player.app', e['content_url']]);
                                    } else {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          barrierDismissible: true,
                                          barrierLabel: '',
                                          opaque: false,
                                          barrierColor: Colors.black.withOpacity(1.0),
                                          pageBuilder: (context, _, __) => Scaffold(
                                            backgroundColor: Colors.transparent,
                                            body: ImageViewer(listImage: data, index: index, isChannel: true),
                                          )
                                        )
                                      );
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.all(1.75),
                                        width: 84, height: 84,
                                        child: ExtendedImage.network(
                                          e['type'] == 'image' ? e['content_url'] : e['path_thumbnail'] ?? 'https://statics.pancake.vn/panchat-dev/2022/7/13/a09eefc0163c17427affb4b6bf939e337aeb54da.mp4',
                                          fit: BoxFit.cover,
                                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          shape: BoxShape.rectangle
                                        ),
                                      ),
                                      if(e['type'] != 'image') Center(
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                          child: Center(child: Icon(CupertinoIcons.play_fill, color: Colors.white, size: 22))
                                        ),
                                      ),
                                    ],
                                  ),
                                ) : InkWell(
                                  onTap: !isVideo ? null : () {
                                    Utils.isWinOrLinux()
                                      ? Process.runSync('start', ['/d', '%ProgramFiles(x86)%\Windows Media Player', 'wmplayer.exe', e["content_url"]], runInShell: true)
                                      : Process.runSync('open', [ '-a', 'QuickTime\ Player.app', e['content_url']]);
                                  },
                                  child: Container(
                                    width: 75, height: 75,
                                    margin: EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? Color(0xFF3d3d3d) : Color(0xFFbfbfbf),
                                      borderRadius: BorderRadius.all(Radius.circular(4))
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 24.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          e['type'].toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w400, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              ),
            ),
            if(!widget.isPreview && type == 'image') AnimatedPositioned(
              curve: Curves.easeIn,
              duration: Duration(milliseconds: 300),
              bottom: !isFill && !isBlock ? 10.0 : -50.0, left: constraints.maxWidth/2 - 50,
              child: TextButton.icon(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey[200]),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                  padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.fromLTRB(10, 8, 16, 8))
                ),
                onPressed: onHandleLoadMore,
                icon: Icon(CupertinoIcons.arrow_down, size: 13, color: Colors.black),
                label: Text('Load more ...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),),
              )
            )
          ],
        );
      }
    );
  }
}