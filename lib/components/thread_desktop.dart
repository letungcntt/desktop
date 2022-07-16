import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_selection/better_selection.dart';
import 'package:context_menus/context_menus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/expanded_viewport.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/file_items.dart';
import 'package:workcake/components/message_item/attachments/sticker_file.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/workspaces/list_sticker.dart';

import '../hive/direct/direct.model.dart';
import 'message_item/chat_item_macOS.dart';

class ThreadDesktop extends StatefulWidget {
  final parentMessage;
  final bool isMessageImage;
  final DirectModel dataDirectMessage;

  ThreadDesktop({
    Key? key,
    this.parentMessage,
    this.isMessageImage = false,
    required this.dataDirectMessage,
  }) : super(key: key);

  @override
  _ThreadDesktopState createState() => _ThreadDesktopState();
}

class _ThreadDesktopState extends State<ThreadDesktop> {
  List data = [];
  ScrollController? controller;
  var messageParent;
  var selectedMessage;
  var channel;
  var isChannel;
  var token;
  int newLine = 1;
  int? maxLine;
  bool isSelectAll = false;
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  Map? currentDataMessageConversation;
  List fileItems = [];
  List snippetList = [];
  List listBlockCode = [];
  bool isUpdate = false;
  var messageUpdate;
  bool threadFetching = false;
  bool isBlockCode = false;
  bool checked = false;
  double height = 0.0;
  bool isSend = false;
  Timer? _debounce;

