import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:better_selection/better_selection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/file_items.dart';
import 'package:workcake/flutter_mention/action_input.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/models/models.dart';

import 'message_item/chat_item_macOS.dart';

class ThreadItemMacos extends StatefulWidget {
  ThreadItemMacos({
    Key? key,
    @required this.parentMessage
  }) : super(key: key);

  final parentMessage;

  @override
  _ThreadItemMacosState createState() => _ThreadItemMacosState();
}

class _ThreadItemMacosState extends State<ThreadItemMacos> {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  double heightCommand = 0.0;
  List suggestCommands = [];
  ScrollController? controller;
  List images = [];
  List fileItems = [];
  var maxLine;
  var newLine = 1;
  bool isSelectAll = false;
  bool islastEdited = false;
  bool isUpdate = false;
  var messageUpdate;
  var snippet;
  List snippetList = [];
  bool isCodeBlock = false;
  List listBlockCode = [];
  bool threadFetching = false;
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 0;
  bool tooltipNotify = false;
  bool onHighlight = false;

  getUser(userId) {
    final members = Provider.of<Workspaces>(context, listen: true).members;
    final index = members.indexWhere((e) => e["id"] == userId);

    if (index != -1) {
      final user = members[index];

      return user;
    } else {
      return {
        "avatar_url": "",
        "full_name": ""
      };
    }
  }

  getChannel(channelId) {
    List channels = Provider.of<Channels>(context, listen: false).data;
    final index = channels.indexWhere((e) => e["id"] == channelId);

    if (index != -1) {
      return channels[index];
    } else {
      return null;
    }
  }

  sendThreadMessage(token, workspaceId, channelId) {
    final channelThreadId = widget.parentMessage["id"];
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText);
    List list = fileItems;

    var dataMessage  = {
      "channel_thread_id": channelThreadId,
      "channel_id": channelId,
      "workspace_id": workspaceId,
      "key": Utils.getRandomString(20),
      "message": result["success"] || isCodeBlock ? "" : result["data"],
      "attachments": [] + (result["success"] ? [{"type": "mention", "data": result["data"] }] : []) + (isCodeBlock ? [{"type": "block_code", "data": [{"type": "block_code", "value": key.currentState!.controller!.text}]}] : []),
      "isDesktop": true,
      "fromThread": true
    };

    setState(() { fileItems = []; });

