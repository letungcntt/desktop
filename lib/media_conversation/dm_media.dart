import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/providers/providers.dart';

class MediaConversationRender extends StatefulWidget {
  final String id;
  final String type;
  final back;

  const MediaConversationRender({
    Key? key,
    required this.id,
    required this.back,
    required this.type
  }) : super(key: key);

  @override
  State<MediaConversationRender> createState() => _MediaConversationRenderState();
}

class _MediaConversationRenderState extends State<MediaConversationRender> {
  List<MediaConversation> data =[];
  int totalImages = 0;
  int totalFiles = 0;
  String selectedType = 'image_video';
  Map<String, List<MediaConversation>> dataMedia = {
    "image_video": [],
    "file": []
  };

  @override
  void didUpdateWidget(oldWidget){
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.type != widget.type) {
      selectedType =  widget.type;
      resetData();
      getDataType(selectedType);
    }
  }


  @override
  void initState(){
    super.initState();
    Timer.run(() async{
      resetData();
    });
  }

  resetData() async {
      var id  =  widget.id;
      dataMedia = {
        "image_video": [],
        "file": []
      };
      totalImages =  0;
      totalFiles = 0;
      Map d = await ServiceMedia.getNumberOfConversation(widget.id);
      getDataType(selectedType);
      if (widget.id != id) return;
      setState(() {
        totalImages = d["images"];
        totalFiles = d["files"];
      });
  }


  getDataType(String type) async {
    var id  =  widget.id;
    List<MediaConversation> t = (await ServiceMedia.loadConversationMedia(widget.id, 30, getLastCurrentTimeOfType(type), type))["data"];
    if (widget.id != id) return;

    setState(() {
      dataMedia[type] = t;
    });
  }

  int getLastCurrentTimeOfType(String type){
    try {
      return dataMedia[type]!.last.currentTime;

    } catch (e) {
      return DateTime.now().microsecondsSinceEpoch;
    }
  }

  Widget renderMediaType(){
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    if (selectedType == "image_video")
    return Expanded(
      child: GridView.count(
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        crossAxisCount: 3,
        children: (dataMedia[selectedType] ?? []).asMap().entries.map((entry) {
          final e = entry.value;
          final index = entry.key;
          String type = e.media.target!.type;

          return e.media.target!.status == 'downloaded' ? HoverItem(
            colorHover: isDark ? Palette.calendulaGold : Palette.dayBlue,
            child: Container(
              margin: EdgeInsets.all(1.5),
              child: GestureDetector(
                onTap: () {
                  if(type == 'video') {
                    Process.runSync('open', [ '-a', 'QuickTime\ Player.app', e.media.target!.pathInDevice ?? '']);
                    return;
                  }
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      barrierDismissible: true,
                      barrierLabel: '',
                      opaque: false,
                      barrierColor: Colors.black.withOpacity(1.0),
                      pageBuilder: (context, _, __) => Scaffold(
                        backgroundColor: Colors.transparent,
                        body: ImageViewer(listImage: dataMedia[selectedType] ?? [], index: index),
                      )
                    )
                  );
                },
                child: type == 'video'? Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      child: ExtendedImage.network(
                        json.decode(e.media.target!.metaData)['url_thumbnail'] ?? 'https://statics.pancake.vn/panchat-dev/2022/7/13/a09eefc0163c17427affb4b6bf939e337aeb54da.mp4',
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                        shape: BoxShape.rectangle
                      ),
                    ),
                    Center(
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
                ) : ExtendedImage.file(
                  File(e.media.target!.pathInDevice ?? ""),
                  fit: BoxFit.cover,
                  clearMemoryCacheWhenDispose: true,
                ),
              ),
            ),
          ) : Container(
              alignment: Alignment.center,
              height: 56,
              color: Colors.transparent.withOpacity(0.45),
              child: Text(
                'File has deleted', style: TextStyle(
                  fontWeight: FontWeight.w500, color: Palette.defaultTextDark, fontSize: 12
                ),
              )
            );
        }).toList()
      ),
    );

    return Expanded(
      child: ListView.builder(
        controller: ScrollController(),
        itemCount: dataMedia["file"]?.length,
        itemBuilder: (BuildContext c, int i){
          MediaConversation e = dataMedia["file"]![i];
          return Stack(
            children: [
              HoverItem(
                colorHover: Palette.hoverColorDefault,
                isRound: true, radius: 4.0,
                child: InkWell(
                  onTap: () {
                    try {
                      if (e.media.target!.type.toString().toLowerCase() == 'mp4' || e.media.target!.type.toString().toLowerCase() == 'mov') {
                        Process.runSync('open', [e.media.target!.pathInDevice ?? ""]);
                      } else {
                        Process.runSync('open', ['-R', e.media.target!.pathInDevice ?? ""]);
                      }
                    } catch (e) {}
                  },
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
                          child: Icon(
                            PhosphorIcons.files,
                            size: 22.0,
                          ),
                        ),
                        Container(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.media.target!.name, style: TextStyle(overflow: TextOverflow.ellipsis, color: isDark ?  Color(0xFFDBDBDB) : Color(0xFF262626))),
                              Container(height: 10,),
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    child: Text(".${e.media.target!.type}", style: TextStyle( fontSize: 12,color: Color(0xFF828282))),
                                  ),
                                  Text("${e.media.target!.size} bytes", style: TextStyle( fontSize: 12, color: Color(0xFF828282))),
                                ],
                              )
                            ]
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              if(e.media.target!.status ==  'not download') Positioned(
                child: Container(
                  alignment: Alignment.center,
                  height: 56,
                  color: Colors.transparent.withOpacity(0.45),
                  child: Text(
                    'File has deleted', style: TextStyle(
                      fontWeight: FontWeight.w500, color: Palette.defaultTextDark
                    ),
                  )
                ),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      width: 326,
      color: isDark ? Color(0xFF2e2e2e) : Color(0xFFffffff),
      margin: EdgeInsets.symmetric(horizontal:2),
      child: Column(
        children: [
          Container(
            height: 56, color: Palette.backgroundTheardDark,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    child: InkWell(
                      onTap: () {
                        widget.back();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Icon(PhosphorIcons.arrowLeft, size: 20, color: Palette.defaultTextDark),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Text(
                      selectedType != 'image_video' ? "Files" : 'Images/Videos',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17, color: Palette.defaultTextDark
                      )
                    ),
                  ),
                  SizedBox(width: 50,)
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(child: renderMediaType())
        ],
      ),
    );
  }
}


//Show Image from FileBackup
class ImageViewer extends StatefulWidget {
  final listImage;
  final index;
  final bool isChannel;

  const ImageViewer({
    Key? key,
    required this.listImage,
    required this.index,
    this.isChannel = false
  }) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  var imageIndex;

  @override
  void initState() {
    imageIndex = widget.index;
    RawKeyboard.instance.addListener(handleEvent);
    super.initState();
  }

  handleEvent(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)){
      if (imageIndex < widget.listImage.length - 1) {
        setState(() { imageIndex += 1; });

      }
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)){
      if (imageIndex > 0) {
        setState(() { imageIndex -= 1; });
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    // _controller!.dispose();
    RawKeyboard.instance.removeListener(handleEvent);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final data = widget.listImage[imageIndex];
    return Container(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Center(
                child: widget.isChannel ? ExtendedImage.network(
                  data['content_url'],
                  clearMemoryCacheWhenDispose: true,
                  enableMemoryCache: true,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: (state) {
                    return GestureConfig(
                      minScale: 0.9,
                      animationMinScale: 0.7,
                      maxScale: 3.0,
                      animationMaxScale: 3.5,
                      speed: 1.0,
                      inertialSpeed: 100.0,
                      initialScale: 1.0,
                      inPageView: true,
                      initialAlignment: InitialAlignment.center,
                    );
                  }
                ) : ExtendedImage.file(
                  File(data.media.target!.pathInDevice ?? ""),
                  clearMemoryCacheWhenDispose: true,
                  enableMemoryCache: true,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: (state) {
                    return GestureConfig(
                      minScale: 0.9,
                      animationMinScale: 0.7,
                      maxScale: 3.0,
                      animationMaxScale: 3.5,
                      speed: 1.0,
                      inertialSpeed: 100.0,
                      initialScale: 1.0,
                      inPageView: true,
                      initialAlignment: InitialAlignment.center,
                    );
                  }
                )
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                top: 0,
                child: Container(
                  color: Color(0xFF000000).withOpacity(0.25),
                  height: 50,
                  alignment: Alignment.centerRight,
                  width: constraints.maxWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        child: HoverItem(
                          colorHover: Colors.grey.withOpacity(0.4),
                          child: InkWell(
                            focusNode: FocusNode(skipTraversal: true),
                            highlightColor: Color(0xff27AE60),
                            onTap: () {
                              final auth = Provider.of<Auth>(context, listen: false);
                              if (widget.isChannel) {
                                jumpToMessage(data['message_id'], data['channel_id'], data['workspace_id']).then((e) => Navigator.pop(context));
                              } else {
                                Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump({
                                  'id': data.messageId,
                                  'conversation_id': data.conversationId,
                                  'inserted_at': data.insertedAt,
                                  'current_time': data.currentTime
                                }, auth.token, auth.userId);
                                Navigator.pop(context);
                              }
                            },
                            child: Icon(
                              PhosphorIcons.arrowElbowDownRight,
                              size: 22.0, color: Color(0xFFFFFFFF)
                            )
                          ),
                        ),
                      ),
                      if(widget.isChannel) Container(
                        height: 50,
                        width: 50,
                        child: HoverItem(
                          colorHover: Colors.grey.withOpacity(0.4),
                          child: InkWell(
                            focusNode: FocusNode(skipTraversal: true),
                            highlightColor: Color(0xff27AE60),
                            onTap: () => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": data['content_url'], "name": data['file_name'],  "key_encrypt": ''}),
                            child: Icon(Icons.file_download, size: 20, color: Color(0xFFFFFFFF))
                          ),
                        ),
                      ),
                      if(!widget.isChannel) Container(
                        height: 50,
                        width: 50,
                        child: HoverItem(
                          colorHover: Colors.grey.withOpacity(0.4),
                          child: InkWell(
                            focusNode: FocusNode(skipTraversal: true),
                            highlightColor: Color(0xff27AE60),
                            onTap: () {
                              try {
                                Process.runSync('open', ['-R', data.media.target!.pathInDevice ?? ""]);
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Icon(
                              PhosphorIcons.folderOpen,
                              size: 22.0, color: Color(0xFFFFFFFF)
                            )
                          ),
                        ),
                      ),
                      Container(
                        height: 50,
                        width: 50,
                        child: HoverItem(
                          colorHover: Colors.grey.withOpacity(0.4),
                          child: InkWell(
                            focusNode: FocusNode(skipTraversal: true),
                            highlightColor: Color(0xff27AE60),
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close_rounded, size: 24, color: Colors.white)
                          ),
                        )
                      )
                    ]
                  )
                )
              ),
            ],
          );
        }
      ),
    );
  }
}