  @override
  void initState() {
    controller = new ScrollController();
    channel = Provider.of<Auth>(context, listen: false).channel;
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    isChannel = parentMessage["isChannel"];
    final messageId = parentMessage["id"];
    token = Provider.of<Auth>(context, listen: false).token;

    channel.on("update_channel_thread_message", (data, _ref, _joinRef){
      processUpdateThread(data);
    });

    channel.on("new_message_channel", (data, _ref, _joinRef){
      updateSocketChannel(data);
    });

    channel.on("new_thread_count_conversation", (data, _ref, _joinRef) {
      // final dm = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
      processData(data["data"]);
    });

    channel.on("update_dm_thread_message", (data, _ref, _joinRef) {
      // processUpdateDM(data);
    });
    channel.on("reaction_channel_message", (data, _ref, _j){
      updateReactionChannelMessage(data);
    });

    channel.on("delete_message", (payload, ref, joinRef) {
      deleteMessage(payload);
    });

    channel.on("update_channel_message", (data, _ref, _joinRef){
      updateMessageInThread(data);
    });

    channel.on("delete_message_dm", (dataSocket, _r, _j){
      if (dataSocket == null) return;
      final conversationId = dataSocket["conversation_id"];
      if (conversationId == widget.parentMessage["conversationId"] && mounted){
        var messageDeleted = dataSocket["message_ids"];
        setState(() {
          data = data.map((dataM){
            var indexInDelete = (messageDeleted as List).indexWhere((element) => element == dataM["id"]);
            if (indexInDelete == -1) return dataM;
            return {
              ...(dataM as Map),
              "action": "delete"
            };
          }).toList();
        });
        
      }
    });

    channel.on("delete_for_me", (dataSocket, _r, _j){
      if (dataSocket == null) return;
      final conversationId = dataSocket["conversation_id"];
      if (conversationId == widget.parentMessage["conversationId"] && mounted){
        var messageDeleted = dataSocket["message_ids"];
        messageDeleted.map((mid) {
        Provider.of<DirectMessage>(context, listen: false).updateDeleteMessage(token, conversationId, mid, type: "delete_for_me");      
        }).toList();

        setState(() {
          data = data.map((dataM){
            var indexInDelete = (messageDeleted as List).indexWhere((element) => element == dataM["id"]);
            if (indexInDelete == -1) return dataM;
            return {
              ...(dataM as Map),
              "action": "delete_for_me"
            };
          }).toList();
        });
      } 
    });

    super.initState();
    if (isChannel) {
      getDataChannelThread();
    } else {
      currentDataMessageConversation =  Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.parentMessage["conversationId"]);
      getData(widget.parentMessage["conversationId"], messageId);
    }
  }

  updateReactionChannelMessage(dataReaction){
    Map dataM  = dataReaction["reactions"];
    var indexMessage =  data.indexWhere((element) => element["id"] == dataM["message_id"]);
    if (indexMessage != -1 && mounted){
      setState(() {
        data[indexMessage]["reactions"] = MessageConversationServices.processReaction(dataM["reactions"]);    
      });

    }
  }

  @override
  void dispose() {
    super.dispose();
  }


  handleMessage() {
    final auth = Provider.of<Auth>(context, listen: false);
    if (Utils.checkedTypeEmpty(key.currentState!.controller!.text.trim()) || fileItems.isNotEmpty) {
      if (isChannel) {
        if (isUpdate) {
          _sendUpdateMessage(auth);
        } else {
          sendChannelThreadMessage(auth.token);
        }
      } else {
        sendThreadMessage();
      }
    }
    handleCodeBlock(false);
      
    Timer(const Duration(microseconds: 100), () => {
      key.currentState!.controller!.clear()
    });
  }

  updateMessageInThread(payload) {
    if (mounted) {
      final index = data.indexWhere((e) => e["id"] == payload["id"]);

      if (index != -1) {
        setState(() {
          data[index]["message"] = payload["message"];
          data[index]["attachments"] = payload["attachments"];  
        });
      }
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    final messageId = parentMessage["id"];

    isChannel = parentMessage["isChannel"];

    if (oldWidget.parentMessage["id"] != widget.parentMessage["id"] || oldWidget.parentMessage["isChannel"] != widget.parentMessage["isChannel"]) {
      if (mounted) {
        setState(() {
          data = [];
          height = 0.0;
        });
      }
      if(isChannel){
        getDataChannelThread();
      } else {
        currentDataMessageConversation =  Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.parentMessage["conversationId"]);
        getData(widget.parentMessage["conversationId"], messageId);
      }
    }
  }

  deleteMessage(payload) {
    if (mounted) {
      final messageId = payload["message_id"];
      final index = data.indexWhere((e) => e["id"] == messageId);
      
      if (index != -1) {
        List newData = List.from(data);
        newData.removeAt(index);

        setState(() {
          data = newData;
        });
      }
    }
  }

  processData(dataM) async {
    if (mounted) {
      final parentMessage = !widget.isMessageImage
                            ? Provider.of<Messages>(context, listen: false).parentMessage
                            : Provider.of<Messages>(context, listen: false).messageImage;
      if (!isChannel) {
        for (var i =0; i< dataM.length; i++){
          var dataMessage  = dataM[i];
          var dataDe =  await currentDataMessageConversation!["conversationKey"].decryptMessage(dataMessage);
          if(dataDe["success"]){
            dataMessage = {...dataDe["message"], "is_blur": false};
            // save to Isar
            await MessageConversationServices.insertOrUpdateMessage(dataMessage);  
            Provider.of<DirectMessage>(context, listen: false).markReadConversationV2(token, parentMessage["conversationId"], [dataMessage["id"]], [], true);
            if (dataMessage["parent_id"] == parentMessage["id"]) {
              int index = data.indexWhere((e) => e["fake_id"] == dataMessage["fake_id"]);
              List fromListData = List.from(data);
              if (index != -1) {
                fromListData[index] = dataMessage;
              } else {
                fromListData.add(dataMessage);
              }
              setState(() {
                data = fromListData;
                if (messageParent != null) {
                  messageParent["count"] = messageParent["count"] + 1;
                }
              });
            }
          }
        }
      }
    }
  }

  processFiles(files) async{
    List result  = [];
    for(var i = 0; i < files.length; i++) {
      // check the path has existed
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
    fileItems = [] + fileItems + result;
    if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    StreamDropzone.instance.initDrop();
  }

  getData(directMessageId, messageId) async {
    try {
      // mac dinh se hien thi data trong isar truoc
      // sau do se merge data tren server
      List dataFromIsar = await MessageConversationServices.getMessageThreadAll(directMessageId, messageId, parseJson: true);
      final deviceId  =  await Utils.getDeviceId();
      final url = "${Utils.apiUrl}direct_messages/$directMessageId/thread_messages/$messageId/messages?token=$token&device_id=$deviceId&mark_read_thread=true";

      var response = await Dio().get(url);
      var dataRes = response.data;
      
      if (dataRes["success"] && mounted) {
        var result  = [];
        List<String> errorIds = [];
        List messageError = [];
        Map dataToSave = {};
        for (var i =0 ; i < dataRes["data"].length; i++){
          try {
            var dataM = await currentDataMessageConversation!["conversationKey"].decryptMessage( dataRes["data"][i]);
            // merge data on Isar
            var indexFromIsar = dataFromIsar.indexWhere((element) => element["id"] == dataRes["data"][i]["id"]);
            var dataMessage = Utils.mergeMaps([
              indexFromIsar != -1 ? dataFromIsar[indexFromIsar] : {},
              dataM["success"] ? dataM["message"] : {},
            ]);
            if (dataMessage["id"] != null){
              result += [dataMessage];
              var key = messageId + "_" + dataMessage["id"];
              dataToSave["$key"] = dataMessage;
            } else {
              errorIds += [dataRes["data"][i]["id"]];
              messageError += [{
                ...(dataRes["data"][i]),
                "status_decrypted": "decryptionFailed"
              }];
            }
          } catch (e) {
            print("___ error $e");
          }
        }
        Provider.of<DirectMessage>(context, listen: false).markReadConversationV2(token, directMessageId, ((dataFromIsar + result)).map((e) => (e["id"] as String)).toList(), errorIds, false);
        MessageConversationServices.insertOrUpdateMessages(result);
        result = MessageConversationServices.uniqById( [] + dataFromIsar + result + messageError);
        Provider.of<DirectMessage>(context, listen: false).getInfoUnreadMessage(result, token, directMessageId);
        setState(() {
          data = data + result.reversed.toList() ;
        });
      }
    } catch (e) {
      print("Direct Error: $e ");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    var isFocusThread = FocusInputStream.instance.focusTarget == FocusTarget.THREADBOX;
    if (isFocusThread && mounted) {
      FocusScope.of(context).unfocus();
      if (key.currentState != null)
        key.currentState!.focusNode.requestFocus();
    }
  }

  replaceNickName(List messages) {
    List nickNames = Provider.of<Workspaces>(Utils.globalContext!, listen: false).members;
    return messages.map((e) {

    var index = nickNames.indexWhere((user) => user["id"]  == e["user_id"]);

      return {...e,
      "full_name": index == -1 ? e["full_name"] :  (nickNames[index]["nickname"] ??  e["full_name"])
    };
    }).toList();
  }

  getDataChannelThread() async {
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    final workspaceId = parentMessage["workspaceId"];
    final channelId = parentMessage["channelId"];
    final messageId = parentMessage["id"];
    // int index = Provider.of<Channels>(context, listen: false).data.indexWhere((e) => e["id"] == channelId); 
    // var currentChannelSelected = Provider.of<Channels>(context, listen: false).data[index];  

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/thread?message_id=$messageId&token=$token';
    try {
      final response = await Dio().get(url);
      var dataRes = response.data;
      if (dataRes["success"] && mounted) {
        if (widget.parentMessage == null || dataRes["parent_message"]["id"] == widget.parentMessage["id"]) {
          data = await MessageConversationServices.processBlockCodeMessage(dataRes["thread_messages"]);
          setState(() {
            data = replaceNickName(data);
            messageParent = dataRes["parent_message"];
          });
        }
      }
    } catch (e) {
      print("Error Channel: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    var isFocusThread = FocusInputStream.instance.focusTarget == FocusTarget.THREADBOX;
    if (isFocusThread) {
      if (mounted) FocusScope.of(context).unfocus();
    key.currentState?.focusNode.requestFocus();
    }
  }

  updateUnreadOpenThread(workspaceId, channelId, token) {
    final parentMessage = Provider.of<Messages>(context, listen: false).parentMessage;

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
        Utils.updateBadge(context);  
      }
    });
  }

  updateSocketChannel(payload) {
    if (mounted) { 
      Map newMessage = {...payload["message"], "is_blur": false};
      final parentMessage = !widget.isMessageImage
        ? Provider.of<Messages>(context, listen: false).parentMessage
        : Provider.of<Messages>(context, listen: false).messageImage;

      if (parentMessage["id"] != null) {
        final messageId = parentMessage["id"];

        if (newMessage["id"] != null && newMessage["channel_thread_id"] != null && newMessage["channel_thread_id"] ==  messageId) {
          int index = data.indexWhere((e) => e["key"] == newMessage["key"]);
          List fromListData = List.from(data); 

          if (index != -1) {
            fromListData[index] = newMessage;
          } else {
            fromListData.add(newMessage);
          }

          setState(() {
            data = fromListData;
          });

          var isFocusApp = Provider.of<Auth>(context, listen: false).onFocusApp;
          if (isFocusApp) {
            updateUnreadOpenThread(newMessage["workspace_id"], newMessage["channel_id"], token);
          }
        }
      }
    }
  }

  processUpdateThread(dataM) async {
    if (mounted) {
      if (messageParent != null && dataM["message_id"] == messageParent["id"]) {
        Map parentMessage = { 
          "id": dataM["id"],
          "message": dataM["message"],
          "avatarUrl": dataM["avatar_url"],
          "lastEditedAt": dataM["last_edited_at"],
          "isUnsent": dataM["is_unsent"],
          "fullName": dataM["full_name"],
          "insertedAt": dataM["inserted_at"],
          "attachments": dataM["attachments"],
          "userId": dataM["user_id"],
          "workspaceId": dataM["workspace_id"],
          "channelId": dataM["channel_id"] is int ? dataM["channel_id"] : int.parse(dataM["channel_id"]),
          "isChannel": true
        };

        await Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
      } else {
        final index = data.indexWhere((element) {return element["id"] == dataM["message_id"];});
        
        if (index != -1) {
          setState(() {
            data[index]["message"] = dataM["message"];
            data[index]["attachments"] = dataM["attachments"];
            data[index]["last_edited_at"] = dataM["last_edited_at"];
          });
        }
      }
    }
  }
  getSuggestionMentions() {
    List listUser = [];
    List<Map<String, dynamic>> dataList = [];
    final auth = Provider.of<Auth>(context, listen: false);
    final data = Provider.of<DirectMessage>(context, listen: false).data;
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;

    if(parentMessage["isChannel"]) {
      List members = Provider.of<Channels>(context, listen: false).getDataMember(parentMessage["channelId"]);
      listUser = members.length < 2 ? [] : members; 
    } else {
      int index = data.indexWhere((e) => e.id == parentMessage["conversationId"]);
      final dataUserMentions = Provider.of<User>(context, listen: false).userMentionInDirect;
      if(index != -1) listUser = [] + data[index].user + dataUserMentions;
    }
    Map index = {};

    for (var i = 0 ; i < listUser.length; i++){
      var keyId =listUser[i]["user_id"] ??listUser[i]["id"];
      if (index[keyId] != null) continue;
      Map<String, dynamic> item = {
        'id': isChannel ? listUser[i]["id"] : listUser[i]["user_id"],
        'type': 'user',
        'display':Utils.getUserNickName(isChannel ? listUser[i]["id"] : listUser[i]["user_id"]) ?? listUser[i]["full_name"],
        'full_name': Utils.checkedTypeEmpty(Utils.getUserNickName(isChannel ? listUser[i]["id"] : listUser[i]["user_id"]))
            ? "${Utils.getUserNickName(isChannel ? listUser[i]["id"] : listUser[i]["user_id"])} • ${listUser[i]["full_name"]}"
            : listUser[i]["full_name"],
        'photo': listUser[i]["avatar_url"]
      };
      index[keyId] = true;

      if ((isChannel && auth.userId != listUser[i]["id"]) || (listUser[i]["user_id"] != null && auth.userId != listUser[i]["user_id"])) dataList += [item];
    }

    return dataList;
  }

  sendChannelThreadMessage(token) async{
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    final channelId = parentMessage["channelId"];
    final workspaceId = parentMessage["workspaceId"];
    final channelThreadId = parentMessage["id"];
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText.trim());
    Provider.of<Workspaces>(context, listen: false).updateUnreadMention(workspaceId, channelThreadId, false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    List list = fileItems;

    var dataMessage  = {
      "channel_thread_id": channelThreadId,
      "channel_id": channelId,
      "workspace_id": workspaceId,
      "key": Utils.getRandomString(20),
      "message": result["success"] || isBlockCode ? "" : result["data"],
      "attachments": [] + (checked ? [{"type": "send_to_channel_from_thread", "parent_message": parentMessage, "child_message": result["data"]}] : []) + (result["success"] ? [{"type": "mention", "data": result["data"]}] : []) + (isBlockCode ? [{"type": "block_code", "data": [{"type": "block_code", "value": key.currentState!.controller!.text}]}] : []),
      "isDesktop": true,
      "fromThread": true,
      "alsoSendToChannel": checked,
      "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "user_id": currentUser["id"],
      "user": currentUser["full_name"] ?? "",
      "avatar_url": currentUser["avatar_url"] ?? "",
      "full_name": currentUser["full_name"] ?? "",
      "is_blur": false,
    };

    data.add(dataMessage);

    if (selectedMessage != null){
      var idMessageSelected = selectedMessage.split("__")[1];
      var messageSelected = data.firstWhere((element)  {return element["id"] == idMessageSelected;});
      var  attachments = messageSelected == null ? [] : messageSelected["attachments"] == null ? [] : messageSelected["attachments"];
      for(var i= 0; i< attachments.length; i ++){
        if ((attachments[i]["type"] ?? "") != "mention"){
          dataMessage["attachments"] +=[attachments[i]];
        }
      }
    }

    setState(() { fileItems = []; });

    if (Utils.checkedTypeEmpty(key.currentState!.controller!.text.trim()) || list.isNotEmpty) {
      Provider.of<Messages>(context, listen: false).sendMessageWithImage(list, dataMessage, token);
      Future.delayed(const Duration(seconds: 2), () {
        int index = data.indexWhere((e) => e["key"] == dataMessage["key"]);
        if(index != -1 && data[index]["id"] == null) {
          data[index]["is_blur"] = true;
        }
      });
    }
    key.currentState!.controller!.clear();
  }

  removeFile(index) {
    List list = fileItems;
    list.removeAt(index);
    setState(() {
      fileItems = list;
    });
  }

  openFileSelector() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path ?? '')).toList();
      for(int i=0;i<files.length;i++) {
        String name = files[i].path.split('/').last;
        List dataFiles = files.map((element) {
          return {
            "name": name,
            "mime_type": name.split('.').last,
            "path": files[i].path,
            "file": files[i].readAsBytesSync()
          };
        }).toList();

      setState(() {
        fileItems = dataFiles;
        key.currentState!.focusNode.requestFocus();
      });
      }
    } else {
      // User canceled the picker
    }
  }

  selectEmoji(emoji) {
    key.currentState!.setMarkUpText((key.currentState?.controller?.markupText ?? '') + emoji.value);
    key.currentState!.focusNode.requestFocus();
  }

  sendThreadMessage() async{
    var userId  = Provider.of<Auth>(context, listen: false).userId;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    final messageId = parentMessage["id"];
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText, trim: true);
    List files  = fileItems;
    var dataMessage = {
      "message": result["success"] || isBlockCode ? "" : result["data"],
      "attachments": [] + (result["success"] ? [{"type": "mention", "data": result["data"]}] : []) + (isBlockCode ? [{"type": "block_code", "data": [{"type": "block_code", "value": key.currentState!.controller!.text}]}] : []),
      "conversation_id": widget.parentMessage["conversationId"],
      "fake_id": Utils.getRandomString(20),
      "time_create": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "user_id": userId,
      "isDesktop": true,
      "current_time": DateTime.now().microsecondsSinceEpoch,
      "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "user": currentUser["full_name"] ?? "",
      "avatar_url": currentUser["avatar_url"] ?? "",
      "full_name": currentUser["full_name"] ?? "",
      "is_blur": false,
      "user_id_parent_message": parentMessage["user_id"] ?? parentMessage["userId"],
      // "current_time_parent_message": parentMessage["current_time"]
    };

    data =(Provider.of<DirectMessage>(context, listen: false).sortMessagesByDay(
      Provider.of<DirectMessage>(context, listen: false).uniqById([] + data + [{
        ...dataMessage,
        "id": ""
      }])
    ) as List).reversed.toList();

    if (selectedMessage != null) {
      var idMessageSelected  =  selectedMessage.split("__")[1];
      var messageSelected =  data.firstWhere((element)  {return element["id"] == idMessageSelected;});
      var  attachments = messageSelected == null ? [] : messageSelected["attachments"] == null ? [] : messageSelected["attachments"];
      for (var i= 0; i < attachments.length; i ++) {
        if ((attachments[i]["type"] ?? "") != "mention"){
          dataMessage["attachments"] +=[attachments[i]];
        }
      }
    }

    key.currentState!.controller!.clear();
    if (!((dataMessage["message"] == "") && (dataMessage["attachments"].length == 0) && (files.isEmpty))){
      try {
        dataMessage["isThread"] = true;
        dataMessage["parentId"] = messageId;
        dataMessage["isSend"] = selectedMessage == null;
        if (selectedMessage == null) {} else {
          var id = selectedMessage.toString().split("__")[1];
          dataMessage["id"] = id;
        }

        setState(() {
          fileItems = [];
        });
        Provider.of<DirectMessage>(context, listen: false).sendMessageWithImage(files, dataMessage, token);
        Future.delayed(const Duration(seconds: 2), () {
          int index = data.indexWhere((e) => e["fake_id"] == dataMessage["fake_id"]);
          if(index != -1 && data[index]["id"] == null) {
            data[index]["is_blur"] = true;
          }
        });
      } catch (e) {
        print("$e ");
      }
    }
  }

  handleMessageToAttachments(String message) {
    String name = Utils.suffixNameFile('message', fileItems);
    List<int> bytes = utf8.encode(message);
    processFiles([{
      "name": '$name.txt',
      "mime_type": 'txt',
      'type': 'txt',
      "path": '',
      "file": bytes
    }]);
  }

  saveChangesToHive(str) async {
    var box = await Hive.openBox('drafts');
    var lastEdited = box.get('lastEdited');
    List changes;

    if (lastEdited == null) {
      changes = [{
        "id": widget.dataDirectMessage.id,
        "text": str,
      }];
    } else {
      changes = List.from(lastEdited);
      final index = changes.indexWhere((e) => e["id"] == widget.dataDirectMessage.id);

      if (index != -1) {
        changes[index] = {
          "id": widget.dataDirectMessage.id,
          "text": str,
        };
      } else {
        changes.add({
          "id": widget.dataDirectMessage.id,
          "text": str,
        });
      }
    }

    box.put('lastEdited', changes);
  }

  updateMessage(dataM) {
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
            if (mentionData[i]["type"] == "text" ) message += mentionData[i]["value"];
            else {
              message += "=======${mentionData[i]["trigger"] ?? "@"}/${mentionData[i]["value"]}^^^^^${mentionData[i]["name"]}^^^^^${mentionData[i]["type"] ?? ((mentionData[i]["id"].length < 10) ? "all" : "user")}+++++++";
            }
          }
        }

        // Tat ca file can hien thi
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

  setUpdateMessage(data, bool value) {
    Provider.of<Windows>(context, listen: false).isBlockEscape = value;
    setState(() {
      messageUpdate = data;
      isUpdate = value;
    });
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

  handleCodeBlock(bool value) {
    setState(() {
      isBlockCode = value;
    });
  }

  _sendUpdateMessage(auth) async{
    List files = fileItems;
    setState(() {
      fileItems = [];
    });
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText);
    var message  = {
      "channel_thread_id": widget.parentMessage["id"],
      "key": Utils.getRandomString(20),
      "message_id": messageUpdate["id"],
      "message": result["success"] ? "" : result["data"],
      "attachments": (result["success"] ? ([] + [{"type": "mention", "data": result["data"] }]) : []) ,
      "channel_id":   widget.parentMessage["channelId"],
      "workspace_id": widget.parentMessage["workspaceId"],
      "user_id": messageUpdate["userId"],
      "is_system_message": false,
      "is_thread": true
    };

    Provider.of<Messages>(context, listen: false).newUpdateChannelMessage(auth.token, message, files);
    key.currentState!.controller!.clear();

    setUpdateMessage(null, false);
  }

  selectSticker(data) {
    final auth = Provider.of<Auth>(context, listen: false);
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: false).parentMessage
                          : Provider.of<Messages>(context, listen: false).messageImage;
    final channelId = parentMessage["channelId"];
    final workspaceId = parentMessage["workspaceId"];
    final channelThreadId = parentMessage["id"];
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    if (!isChannel) {
      var dataMessage = {
        "message": '',
        "attachments": [{
          'type': 'sticker',
          'data': data
        }],
        "conversation_id": widget.parentMessage["conversationId"],
        "fake_id": Utils.getRandomString(20),
        "time_create": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
        "user_id": auth.userId,
        "isDesktop": true,
        "current_time": DateTime.now().microsecondsSinceEpoch,
        "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
        "user": currentUser["full_name"] ?? "",
        "avatar_url": currentUser["avatar_url"] ?? "",
        "full_name": currentUser["full_name"] ?? "",
        "is_blur": false,
        "user_id_parent_message": parentMessage["user_id"] ?? parentMessage["userId"],
        "isThread": true,
        "parentId": channelThreadId,
        "isSend":  true
      };

      Provider.of<DirectMessage>(context, listen: false).sendMessageWithImage([], dataMessage, token);
    } else {
      var dataMessage = {
        "channel_thread_id": channelThreadId,
        "key": Utils.getRandomString(20),
        "message": "",
        "attachments": [{
          'type': 'sticker',
          'data': data
        }],
        "channel_id":  channelId,
        "workspace_id": workspaceId,
        "count_child": 0,
        "user_id": auth.userId,
        "user":currentUser["full_name"] ?? "",
        "avatar_url": currentUser["avatar_url"] ?? "",
        "full_name": Utils.getUserNickName(auth.userId) ?? currentUser["full_name"] ?? "",
        "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
        "is_system_message": false,
        "is_blur": false,
        "isDesktop": true
      };

      Provider.of<Messages>(context, listen: false).sendMessageWithImage([], dataMessage, auth.token);
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
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final deviceHeight = MediaQuery.of(context).size.height;
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: true).parentMessage
                          : Provider.of<Messages>(context, listen: true).messageImage;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final customColor = Provider.of<User>(context, listen: false).currentUser["custom_color"];
    bool isEndDrawerOpen = Scaffold.of(context).isEndDrawerOpen;

    if(parentMessage['id'] == null) return Container();

    List newList = parentMessage["attachments"].where((e) => e["mime_type"] == "html").toList();
    if (newList.isNotEmpty) {
      Utils.handleSnippet(newList[0]["content_url"], false).then((value) {
        int index = snippetList.indexWhere((e) => e["id"] == parentMessage["id"]);
        if (index == -1) setState(() {
          snippetList.add({
            "id": parentMessage["id"],
            "snippet": value,
          });
        });
      });
    }
    List blockCode = parentMessage["attachments"].where((e) => e["mime_type"] == "block_code").toList();
    if (blockCode.isNotEmpty) {
      Utils.handleSnippet(blockCode[0]["content_url"], true).then((value) {
        int index = listBlockCode.indexWhere((e) => e["id"] == parentMessage["id"]);
        if (index == -1) setState(() {
          listBlockCode.add({
            "id": parentMessage["id"],
            "block_code": value,
          });
        });
      });
    }
    
    return DropZone(
      stream: StreamDropzone.instance.dropped,
      shouldBlock: isEndDrawerOpen,
      builder: (context, files) {
        if(files.data != null && files.data.length > 0) processFiles(files.data ?? []);
        return GestureDetector(
          onTap: () async {
            if (!threadFetching) {
              threadFetching = true;
              final workspaceId = widget.parentMessage["workspaceId"];
              final channelId = widget.parentMessage["channelId"];
              await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
              Utils.updateBadge(context);
              threadFetching = false;
            }
          },
          child: Container(
            height: deviceHeight,
            color: isDark ? Color(0xFF2e2e2e) : Color(0xFFF3F3F3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Palette.backgroundTheardDark,
                          border: Border(
                            bottom: BorderSide(
                              color: Palette.borderSideColorDark
                            )
                          ),
                        ),
                        height: 56,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Reply in thread", style: const TextStyle(color: const Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                            widget.isMessageImage ? Container() : IconButton(
                              padding: const EdgeInsets.all(0),
                              onPressed: () { 
                                Provider.of<Messages>(context, listen: false).openThreadMessage(false, {});
                              }, 
                              icon: const Icon(Icons.close, size: 18, color: const Color(0xffF0F4F8))
                            )
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 1/3
                        ),
                        child: SelectableScope(
                          child: SingleChildScrollView(
                            controller: ScrollController(),
                            child: Container(
                              padding: const EdgeInsets.only(top: 16, left: 3, bottom: 16, right: 18),
                              child: ChatItemMacOS(
                                isChildMessage: false,
                                isThread: true,
                                id: parentMessage["id"],
                                message: parentMessage["message"],
                                avatarUrl: parentMessage["avatarUrl"],
                                insertedAt: parentMessage["insertedAt"],
                                lastEditedAt: parentMessage["lastEditedAt"],
                                accountType: parentMessage["account_type"] ?? "user",
                                fullName: parentMessage["fullName"],
                                attachments: parentMessage["attachments"],
                                isChannel: isChannel,
                                userId: parentMessage["userId"],
                                isLast: true,
                                isFirst: true,
                                isMe: parentMessage["userId"] == currentUser["id"], 
                                reactions: parentMessage["reactions"],
                                snippet: parentMessage["snippet"],
                                blockCode: parentMessage["block_code"],
                                isViewMention: false,
                                channelId: parentMessage["channelId"],
                                isUnsent: parentMessage["isUnsent"],
                                conversationId: widget.parentMessage["conversationId"],
                                isDark: isDark,
                                customColor: customColor,
                                updateMessage: updateMessage,
                                isShow: true
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: Text(data.isNotEmpty ? "${data.length} ${data.length > 1 ? "replies" : "reply"}" : "Reply", style: const TextStyle(color: Color(0xff828282), fontSize: 14))
                          ),
                          Expanded(
                            child: Container(
                              color: const Color(0xff828282), height: 1, width: 236,
                              margin: const EdgeInsets.symmetric(horizontal: 3)
                            ),
                          )
                        ],
                      ),
                      // Divider(height: 2, thickness: 2),
                      const SizedBox(height: 10),
                      renderChatitem(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
                      borderRadius: BorderRadius.circular(5),
                      border: isDark ? const Border() : Border.all(
                        color: Palette.borderSideColorLight, width: 1
                      )
                    ),
                    child: Column(
                      children: [
                        fileItems.isNotEmpty ? FileItems(files: fileItems, removeFile: removeFile, onChangedTypeFile: onChangedTypeFile) : Container(),
                        FlutterMentions(
                          onFocusChange: (value) {
                            Provider.of<Messages>(context, listen: false).setIsFocusThread(value);
                          },
                          parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                          isUpdate: isUpdate,
                          isCodeBlock: isBlockCode,
                          isShowCommand: false,
                          isThread: true,
                          handleCodeBlock: handleCodeBlock,
                          isIssues: false,
                          style: TextStyle(fontSize: 15.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                          onChanged: (value) {
                            saveChangesToHive(key.currentState!.controller!.markupText);
                            if(!isSend && value.isNotEmpty) {
                              setState(() => isSend = true);
                            } else if (isSend && value.isEmpty) {
                              setState(() => isSend = false);
                            }

                            if (value.trim() != "") {
                              if (_debounce?.isActive ?? false) _debounce?.cancel();
                              _debounce = Timer(const Duration(milliseconds: 500), () {
                                auth.channel.push(
                                  event: "on_typing",
                                  payload: {"conversation_id": widget.dataDirectMessage.id, "user_name": currentUser["full_name"]}
                                );
                              });
                            }
                          },
                          cursorColor: isDark ? Colors.grey[400]! : Colors.black87,
                          isDark: isDark,
                          setUpdateMessage: setUpdateMessage,
                          id: isChannel ? currentChannel["id"].toString() : widget.parentMessage["conversationId"],
                          sendMessages: handleMessage,
                          handleMessageToAttachments: handleMessageToAttachments,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: "Reply ...",
                            hintStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5)
                          ), 
                          key: key,
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
                              data: getSuggestionMentions(),
                              matchAll: true
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
                        Container(
                          padding: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDark ? const Color(0xff828282) : Palette.borderSideColorLight, width: 1
                              )
                            )
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    child: Transform.scale(
                                      scale: 0.6,
                                      child: Checkbox(
                                        activeColor: isDark ? const Color(0xff19DFCB) : Colors.blue,
                                        side: BorderSide(color: isDark ? Colors.white : const Color(0xff1F3033)),
                                        splashRadius: 1.0,
                                        value: checked,
                                        onChanged: (value) {
                                          setState(() {
                                            checked = !checked;
                                          });
                                        }
                                      ),
                                    ),
                                  ),
                                  Text("Also send to channel", style: TextStyle(color: isDark ? Colors.white : const Color(0xff1F3033), fontSize:  13),)
                                ],
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    ActionThread(handleMessage: handleMessage, isUpdate: isUpdate, openFileSelector: openFileSelector, selectEmoji: selectEmoji, selectSticker: selectSticker),
                                    InkWell(
                                      child: Container(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(isUpdate ? Icons.check : Icons.send,
                                          size: 18,
                                          color: (isSend || (fileItems.isNotEmpty))
                                          ? const Color(0xffFAAD14)
                                          : isDark ? const Color(0xff9AA5B1) : const Color(0xff616E7C),
                                          // color: isDark ? const Color(0xff9AA5B1) : const Color(0xff616e7c)
                                        ),
                                      ),
                                      onTap: () => (isSend || (fileItems.isNotEmpty)) ? handleMessage() : null,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ]
                    )
                  )
                )
              ]
            )
          ),
        );
      }
    );
  }

  jumpToContext(BuildContext? c, String idMessage){
    BuildContext? messageContext = c;
    if (messageContext == null || controller == null) return;
    try {
      height += c!.size!.height;
      var offset = (height - 100) > controller!.position.maxScrollExtent ? controller!.position.maxScrollExtent : (height - 100);
      controller!.animateTo(offset, duration: const Duration(milliseconds: 100), curve: Curves.ease);
    } catch (e) {
      print(e);
    }
  }

  onFirstFrameMessageSelectedDone(BuildContext? cont, int? time, String? idMessage){
    final parentMessage = !widget.isMessageImage
      ? Provider.of<Messages>(context, listen: false).parentMessage
      : Provider.of<Messages>(context, listen: false).messageImage;
    if (parentMessage["idMessageToJump"] == null || idMessage == null) return;
    try {
      int index  = data.indexWhere((ele) => ele["id"] == parentMessage["idMessageToJump"]);
      int currentT = data[index]["current_time"];
      if (time! >=currentT) jumpToContext(cont, idMessage);
    } catch (_e, trace) {
      print("PPPPPPP $trace");
    }
  }

  Flexible renderChatitem() {
    final dataReversed = data.reversed.toList();
    dataReversed.sort((a,  b) => (b["current_time"] ?? 999999999999999999).compareTo((a["current_time"] ?? 999999999999999999))); 

    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final parentMessage = !widget.isMessageImage
                          ? Provider.of<Messages>(context, listen: true).parentMessage
                          : Provider.of<Messages>(context, listen: true).messageImage;
    return Flexible(
      child: SelectableScope(
        child: Scrollable(
          controller: controller,
          axisDirection: AxisDirection.up,
          viewportBuilder: (context, offset) {
            return ExpandedViewport(
              offset: offset,
              axisDirection: AxisDirection.up,
              crossAxisDirection: null,
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.only(right: 18),
                    sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) {
                        if (dataReversed[i]["action"] == "delete_for_me") return Container();
                        DateTime dateTime = DateTime.parse(dataReversed[i]["inserted_at"] ?? dataReversed[i]["time_create"]);
                        var timeStamp = dateTime.toUtc().millisecondsSinceEpoch;
                        bool showHeader = true;
                        bool showNewUser = true;
            
                        if ((i + 1) < (dataReversed.length)) {
                          DateTime nextTime = DateTime.parse(dataReversed[i + 1]["inserted_at"] ?? dataReversed[i + 1]["time_create"]);
                          var nextTimeStamp = nextTime.toUtc().millisecondsSinceEpoch;
                          showHeader = (dateTime.day != nextTime.day || dateTime.month != nextTime.month || dateTime.year != nextTime.year);
                          showNewUser = timeStamp - nextTimeStamp > 600000;
                        }
            
                        List newList = (dataReversed[i]["attachments"] ?? []).where((e) => e["mime_type"] == "html").toList();
                        if (newList.isNotEmpty) {
                          Utils.handleSnippet(newList[0]["content_url"], false).then((value) {
                            int index = snippetList.indexWhere((e) => e["id"] == dataReversed[i]["id"]);
                            if (index == -1) setState(() {
                              snippetList.add({
                                "id": dataReversed[i]["id"],
                                "snippet": value,
                              });
                            });
                          });
                        }
                        List blockCode = (dataReversed[i]["attachments"] ?? []).where((e) => e["mime_type"] == "block_code").toList();
                        if (blockCode.isNotEmpty) {
                          Utils.handleSnippet(blockCode[0]["content_url"], true).then((value) {
                            int index = listBlockCode.indexWhere((e) => e["id"] == dataReversed[i]["id"]);
                            if (index == -1) setState(() {
                              listBlockCode.add({
                                "id": dataReversed[i]["id"],
                                "block_code": value,
                              });
                            });
                          });
                        }
                        final newSnippet = snippetList.where((e) => e["id"] == dataReversed[i]["id"]).toList();
                        final newListBlockCode = listBlockCode.where((e) => e["id"] == dataReversed[i]["id"]).toList();

                        return ChatItemMacOS(
                          key: Key(dataReversed[i]["id"].toString()),
                          width: 250,
                          isChannel: isChannel,
                          id: dataReversed[i]["id"],
                          isMe: dataReversed[i]["user_id"] == currentUser["id"],
                          message: dataReversed[i]["message"] ?? "",
                          lastEditedAt: dataReversed[i]["last_edited_at"],
                          accountType: dataReversed[i]["account_type"] ?? "user",
                          isUnsent: Utils.checkedTypeEmpty(widget.parentMessage["conversationId"]) ? dataReversed[i]["action"] == "delete" : dataReversed[i]["is_unsent"],
                          avatarUrl: dataReversed[i]["avatar_url"] ?? "",
                          insertedAt: (dataReversed[i]["inserted_at"] ?? dataReversed[i]["time_create"]) ?? "",
                          fullName: Utils.getUserNickName(dataReversed[i]["user_id"]) ?? dataReversed[i]["full_name"] ?? "",
                          attachments: dataReversed[i]["attachments"] != null && dataReversed[i]["attachments"].length > 0 ? dataReversed[i]["attachments"] : [],
                          count: 0,
                          isFirst: i == dataReversed.length - 1 ? true : dataReversed[i]["user_id"] != dataReversed[i + 1]["user_id"] ? true : false,
                          isLast: i == 0 ? true : dataReversed[i]["user_id"] != dataReversed[i - 1]["user_id"] ? true : false,
                          isChildMessage: true,
                          isThread: true,
                          showHeader: showHeader,
                          showNewUser: showNewUser,
                          userId: dataReversed[i]["user_id"],
                          reactions: Utils.checkedTypeEmpty(dataReversed[i]["reactions"]) ? dataReversed[i]["reactions"]  : [], 
                          isViewMention: false,
                          channelId: widget.parentMessage["channelId"],
                          updateMessage: updateMessage,
                          snippet: newSnippet.isNotEmpty ? newSnippet[0]["snippet"] : "",
                          blockCode: newListBlockCode.isNotEmpty ? newListBlockCode[0]["block_code"] : "",
                          conversationId: widget.parentMessage["conversationId"],
                          isBlur: dataReversed[i]["is_blur"],
                          isDark: isDark,
                          waittingForResponse: (dataReversed[i]["status_decrypted"] ?? "") == "decryptionFailed",
                          currentTime: dataReversed[i]["current_time"],
                          parentId: dataReversed[i]["parent_id"],
                          idMessageToJump: parentMessage["idMessageToJump"],
                          onFirstFrameDone: onFirstFrameMessageSelectedDone,
                          customColor: currentUser["custom_color"],
                        );
                      },
                      childCount: dataReversed.length,
                    )
                  )
                )
              ]
            );
          }
        ),
      )
    );
  }
}