    if (Utils.checkedTypeEmpty(key.currentState!.controller!.text.trim()) || list.isNotEmpty || dataMessage["attachments"].length > 0) {
      Provider.of<Messages>(context, listen: false).sendMessageWithImage(list, dataMessage, token);
    }
    key.currentState!.controller!.clear();
  }

  handleMessage() {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final channelId = widget.parentMessage["channel_id"];

    if (!isUpdate) {
      sendThreadMessage(auth.token, currentWorkspace["id"], channelId);
      Provider.of<Workspaces>(context, listen: false).updateUnreadMention(currentWorkspace["id"], widget.parentMessage["id"], false);
      handleCodeBlock(false);
    }  else {
      _sendUpdateMessage(auth, currentWorkspace, channelId);
    }

    setState(() {
      newLine = 1;
    });

    Timer(const Duration(microseconds: 100), () => {
      key.currentState!.controller!.clear()
    });
  }

  _sendUpdateMessage(auth, currentWorkspace, channelId) async{
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText);
    var files = fileItems;
    setState(() {
      fileItems = [];
    });
    var message  = {
      "channel_thread_id": widget.parentMessage["id"] == messageUpdate["id"] ? null : widget.parentMessage["id"],
      "key": Utils.getRandomString(20),
      "message_id": messageUpdate["id"],
      "message": result["success"] || isCodeBlock ? "" : result["data"],
      "attachments": [] + (result["success"] ? [{"type": "mention", "data": result["data"] }] : []) + (isCodeBlock ? [{"type": "block_code", "data": [{"type": "block_code", "value": key.currentState!.controller!.text}]}] : []),
      "channel_id":  channelId,
      "workspace_id": currentWorkspace["id"],
      "user_id": messageUpdate["userId"],
      "is_system_message": false
    };

    Provider.of<Messages>(context, listen: false).newUpdateChannelMessage(auth.token, message, files);
    key.currentState!.controller!.clear();

    setUpdateMessage(null, false);
  }

  handleCodeBlock(bool value) {
    setState(() {
      isCodeBlock = value;
    });
  }

  removeFile(index) {
    List list = fileItems;
    list.removeAt(index);
    setState(() {
      fileItems = list;
    });
  }

  setUpdateMessage(data, bool value) {
    setState(() {
      messageUpdate = data;
      isUpdate = value;
    });
  }
  getDataMentions(channelId, auth) {
    // get data ChannelMember with channelId
    final channelMembers = Provider.of<Channels>(context, listen: false).getDataMember(channelId);
    List<Map<String, dynamic>> suggestionMentions = [];
    for (var i = 0 ; i < channelMembers.length; i++){
      Map<String, dynamic> item = {
        'id': channelMembers[i]["id"],
        'type': 'user',
        'display': Utils.getUserNickName(channelMembers[i]["id"]) ?? channelMembers[i]["full_name"],
        'full_name': Utils.checkedTypeEmpty(Utils.getUserNickName(channelMembers[i]["id"]))
            ? "${Utils.getUserNickName(channelMembers[i]["id"])} • ${channelMembers[i]["full_name"]}"
            : channelMembers[i]["full_name"],
        'photo': channelMembers[i]["avatar_url"]
      };
      if (auth.userId != channelMembers[i]["id"]) suggestionMentions += [item];
    }
    
    return suggestionMentions;
  }

  getSuggestionIssue() {
    List preloadIssues = Provider.of<Workspaces>(context, listen: false).preloadIssues;
    List dataList = [];

    for (var i = 0 ; i < preloadIssues.length; i++){
      Map<String, dynamic> item = {
        'id': "${preloadIssues[i]["id"]}-${preloadIssues[i]["workspace_id"]}-${preloadIssues[i]["channel_id"]}",
        'type': 'issue',
        'display': preloadIssues[i]["unique_id"].toString(),
        'title': preloadIssues[i]["title"],
        'channel_name': preloadIssues[i]["channel_name"],
        'is_closed': preloadIssues[i]["is_closed"]
      };

      dataList += [item];
    }

    return dataList;
  }

  handleMessageToAttachments(String message) {
    String name = Utils.suffixNameFile('message', fileItems);
    List<int> bytes = utf8.encode(message);
    processFiles([{
      "name": '$name.txt',
      "mime_type": 'txt',
      "path": '',
      "file": bytes
    }]);

    key.currentState!.controller!.clear();
  }

  processFiles(files) async{
    try {
      List result  = [];
      for(var i = 0; i < files.length; i++) {
        var file = files[i];
        var existed  =  (fileItems + result).indexWhere((element) => (element["path"] == files[i]["path"] && element['name'] == file['name']));
        if (existed != -1) continue;

        String type = Utils.getLanguageFile(file['mime_type'].toLowerCase());
        int index = Utils.languages.indexWhere((ele) => ele == type);

        try {
          if (index != -1 && file['preview'] == null) {
            String message = utf8.decode((file['file'] as List<int>));

            file = {
              ...files[i],
              'preview': message.length >= 1000 ? message.substring(0, 1000) + ' ...'  : message,
            };
          }
        } catch (err) {}

        result += [file];
      }
      if (result.isNotEmpty) {
        if (mounted) setState(() { fileItems += result; });
      }
      StreamDropzone.instance.initDrop();
      if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    } catch (e) {
      print(e.toString());
    }
  }
  
  openFileSelector() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path ?? '')).toList();
      for(int i=0;i<files.length;i++) {
        String name = files[i].path.split('/').last;
        processFiles(files.map((element) {
          return {
            "name": name,
            "mime_type": name.split('.').last,
            "path": files[i].path,
            "file": files[i].readAsBytesSync()
          };
        }).toList());
      }
    } else {
      // User canceled the picker
    }
  }

  selectEmoji(emoji) {
    key.currentState!.setMarkUpText((key.currentState?.controller?.markupText ?? '') + emoji.value);
    key.currentState!.focusNode.requestFocus();
  }

  onEdittingText(value) {
    setState(() {
      islastEdited = value;
    });
  }

  loadMore() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = widget.parentMessage["workspace_id"];
    final channelId = widget.parentMessage["channel_id"];
    final messageId = widget.parentMessage["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/thread?message_id=$messageId&token=$token';
    try {
      final response = await Dio().get(url);
      var dataRes = response.data;
      var dataProcessed = await MessageConversationServices.processBlockCodeMessage(dataRes["thread_messages"]);
      setState(() {
        widget.parentMessage["children"] = dataProcessed;
      });
    } catch (e) {
      print("Error load thread: $e");
    }
  }

  updateMessage(dataM) {
    List data = widget.parentMessage["children"];
    final messageId = dataM["id"];

    if (data.isNotEmpty || dataM["isChildMessage"] == false) {
      int indexMessage = data.indexWhere((e) => e["id"] == messageId);

      if (indexMessage != -1 || dataM["isChildMessage"] == false) {
        var message = dataM["message"];
        var mentions = dataM["attachments"] != null ?  dataM["attachments"].where((element) => element["type"] == "mention").toList() : [];
        var sendToChannelFromThread  = dataM["attachments"] != null ? dataM["attachments"].where((element) => element["type"] == "send_to_channel_from_thread").toList() : [];

        if (mentions.length > 0) {
          var mentionData = mentions[0]["data"];
          message = "";
          for(var i= 0; i< mentionData.length ; i++){
            if (mentionData[i]["type"] == "text" ) {
              message += mentionData[i]["value"];
            } else {
              message += "=======${mentionData[i]["trigger"] ?? "@"}/${mentionData[i]["value"]}^^^^^${mentionData[i]["name"]}^^^^^${mentionData[i]["type"] ?? ((mentionData[i]["id"].length < 10) ? "all" : "user")}+++++++";
            }
          }
        }

        if (sendToChannelFromThread.length == 0) {
          var attOldMessage = dataM["attachments"] != null ? dataM["attachments"].where((ele) => ele["mime_type"] != "block_code" && ele["type"] != "mention").toList() : [];
          setState((){
            fileItems = attOldMessage;
          });
        }
        key.currentState!.setMarkUpText(message);
        key.currentState!.focusNode.requestFocus();
      }

      setUpdateMessage(dataM, true);
    }
  }

  onChangeInput(parentMessage, str) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final channelId = parentMessage["channel_id"];
    
    if (!threadFetching && parentMessage["unread"]) {
      threadFetching = true;
      await Provider.of<Threads>(context, listen: false).updateThreadUnread(currentWorkspace["id"], channelId, parentMessage, auth.token);
      Utils.updateBadge(context);
      threadFetching = false;
    }
  }

  onChangedTypeFile(int index, String name, String type) {
    setState(() {
      fileItems[index]['mime_type'] = type;
      fileItems[index]['name'] = name+'.'+type;
    });
    key.currentState?.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<User>(context, listen: false).currentUser["custom_color"];
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    var parentMessage = widget.parentMessage;
    final userId = parentMessage["user_id"];
    final channelId = parentMessage["channel_id"];
    final channel = getChannel(channelId);
    List newList =  parentMessage["attachments"] != null ? parentMessage["attachments"].where((e) => e["mime_type"] == "html").toList() : [];
    if (newList.isNotEmpty) {
      Utils.handleSnippet(newList[0]["content_url"], false).then((value) {
        int index = snippetList.indexWhere((e) => e["id"] == parentMessage["id"]);
        if (index == -1 && mounted) {
          setState(() {
          snippetList.add({
            "id": parentMessage["id"],
            "snippet": value,
          });
        });
        }
      });
    }
    List blockCode = parentMessage["attachments"] != null ? parentMessage["attachments"].where((e) => e["mime_type"] == "block_code").toList() : [];
    if (blockCode.isNotEmpty) {
      Utils.handleSnippet(blockCode[0]["content_url"], true).then((value) {
        int index = listBlockCode.indexWhere((e) => e["id"] == parentMessage["id"]);
        if (index == -1 && mounted) {
          setState(() {
          listBlockCode.add({
            "id": parentMessage["id"],
            "block_code": value,
          });
        });
        }
      });
    }
    final newSnippet = snippetList.where((e) => e["id"] == parentMessage["id"]).toList();
    final newListBlockCode = listBlockCode.where((e) => e["id"] == parentMessage["id"]).toList();

    List children = parentMessage["children"];
    List childrenReverse = List.from(children).reversed.toList();

    return DropZone(
      initialData: [],
      stream: StreamDropzone.instance.dropped,
      onHighlightBox: (value) { setState(() { onHighlight = value; }); },
      // useCustomHighlight: true,
      builder: (context, files) {
        if(files.data != null && files.data.length > 0) processFiles(files.data ?? []);
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
            boxShadow: [if (onHighlight) BoxShadow(color: isDark ? Colors.white : Palette.backgroundRightSiderDark, blurRadius: 3.0)]
            // boxShadow: [if (onHighlight) BoxShadow(color: Colors.white, blurRadius: 3.0, blurStyle: BlurStyle.solid)]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    child: Column(
                      children: [
                        Container(
                          height: 32,
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.only(left: 12.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF5E5E5E) : const Color(0xFFEAE8E8),
                            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                          ),
                          child: channel == null ? Container() : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(channel["is_private"] ? CupertinoIcons.lock_fill : CupertinoIcons.number, size: 14),
                                  const SizedBox(width: 4.0),
                                  Text(channel["name"], style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1F2933), fontWeight: FontWeight.w500))
                                ]
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: SimpleTooltip(
                                  arrowTipDistance: 0.0,
                                  tooltipDirection: TooltipDirection.left,
                                  animationDuration: const Duration(milliseconds: 100),
                                  borderColor: isDark ? const Color(0xFF262626) :const Color(0xFFb5b5b5),
                                  borderWidth: 0.5,
                                  borderRadius: 5,
                                  backgroundColor: isDark ? const Color(0xFF1c1c1c): Colors.white,
                                  arrowLength:  6,
                                  arrowBaseWidth: 6.0,
                                  ballonPadding: EdgeInsets.zero,
                                  show: tooltipNotify,
                                  content: Material(child: Text(parentMessage["notify"] == null || parentMessage["notify"] ? "Turn off this thread" : "Turn on this thread"), color: Colors.transparent),
                                  child: InkWell(
                                    onHover: (hover) => setState(() {
                                      tooltipNotify = hover;
                                    }),
                                    onTap: () {
                                      final notify = parentMessage["notify"] != null ? !parentMessage["notify"] : false;
                                      parentMessage["notify"] = notify;
                                      Provider.of<Threads>(context, listen: false).changeNotifyThread(auth.token, parentMessage["workspace_id"], parentMessage["channel_id"], parentMessage["id"], notify);
                                    },
                                    child: Icon((parentMessage["notify"] == null || parentMessage["notify"]) ? Icons.notifications_none : Icons.notifications_off_outlined, size: 18),
                                  )
                                )
                              )
                            ]
                          )
                        ),
                        SelectableScope(
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0)
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0)
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(color: parentMessage["unread"] ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : Colors.transparent, width: 4)
                                      )
                                    ),
                                
                                    child: ChatItemMacOS(
                                      id: parentMessage["id"],
                                      message: parentMessage["message"],
                                      avatarUrl: getUser(userId)["avatar_url"],
                                      insertedAt: parentMessage["inserted_at"],
                                      fullName: Utils.getUserNickName(userId) ?? getUser(userId)["full_name"],
                                      attachments: parentMessage["attachments"],
                                      accountType: parentMessage["account_type"] ?? "user",
                                      isChannel: true,
                                      userId: userId,
                                      isThread: true,
                                      reactions: parentMessage["reactions"],
                                      isLast: true,
                                      isFirst: true,
                                      blockCode: newListBlockCode.isNotEmpty ? newListBlockCode[0]["block_code"] : "",
                                      isChildMessage: false,
                                      channelId: parentMessage["channel_id"],
                                      isViewMention: false,
                                      snippet: newSnippet.isNotEmpty ? newSnippet[0]["snippet"] : "",
                                      isViewThread: true,
                                      isUnsent: parentMessage["is_unsent"],
                                      firstMessage: false,
                                      isDark: isDark,
                                      updateMessage: updateMessage,
                                      customColor: customColor
                                    )
                                  )
                                )
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.only(left: 64.0, right: 20.0, top: 16, bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)),
                                ),
                                child: Column(
                                  children: <Widget> [
                                    if (parentMessage["count_child"] != null && parentMessage["count_child"] > children.length) InkWell(
                                      onTap: () {
                                        loadMore();
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(bottom: 14, left: 18),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue, width: 0.75)
                                            )
                                          ),
                                          child: Text(
                                            "Show ${parentMessage["count_child"] - children.length} more replies",
                                            style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                                          ),
                                        )
                                      )
                                    )
                                  ] + children.map<Widget>((item) {
                                    final message = item;
                                    final i = childrenReverse.indexWhere((e) => e["id"] == item["id"]);
                                
                                    DateTime dateTime = DateTime.parse(childrenReverse[i]["inserted_at"] ?? childrenReverse[i]["time_create"]);
                                    var timeStamp = dateTime.toUtc().millisecondsSinceEpoch;
                                    bool showHeader = true;
                                    bool showNewUser = true;
                                
                                    if ((i + 1) < (childrenReverse.length)) {
                                      DateTime nextTime = DateTime.parse(childrenReverse[i + 1]["inserted_at"] ?? childrenReverse[i + 1]["time_create"]);
                                      var nextTimeStamp = nextTime.toUtc().millisecondsSinceEpoch;
                                      showHeader = (dateTime.day != nextTime.day || dateTime.month != nextTime.month || dateTime.year != nextTime.year);
                                      showNewUser = timeStamp - nextTimeStamp > 600000;
                                    }
                                
                                    List newList = childrenReverse[i]["attachments"].where((e) => e["mime_type"] == "html").toList();
                                    if (newList.isNotEmpty) {
                                      Utils.handleSnippet(newList[0]["content_url"], false).then((value) {
                                        int index = snippetList.indexWhere((e) => e["id"] == childrenReverse[i]["id"]);
                                        if (index == -1) {
                                          setState(() {
                                            snippetList.add({
                                              "id": childrenReverse[i]["id"],
                                              "snippet": value,
                                            });
                                        });
                                        }
                                      });
                                    }
                                    List blockCode = childrenReverse[i]["attachments"].where((e) => e["mime_type"] == "block_code").toList();
                                    if (blockCode.isNotEmpty) {
                                      Utils.handleSnippet(blockCode[0]["content_url"], true).then((value) {
                                        int index = listBlockCode.indexWhere((e) => e["id"] == childrenReverse[i]["id"]);
                                        if (index == -1) {
                                          setState(() {
                                            listBlockCode.add({
                                              "id": childrenReverse[i]["id"],
                                              "block_code": value,
                                            });
                                          });
                                        }
                                      });
                                    }
                                    final newSnippet = snippetList.where((e) => e["id"] == childrenReverse[i]["id"]).toList();
                                    final newListBlockCode = listBlockCode.where((e) => e["id"] == childrenReverse[i]["id"]).toList();
                                
                                    return ChatItemMacOS(
                                      key: Key(message["id"].toString()),
                                      id: message["id"],
                                      message: message["message"],
                                      avatarUrl: getUser(message["user_id"])["avatar_url"],
                                      insertedAt: message["inserted_at"],
                                      fullName:Utils.getUserNickName(message["user_id"]) ?? getUser(message["user_id"])["full_name"],
                                      attachments: message["attachments"],
                                      accountType: message["account_type"] ?? "user",
                                      isChannel: true,
                                      userId: message["user_id"],
                                      isThread: true,
                                      reactions: message["reactions"],
                                      isFirst: i == childrenReverse.length - 1 ? true : childrenReverse[i]["user_id"] != childrenReverse[i + 1]["user_id"] ? true : false,
                                      isLast: i == 0 ? true : childrenReverse[i]["user_id"] != childrenReverse[i - 1]["user_id"] ? true : false,
                                      snippet: newSnippet.isNotEmpty ? newSnippet[0]["snippet"] : "",
                                      blockCode: newListBlockCode.isNotEmpty ? newListBlockCode[0]["block_code"] : "",
                                      isChildMessage: true,
                                      channelId: parentMessage["channel_id"],
                                      isViewMention: false,
                                      isViewThread: true,
                                      showHeader: showHeader,
                                      showNewUser: showNewUser,
                                      firstMessage: false,
                                      isDark: isDark,
                                      updateMessage: updateMessage,
                                      customColor: customColor,
                                    );
                                  }).toList()
                                )
                              )
                            ]
                          )
                        )
                      ]
                    )
                  )
                ]
              ),
              Container(
                padding: const EdgeInsets.only(left: 72, right: 24),
                decoration: BoxDecoration(
                  color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4.0), bottomRight: Radius.circular(4.0)),
                ),
                child: Column(
                  children:[
                    fileItems.isNotEmpty ? FileItems(files: fileItems, removeFile: removeFile, onChangedTypeFile: onChangedTypeFile) : Container(),
                    (parentMessage["is_archived"] != null && parentMessage["is_archived"]) ? Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      height: 36,
                      child: Center(child: Text("You are viewing a thread from an archived channel.", style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14
                      )))
                    ) :
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff1E1E1E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: isDark ? null : Border.all(
                          color: const Color(0xffA6A6A6), width: 0.5
                        ),
                      ),
                      child: Focus(
                        onFocusChange: (value) async {
                          if (!threadFetching && parentMessage["unread"]) {
                            threadFetching = true;
                            await Provider.of<Threads>(context, listen: false).updateThreadUnread(currentWorkspace["id"], channelId, parentMessage, auth.token);
                            Utils.updateBadge(context);
                            threadFetching = false;
                          }
                        },
                        child: Column(
                          children: [
                            FlutterMentions(
                              parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                              isIssues: false,
                              cursorColor: isDark ? Colors.grey[400]! : Colors.black87,
                              key: key,
                              autofocus: false,
                              id: channelId.toString(),
                              isDark: isDark,
                              setUpdateMessage: setUpdateMessage,
                              isUpdate: isUpdate,
                              style: TextStyle(fontSize: 15.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                              sendMessages: handleMessage,
                              isCodeBlock: isCodeBlock,
                              isShowCommand: false,
                              handleCodeBlock: handleCodeBlock,
                              handleMessageToAttachments: handleMessageToAttachments,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.only(left: 5, bottom: 16, top: 16),
                                hintText: 'Add Comment',
                                hintStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5)
                              ),
                              islastEdited: islastEdited,
                              onEdittingText: onEdittingText,
                              onChanged: (str) async {
                                onChangeInput(parentMessage, str);
                              },
                              suggestionListHeight: 200,
                              suggestionListDecoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              onSearchChanged: (trigger, value) { },
                              mentions: [
                                Mention(
                                  markupBuilder: (trigger, mention, value, type) {
                                    return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                                  },
                                  trigger: '@',
                                  style: const TextStyle(color: Colors.lightBlue),
                                  data: getDataMentions(channelId, auth),
                                  matchAll: true,
                                ),
                                Mention(
                                  markupBuilder: (trigger, mention, value, type) {
                                    return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                                  },
                                  trigger: "#",
                                  style: const TextStyle(color: Colors.lightBlue),
                                  data: getSuggestionIssue(),
                                  matchAll: true,
                                )
                              ]
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                !isUpdate
                                  ? ActionInput(openFileSelector: openFileSelector, selectEmoji: selectEmoji, isThreadTab: true,)
                                  : Container(),
                                IconButton(
                                  icon: Icon(Icons.send,
                                    color: const Color(0xffFAAD14),
                                    size: 18
                                  ),
                                  onPressed: () => handleMessage(),
                                ),
                              ],
                            )
                          ],
                        )
                      )
                    )
                  ]
                )
              )
            ]
          )
        );
      }
    );
  }
}