class ActionThread extends StatefulWidget {
  ActionThread({
    Key? key,
    required this.openFileSelector,
    required this.handleMessage,
    required this.selectEmoji,
    required this.isUpdate,
    required this.selectSticker,
  }) : super(key: key);

  final Function openFileSelector;
  final Function handleMessage;
  final Function selectEmoji;
  final bool isUpdate;
  final Function selectSticker;

  @override
  State<ActionThread> createState() => _ActionThreadState();
}

class _ActionThreadState extends State<ActionThread> {
  final JustTheController _controller = JustTheController(value: TooltipStatus.isHidden);
  List stickers = ducks + pepeStickers + otherSticker;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(left: 5),
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
        Container(
          width: 30,
          height: 30,
          child: HoverItem(
            colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            child: JustTheTooltip(
              controller: _controller,
              isModal: true,
              preferredDirection: AxisDirection.up,
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
                  // showPopover(
                  //   context: context,
                  //   direction: PopoverDirection.top,
                  //   transitionDuration: const Duration(milliseconds: 50),
                  //   arrowWidth: 0,
                  //   arrowHeight: 0,
                  //   arrowDxOffset: 0,
                  //   shadow: [],
                  //   onPop: (){
                  //   },
                  //   bodyBuilder: (context) => 
                  // );
                }
              ),
            ),
          )
        ),
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
            child: HoverItem(
              colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
              child: Icon(PhosphorIcons.sticker, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
            )
          ),
        )
      ]
    );
  }
}