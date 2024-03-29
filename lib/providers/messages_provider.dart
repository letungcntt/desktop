import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/services/queue.dart';

import '../service_locator.dart';
import 'providers.dart';

class Messages with ChangeNotifier {
  List _data = [];
  bool _isFetching = false;
  int? _lengthData;
  bool _openThread = false;
  Map _parentMessage = {};
  bool _onConversation = false;
  String _messageIdToJump = "";
  Map _messageImage = {};
  bool _isFocusInputThread = false;

  int?  get lenghtData => _lengthData;
  bool get isFetching => _isFetching;
  List get data => _data;
  bool get openThread => _openThread;
  Map get parentMessage => _parentMessage;
  bool get onConversation => _onConversation;
  String get messageIdToJump => _messageIdToJump;
  Map get messageImage => _messageImage;
  bool get isFocusInputThread => _isFocusInputThread;

  setMessageIdToJump(value){
    _messageIdToJump = value;
  }

  setIsFocusThread(bool value) => _isFocusInputThread = value;

  onChangeMessageImage(Map data) {
    _messageImage = data;
    notifyListeners();
  }

  updateReactionParentMessage(reaction) {
    _parentMessage["reactions"] = reaction;
    notifyListeners();
  }

  // default MessageDataChannel
  Map defaultMessagesDataChannel = {
    "messages": [],
    "channelId": "",
    "workspaceId": "",
    "queue": null,
    "isLoadingUp": false,
    "disableLoadingUp": true,
    "isLoadingDown": false,
    "disableLoadingDown": false,
    // truong nay su dung khi nhay den tin nhan va tin nha do khong co trong list
    // mac dinh co gia tri null, khi nhay den message ko co san trong list => 0
    // khi gui tin nhan ma numberNewMessages != null => reset tin nhan ve rong roi nhan tin tiep
    "numberNewMessages": null
  };

  onUpdateMessagesChannele(data){
    _data =_data.map((e){
      if ("${e["workspaceId"]}" != "${data["workspace_id"]}") return e;
      e["messages"] = (e["messages"] as List).map((ele){
        if(ele["user_id"] == data["user_id"]){
          ele["full_name"] = data["nickname"];
          }
          return ele;
        }).toList();
      return e;
    }).toList();
    notifyListeners();
  }


  Future<dynamic> loadMessages(var token, workspaceId, int channelId) async {
    int index = _data.indexWhere((e) => e["channelId"] == channelId);
    if (index == -1) {
      try {
        Map newData = {
          "channelId": channelId,
          "workspaceId": workspaceId,
          "messages": [],
          "queue": Scheduler(),
          "last_current_time": DateTime.now().microsecondsSinceEpoch,
          "latest_current_time": DateTime.now().microsecondsSinceEpoch,
        };
        _data = _data + [{
          ...defaultMessagesDataChannel,
          ...newData
        }];
        await loadMoreMessages(token, workspaceId, channelId);
      } catch (e) {
        print(e);
      }
    } else {
      int index = _data.indexWhere((e) => e["channelId"] == channelId);
      if (index == -1 || _data[index]['numberNewMessages'] != null) return;
      _data[index]["last_current_time"] = DateTime.now().microsecondsSinceEpoch;
      loadMoreMessages(token, workspaceId, channelId, isReset: true);
    }
  }

  replaceNickName(List messages) {
    List members = Provider.of<Workspaces>(Utils.globalContext!, listen: false).members;
    List nickNameMembers = members.where((ele) => Utils.checkedTypeEmpty(ele['nickname'])).toList();

    return messages.map((e) {
      int index = nickNameMembers.indexWhere((user) => user["id"]  == e["user_id"]);
      return {...e,
        "full_name": index == -1 ? e["full_name"] : (nickNameMembers[index]["nickname"] ?? e["full_name"])
      };
    }).toList();
  }

  Future<dynamic> loadMoreMessages(String token, workspaceId, channelId, {bool isNotifi = true, isReset = false}) async {
    int index = _data.indexWhere((e) => e["channelId"] == channelId);
    if (index == -1 || _data[index]["isLoadingDown"] || _data[index]["disableLoadingDown"]) return;
    var currentChannelSelected = _data[index];
    currentChannelSelected["isLoadingDown"] = true;
    if(isNotifi) notifyListeners();
    List data = currentChannelSelected["messages"];
    var lastId  = (data.length == 0 ? "" : data.last["id"]) ?? "";

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?last_id=$lastId&token=$token&is_desktop=true&last_current_time=${currentChannelSelected["last_current_time"]}';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);
      if (responseData["success"] == true) {
        _lengthData = responseData["messages"].length;
        currentChannelSelected["messages"] = sortMessagesByDay(MessageConversationServices.uniqById([] + await MessageConversationServices.processBlockCodeMessage(responseData["messages"])
          + (isReset ? [] : _data[index]["messages"])));
        currentChannelSelected["messages"] = replaceNickName(currentChannelSelected["messages"]);
        currentChannelSelected["disableLoadingDown"] = _lengthData == 0;
        currentChannelSelected["last_current_time"] = _lengthData == 0 ? currentChannelSelected["last_current_time"] : (currentChannelSelected["messages"].last)["current_time"];
      } else {
        currentChannelSelected["disableLoadingDown"] = true;
        throw HttpException(responseData["message"]);
      }

      currentChannelSelected["isLoadingDown"] = false;
    } catch (e, trace) {
      currentChannelSelected["isLoadingDown"] = false;
      print("loadMoreMessages ${e.toString()}, $trace");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    if (isNotifi) notifyListeners();
  }

  sortMessagesByDay(messages) {
    messages = messages.where((e) => e["is_datetime"] == null).toList();
    List listMessages = [];

    for (var i = 0; i < messages.length; i++) {
      try {
        listMessages.add(messages[i]);


        DateTime insertTime = DateTime.fromMicrosecondsSinceEpoch(messages[i]["current_time"]);

        if ((i + 1) < messages.length) {
          var currentDay = DateFormat('MM-dd').format(insertTime);
          var nextday = DateFormat('MM-dd').format(DateTime.fromMicrosecondsSinceEpoch(messages[i +1]["current_time"]));

          if (nextday != currentDay) {
            var stringDay = DateFormat('yyyy-MM-dd – kk:mm').format(insertTime);
            var message = {...messages[i],
              "id": stringDay,
              "key": stringDay,
              "is_system_message": true,
              "attachments": [{"type": "datetime", "value": stringDay, "id": messages[i]["id"]}],
              "message": "",
              "channel_id": messages[i]["channel_id"],
              "workspace_id": messages[i]["workspace_id"],
              "is_datetime": true
            };

            listMessages.add(message);
          }
        }
      } catch (e) {
        continue;
      }
    }

    for (var index = 0; index < listMessages.length; index++) {
      try {
        int length = listMessages.length;
        var isFirst = (index + 1) < length ? ((listMessages[index + 1]["user_id"] != listMessages[index]["user_id"]) || listMessages[index + 1]["is_system_message"] == true) : true;
        var isLast = index == 0  ? true : listMessages[index]["user_id"] != listMessages[index - 1]["user_id"] ;
        bool showNewUser = false;

        if ((index + 1) < length) {
          showNewUser = (listMessages[index + 1]["inserted_at"] == null || listMessages[index]["inserted_at"] == null)
            ? false
            : DateTime.parse(listMessages[index]["inserted_at"]).subtract(Duration(minutes: 10)).compareTo(DateTime.parse(listMessages[index + 1]["inserted_at"])) == 1
              ? true : false;
        }

        var firstMessage = index + 1 < length && listMessages[index + 1]["is_datetime"] != null;
        var isAfterThread = (index + 1) < length ? (((listMessages[index +  1]["count_child"] ?? 0) > 0)) : false;

        listMessages[index]["isFirst"] = isFirst;
        listMessages[index]["isLast"] = isLast;
        listMessages[index]["showNewUser"] = showNewUser;
        listMessages[index]["firstMessage"] = firstMessage;
        listMessages[index]["index"] = index;
        listMessages[index]["isAfterThread"] = isAfterThread;
      } catch (e) {
        continue;
      }
    }

    return listMessages;
  }

  Future<dynamic> newSendMessage(String token, Map message) async {
    var channelId = message["channel_id"];
    var workspaceId = message["workspace_id"];
    var indexChannel  = _data.indexWhere((element) => element["channelId"] == channelId);
    if (message["fromThread"] == true) {
      queueBeforeSend(token, workspaceId, channelId, message);
    } else {
      if (indexChannel == -1) return;
      Scheduler queue = _data[indexChannel]["queue"];
      if (queue.getLength() != 0) message["is_blur"] = true;
      checkNewMessage(message);
      queue.schedule(() {
        return queueBeforeSend(token, workspaceId, channelId, message);
      });
    }
  }

  queueBeforeSend(String token, workspaceId, int channelId, Map message)async{

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token';
    for (var i =0; i < message["attachments"].length; i++){
      if (message["attachments"][i]["uploading"] == true)
      message["attachments"][i]["uploading"] = false;
    }
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(message));
      final responseData = json.decode(response.body);

      if (responseData['success']) {
        // box.delete(message["key"]);
      } else {
        insetMessageErrorToReSend({...message, 'retries': 5});
        message["is_blur"] = true;
        message["success"] = false;
        message["sending"] = false;
        onUpdateChannelMessage(message);
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      insetMessageErrorToReSend({...message, 'retries': 5});
      message["is_blur"] = true;
      message["success"] = false;
      message["sending"] = false;
      onUpdateChannelMessage({...message, 'retries': 5});
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  insetMessageErrorToReSend(Map message) async {
    try {
      var queueBox = Hive.box('queueMessages');
      var oldData = queueBox.get(message["key"]);
      queueBox.put(message["key"],
        {...message, ...(oldData ?? {})}
      );
    } catch (e) {
    }
  }

  checkMentions(message, {bool trim = false}){
    var text = trim ? message.trim() : message;
    RegExp exp = new RegExp(r"={7}[@|#][a-zA-Z0-9-\/\=\_]*\^{5}[\w\d\sÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀẾỂưăạảấầẩẫậắằẳẵặẹẻẽềếểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ.\/+!@&$#%^*()-]*\^{5}[a-zA-Z0-9]{1,}\+{7}");
    RegExp oldExp = new RegExp(r"={7}[@|#][a-zA-Z0-9-\/\=\_]*\^{5}[\w\d\sÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀẾỂưăạảấầẩẫậắằẳẵặẹẻẽềếểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ.\/+!@&$#%^*()-]*\+{7}");
    var matchOld = false;
    var matchs = exp.allMatches(text).toList();
    if (matchs.length == 0){
      matchs = oldExp.allMatches(text).toList();
      matchOld = true;
    }
    if (matchs.length == 0 ) return{
      "success": false,
      "data": text
    };
    else {
      var split = text.split(matchOld ? oldExp : exp);
      var result  = [];
      for(var i = 0; i < split.length; i++) {
        result  += [{
          "type": "text",
          "value": split[i]
        }];

        if (i < matchs.length){
          var message = matchs[i].group(0)!;
          var type = message.contains("=======#") ? "issue" : "user";
          if (type == "issue") {
            var text = (matchs[i].group(0)!.replaceAll("=======#/", "")).replaceAll("+++++++", "");
            var id = text.split("^^^^^")[0];
            var name = text.split("^^^^^")[1];

            result += [{
              "type": type,
              "value": id,
              "trigger": "#",
              "name": name
            }];
          } else {
            var text = (matchs[i].group(0)!.replaceAll("=======@/", "")).replaceAll("+++++++", "");
            var id  = text.split("^^^^^")[0];
            var name = text.split("^^^^^")[1];

            try {
              type = text.split("^^^^^")[2];
            } catch (e) {}
            // trigger hien chi ho tro mention @
            result  += [{
              "type": type,
              "value": id,
              "trigger": "@",
              "name": name
            }];
          }
        }
      }

      for (var i = 0; i < result.length; i++) {
        if (result[i]["type"] == "issue") {
          List list = result[i]["value"].split("-");
          result[i]["id"] = list[0];
          result[i]["workspace_id"] = list[1];
          result[i]["channel_id"] = list[2];
        }
      }

      return {
        "success": true,
        "data": result
      };
    }
  }

  regexMessageBlockCode(string) {
    RegExp exp = new RegExp(r"\`{1}[a-z0-9A-Z\@\s\\!\/\-()&?:}{\[\]\|=^%$#!~*_<>+]{1,7500}\`{1}");
    var matchs = exp.allMatches(string).toList();
    if (matchs.length == 0) {
      return {
        "success": false,
        "data": string
      };
    }
    else {
      var split = string.split(exp);
      var result  = [];
      for(var i = 0; i < split.length; i++){
        result  += [{
          "type": "text",
          "value": split[i]
        }];
        if (i < matchs.length){
          var text  = (matchs[i].group(0)!.replaceAll("`", ""));
          var snippet  = text.split("**")[0];
          result  += [{
          "type": "block_code",
          "value": snippet.trim()
        }];
        }
      }
      return {
        "success": true,
        "data": result
      };
    }
  }

  Future<dynamic> newUpdateChannelMessage(token, message, List files) async {
    if (message["attachments"].length > 0 || message["message"] != "" || files.length > 0) {
      // tai len tat ca cac att chua co content_url
      // attachments = Taast
      var dummyAtts = files.where((element) => element["content_url"] == null && element["mime_type"] != "share").map((e) {
        return {
          "att_id": e["att_id"],
          "name": e["name"],
          "uploading": true,
          "progress": "0"
        };
      }).toList();
      var noDummyAtts = files.where((element) => element["content_url"] != null && element["mime_type"] != "share").toList();
      message["attachments"] = noDummyAtts + (Utils.checkedTypeEmpty(message["attachments"]) ? message["attachments"] + dummyAtts :  [] + dummyAtts);
      onUpdateChannelMessage(message);
      List resultUpload = await Future.wait(
        files.where((element) => element["content_url"] == null && element["mime_type"] != "share").map((item) async{
          final context = Utils.getGlobalContext();
          var uploadFile = await Provider.of<Work>(context, listen: false).getUploadData(item);
          return Provider.of<Work>(context, listen: false).uploadImage(token, message["workspace_id"], uploadFile, uploadFile["type"], (value){
            if (message["isThread"] != null && message["isThread"]) return;
            var index  =  message["attachments"].indexWhere((ele) => ele["att_id"] == item["att_id"]);
            if (index != -1){
               message["attachments"][index]["progress"] = "${(value * 100).round()}";
               onUpdateChannelMessage(message);
            }
          });
        })
      );

      List successAtt = resultUpload.where((element) => element["success"]).toList();
      message["attachments"].removeWhere((ele) => ele["uploading"] == true);
      message["attachments"] += successAtt;
      onUpdateChannelMessage(message);
      queueBeforUpdate(token,  message["workspace_id"],  message["channel_id"], message);
    }
  }

  Future queueBeforUpdate(token, workspaceId, channelId, message) async{
    // remove dummy uploaf file
    for (var i =0; i < message["attachments"].length; i++){
      if (message["attachments"][i]["uploading"] == true)
        message["attachments"][i] = {
          "content_url": message["attachments"][i]["content_url"],
          "name": message["attachments"][i]["name"],
          "mime_type": message["attachments"][i]["mime_type"],
          "image_data": message["attachments"][i]["image_data"],
          "key": message["attachments"][i]["key"],
          "type": message["attachments"][i]["type_file"],
          "url_thumbnail" : message["attachments"][i]["url_thumbnail"]
        };
    }
    try {
      final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/update_message?token=$token';
      var response = await Dio().post(url, data: message);
      var resData = response.data;
      if (resData["success"]){
        message["is_blur"] = false;
        message["success"] = true;
        onUpdateChannelMessage(message);
      }
      else {
        message["is_blur"] = true;
        message["success"] = false;
        onUpdateChannelMessage(message);
      }
      notifyListeners();
    } catch (e) {
      print("errrpr $e");
      message["is_blur"] = true;
      message["success"] = false;
      onUpdateChannelMessage(message);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  onUpdateChannelMessage(dataM) async {
    int channelId = int.parse("${dataM["channel_id"]}");
    final indexChannel = _data.indexWhere((e) => e["channelId"] == channelId);

    if (indexChannel != -1) {
      final messageChannel = _data[indexChannel]["messages"];
      final indexMesasage = messageChannel.indexWhere((e) {
        return e["id"] == dataM["message_id"];
      });

      if (indexMesasage != -1 && Utils.checkedTypeEmpty(dataM["message_id"])) {
        messageChannel[indexMesasage] = Utils.mergeMaps([messageChannel[indexMesasage], dataM]);
      } else {
        if (dataM["key"] == null) return;
        final indexKey = messageChannel.indexWhere((e) {
          return e["key"] == dataM["key"];
        });
        if (indexKey != -1  && Utils.checkedTypeEmpty(dataM["key"])){
          messageChannel[indexKey] = Utils.mergeMaps([messageChannel[indexKey], dataM]);
        }
      }

      _data[indexChannel]["messages"] = sortMessagesByDay(await MessageConversationServices.processBlockCodeMessage(_data[indexChannel]["messages"]));
      notifyListeners();
    }
  }

  onUpdateProfile(data){
    _data =_data.map((e){
      e["messages"] = (e["messages"] as List).map((ele){
        if(ele["user_id"] == data["user_id"]){
          ele["avatar_url"] = data["avatar_url"];
          ele["full_name"] = data["full_name"];
          ele["custom_color"] = data["custom_color"];
        }
        return ele;
      }).toList();
      return e;
    }).toList();
    notifyListeners();
  }

  Future<dynamic> excuteCommand(token, workspaceId, channelId, command) async{
    final url = Utils.apiUrl + 'app/${command["app_id"]}/excute_command?token=$token';
    await Dio().post(url, data: command);
  }

  sendMessageWithImage(List files, Map message, String token) async {
    var channelId = message["channel_id"];
    var indexDataMessageChannel = _data.indexWhere((element) => "${element["channelId"]}" == "$channelId");
    if (indexDataMessageChannel != -1 && _data[indexDataMessageChannel]["numberNewMessages"] != null) resetOneChannelMessage(channelId);
    if (files.length == 0) return newSendMessage(token, message);

    try {
      for(var i = 0; i< files.length; i ++){
        files[i]["att_id"] = Utils.getRandomString(10);
      }
      // doi voi sua tin nhan thi chi upload file chua cos content_url
      var dummyAtts = files.where((element) => element["content_url"] == null).map((e) {
        if (["mp4", "mov"].contains(e["type"].toString().toLowerCase())) e["type"] = 'video';
        return {
          "att_id": e["att_id"],
          "name": e["name"],
          'preview': e['preview'],
          "uploading": true,
          "progress": "0",
          "path_folder": e["path"],
          "type": e["type"],
          "image_data": e["image_data"]
        };
      }).toList();
      message["attachments"] =  Utils.checkedTypeEmpty(message["attachments"]) ? message["attachments"] + dummyAtts :  [] + dummyAtts;
      checkNewMessage(message);
      List resultUpload  =  await Future.wait(
        files.where((element) => element["content_url"] == null).map((item) async{
          final context = Utils.getGlobalContext();
          var uploadFile = await Provider.of<Work>(context, listen: false).getUploadData(item);
          return Provider.of<Work>(context, listen: false).uploadImage(token, message["workspace_id"], uploadFile, uploadFile["type"], (value){});
        })
      );
      List failAtt =  resultUpload.where((element) => !element["success"]).toList();
      List successAtt = resultUpload.where((element) => element["success"]).toList();
      message["attachments"].removeWhere((ele) => ele["uploading"] == true);
      message["attachments"] += successAtt;
      if(message["attachments"].length > 0 || message["message"] != "") newSendMessage(token, message);
      if (failAtt.length > 0) {
        var messagFail = Map.from(message);
        messagFail["key"] = Utils.getRandomString(20);
        messagFail["attachments"] = failAtt;
        messagFail["message"] = "";
        createMessageUploadFail(messagFail);
      }
      if(message["attachments"].length == 0 && message["message"] == ""){
        removeMessageWhenUploadAttFailed(message);
      }
    } catch (e) {
      print("Sfrsef ___ $e");
      message["success"] = false;
      message["is_blur"] = true;
      onUpdateChannelMessage(message);
    }
  }

  removeMessageWhenUploadAttFailed(message){
    try {
      int index = _data.indexWhere((element) => element["channelId"] == message["channel_id"]);
      if (index == -1) return;
      var currentChannelSelected = _data[index];
      currentChannelSelected["messages"] = currentChannelSelected["messages"].where((e) => e["key"] != message["key"]).toList();
    } catch (e) {
    }
  }

  createMessageUploadFail(message){
    int channelId = int.parse("${message["channel_id"]}");
    final indexChannel = _data.indexWhere((e) => e["channelId"] == channelId);
    if (indexChannel != -1) {
      _data[indexChannel]["messages"] = [message] + _data[indexChannel]["messages"];
    }
    notifyListeners();
  }

  setDataDefault(){
    _data = [];
    notifyListeners();
  }

  updateMessage(message) {
    final channelId = message["channel_id"];
    int index = _data.indexWhere((e) => e["channelId"] == channelId);

    final newUser = {
      "message_id": message["id"],
      "user_id": message["user_id"],
      "inserted_at": message["inserted_at"],
      "avatar_url": message["avatar_url"],
      "full_name": message["full_name"]
    };

    if (index != -1) {
      List messages = _data[index]["messages"];
      int indexMessage = messages.indexWhere((e) => e["id"] == message["channel_thread_id"]);

      if (indexMessage != -1) {
        messages[indexMessage]["count_child"] = (messages[indexMessage]["count_child"] ?? 0) + 1;

        if (messages[indexMessage]["info_thread"] != null ) {
          messages[indexMessage]["info_thread"] = [] + [newUser] + messages[indexMessage]["info_thread"];
        } else {
          messages[indexMessage]["info_thread"] = [] + [newUser];
        }

        notifyListeners();
      }
    }
  }

  checkNewMessage(message) async {
    if (message["channel_thread_id"] == null || (message["channel_thread_id"] != null && Utils.checkedTypeEmpty(message["also_send_to_channel"]))) {
      int index = _data.indexWhere((e) => e["channelId"] == message["channel_id"]);

      if (index != -1) {
        Map newMessage = _data[index];
        // new message la dummy
        // cap nhat tin nhawn

        // trong truong hop co nhay den tin nhan cu(numberNewMessage = 0) thi se khong them vao provider, ma chi tang gia tri do len 1;
        // nguoi dung khi click vao numberNewMessage, se reset tin nhan
        if (_data[index]["numberNewMessages"] != null && Utils.checkedTypeEmpty(message["id"])) {
          _data[index]["numberNewMessages"] = _data[index]["numberNewMessages"] + 1;
          notifyListeners();
          return;
        }
        // trong truong hop con lai thi xu ly bt

        var indexKeyId  = newMessage["messages"].indexWhere((ele) => (ele["key"] == message["key"] && Utils.checkedTypeEmpty(ele["key"])));
        if (indexKeyId != -1) {
          newMessage["messages"][indexKeyId] = Utils.mergeMaps([
            newMessage["messages"][indexKeyId],
            message,
            {"is_blur": false, "success": true, "sending": false}
          ]);
          _data[index]["messages"] = sortMessagesByDay(await MessageConversationServices.processBlockCodeMessage(_data[index]["messages"]));
        } else {
          _data[index]["messages"] = sortMessagesByDay(await MessageConversationServices.processBlockCodeMessage([message] + newMessage["messages"]));
        }

        notifyListeners();
      }
    }
  }

  resetStatus(token, context) async {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    if (currentChannel["id"] != null && currentChannel["workspace_id"] != null) {
      _lengthData = 0;
      final channelId = currentChannel["id"];
      final workspaceId = currentChannel["workspace_id"];
      final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token&is_desktop=true';

      try {
        final response = await http.get(Uri.parse(url));
        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          Map newData = {
            "last_current_time": DateTime.now().microsecondsSinceEpoch,
            "latest_current_time": DateTime.now().microsecondsSinceEpoch,
            "channelId": channelId,
            "workspaceId": workspaceId,
            "messages": sortMessagesByDay(await MessageConversationServices.processBlockCodeMessage(responseData["messages"])),
            "queue": Scheduler()
          };
          _data = [{
            ...defaultMessagesDataChannel,

            ...newData
          }];
          _lengthData = responseData["messages"].length;
          notifyListeners();
        } else {
          throw HttpException(responseData['message']);
        }
      } catch (e) {
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  openThreadMessage(value, message) {
    _openThread = value;
    _parentMessage = message;

    notifyListeners();
  }

  changeOpenThread(value) {
    _openThread = value;

    notifyListeners();
  }

  getMentionChannel(text, workspaceId, channelId, token)async {
    final url = "${Utils.apiUrl}workspaces/$workspaceId/channels/$channelId/search_member?text=$text&token=$token";
    try {
      var response  =  await Dio().get(url);
      var resData  = response.data;
      if (resData["success"]) return resData["members"];
      return [];

    } catch (e) {
      print("error $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
      return [];
    }
  }

  openConversation(value) {
    _onConversation = value;
    notifyListeners();
  }

  Future<dynamic> deleteChannelMessage(String token, workspaceId, channelId, messageId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/delete_message?token=$token&message_id=$messageId';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers);
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {

      } else if (responseData['success'] == false) {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  deleteMessage(data) {
    final index = _data.indexWhere((e) => e["channelId"] == data["channel_id"]);
    if (index == -1) return;

    final messages = _data[index]["messages"];

    if (data["channel_thread_id"] == null) {
      final indexMessage = messages.indexWhere((e) => e["id"] == data["message_id"]);

      if (indexMessage != -1) {
        messages.removeAt(indexMessage);
        _data[index]["messages"] = sortMessagesByDay(messages.where((e) => (e["id"] ?? []).length != 10).toList());

        if (data["message_id"] == parentMessage["id"]) {
          openThreadMessage(false, {});
        }
        notifyListeners();
      }
    } else {
      final indexMessage = messages.indexWhere((e) => e["id"] == data["channel_thread_id"]);
      if (indexMessage != -1) {
        final indexInfo = messages[indexMessage]["info_thread"].indexWhere((e) => e["message_id"] == data["message_id"]);
        if (indexInfo != -1) {
          messages[indexMessage]["info_thread"].removeAt(indexInfo);
        }
        messages[indexMessage]["count_child"] = messages[indexMessage]["count_child"] - 1;
        notifyListeners();
      }
    }
  }

  reactionChannelMessage(data){
    final index = _data.indexWhere((e) => "${e["channelId"]}" == "${data["reactions"]["channel_id"]}");
    if (index != -1) {
      final indexMessage = _data[index]["messages"].indexWhere((e) => e["id"] == data["reactions"]["message_id"]);

      if (indexMessage != -1) {
        _data[index]["messages"][indexMessage]["reactions"] = MessageConversationServices.processReaction(data["reactions"]["reactions"]);
        notifyListeners();
      }
    }
  }

  handleReactionMessage(Map obj) async{
    String url  = "${Utils.apiUrl}workspaces/${obj["workspace_id"]}/channels/${obj["channel_id"]}/messages/handle_reaction_message?token=${obj["token"]}";
    var response = await Dio().post(url, data: obj);
    var dataRes = response.data;

    if (dataRes["success"]){
      // update
      final index = _data.indexWhere((e) => e["channelId"] == obj["channel_id"]);
      if (index != -1) {
        final indexMessage = _data[index]["messages"].indexWhere((e) => e["id"] == obj["message_id"]);
        if (indexMessage != -1) {
          _data[index]["messages"][indexMessage]["reactions"] = MessageConversationServices.processReaction(dataRes["reactions"]);
          notifyListeners();
        }
      }
    }
  }

  //  ham nay chi su dung khi  numberNewMessages != null va app dung khi gui tin nhan()
  resetOneChannelMessage(int channelId){
    final BuildContext context = Utils.globalContext!;
    final auth = Provider.of<Auth>(context, listen: false);
    int index = _data.indexWhere((e) => "${e["channelId"]}" == "$channelId");
    if (index == -1) return;
    _data[index] = {
      ..._data[index],
      "messages": [],
      "numberNewMessages": null,
      "isLoadingUp": false,
      "disableLoadingUp": true,
      "isLoadingDown": false,
      "disableLoadingDown": false,
      "last_current_time": DateTime.now().microsecondsSinceEpoch,
      "latest_current_time": DateTime.now().microsecondsSinceEpoch,
    };

    loadMoreMessages(auth.token, _data[index]['workspaceId'], channelId);
  }

  getMessageChannelUp(String token, int channelId, int workspaceId,  {bool isNotifyListeners = false, bool callApi = false, int limit = 10}) async {
    // lay 15 tin moi hon tin dc chon(bao gom ca tin dc chon)
    int indexChannelDataMessage = _data.indexWhere((element) => element["channelId"] == channelId);
    if (indexChannelDataMessage == -1 ) return;
    var currentChannelSelected = _data[indexChannelDataMessage];
    if ((currentChannelSelected["disableLoadingUp"] || currentChannelSelected["isLoadingUp"]) && !callApi) return;
    currentChannelSelected["isLoadingUp"] = true;
    if(isNotifyListeners) notifyListeners();
    int latestCurrentTime = currentChannelSelected["latest_current_time"];
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token&limit=$limit&latest_current_time=$latestCurrentTime';
      // print(url);
      try {
        final response = await http.get(Uri.parse(url));
        final responseData = json.decode(response.body);
        if (responseData["success"] == true) {
          currentChannelSelected["messages"] = sortMessagesByDay(MessageConversationServices.uniqById([] + _data[indexChannelDataMessage]["messages"] + await MessageConversationServices.processBlockCodeMessage(responseData["messages"])));
          currentChannelSelected["messages"] = replaceNickName(currentChannelSelected["messages"]);

          currentChannelSelected["latest_current_time"] = currentChannelSelected["messages"].length <= 1 ? currentChannelSelected["latest_current_time"] : (currentChannelSelected["messages"].first)["current_time"];
          bool hasLoadEnded = responseData["messages"].where((ele) => ele["current_time"] != latestCurrentTime).toList().length < (limit - 1);
          currentChannelSelected["disableLoadingUp"] = hasLoadEnded;
          currentChannelSelected["numberNewMessages"] = hasLoadEnded ? null : currentChannelSelected["numberNewMessages"];
          if (isNotifyListeners) notifyListeners();
        } else {
          throw HttpException(responseData["message"]);
        }
        currentChannelSelected["isLoadingUp"] = false;

      } catch (e) {
        currentChannelSelected["isLoadingUp"] = false;
        currentChannelSelected["disableLoadingUp"] = true;
        print("handleProcessMessageToJump $e");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
  }

  // xu ly tin nhan de nhay den
  handleProcessMessageToJump(Map message, BuildContext? oldContext) async {
    // oldContext se bi thay the = Utils.globalContext;
    BuildContext? context = Utils.globalContext;
    if (context == null) return;
    final auth = Provider.of<Auth>(context, listen: false);
    String token = auth.token;
    int workspaceId = message["workspace_id"] ?? message["workspaceId"];
    int channelId = message["channel_id"] ?? message["channelId"];
    var indexChannelDataMessage = _data.indexWhere((element) => "${element["channelId"]}" == "$channelId");

    if (indexChannelDataMessage == -1 ) {
      _data = [] + _data + [{
        ...defaultMessagesDataChannel,
        "queue": Scheduler(),
        "channelId": channelId,
        "workspaceId": workspaceId,
        "numberNewMessages": 0,
        "disableLoadingUp": false,
        "latest_current_time": message["current_time"],
        "last_current_time": message["current_time"],
      }];
      indexChannelDataMessage = _data.length -1;
    } else {
      _data[indexChannelDataMessage] = {
        ..._data[indexChannelDataMessage],
        "numberNewMessages": 0,
        "messages": [],
        "latest_current_time": message["current_time"],
        "last_current_time": message["current_time"],
      };
    }
    notifyListeners();
    // neu message nhay den chua co
    // + Reset tat tin nhan ve mac dinh
    // goi api load 2 chieu tinh tu message jump
    // cap nhat numberNewMessages 0
    // new co tin nhan moi,
    // scroll xuong den khi nao khong the load moi dc nua
    // hoac click vao tin moi => reset lai hoi thoai
    // neu gui tin moi => reset lai hoi thoai
    // viec nhay den tin nhan do view hien thi dam nhan
    //
    _messageIdToJump = message["id"];
    Future getDown() async{
      await loadMoreMessages(token, workspaceId, channelId, isNotifi: false);
    }

    Future getUp() async{
      await getMessageChannelUp(token, channelId, workspaceId, limit: 5);
    }

    _data[indexChannelDataMessage] = {
      ...defaultMessagesDataChannel,
      ..._data[indexChannelDataMessage],
      "messages": [],
      "numberNewMessages": 0,
      "isLoadingUp": false,
      "disableLoadingUp": false,
    };

    await Future.wait([
      getDown(),
      getUp(),
      // Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, workspaceId, context)
    ]);
    // set
    //current_channel (Channel)
    //current_workspace, currentTab (Workspace)
    //selectedTab (User)

    Provider.of<Workspaces>(context, listen: false).onSelectWorkspace(context, workspaceId);
    Provider.of<Channels>(context, listen: false).onSelectedChannel(workspaceId, channelId, auth, this);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);

    Provider.of<User>(context, listen: false).selectTab("channel");

    clearMessageIdToJump();
  }

  clearMessageIdToJump()async{
    // Timeout de xoa messageIdToJump;
    await Future.delayed(Duration(seconds: 10));
    _messageIdToJump = "";
    notifyListeners();
  }

  onSubmitPoll(token, workspaceId, channelId, messageId, selected, added, removed) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/submit_poll?token=$token';

    try {
      var response = await Dio().post(url, data: {'removed': removed, 'selected': selected, 'added': added, 'message_id': messageId});
      var resData = response.data;
      if (resData["success"] == true) {

      } else {
        throw HttpException("submit poll error");
      }
    } catch (e) {
      print(e.toString());
    }
  }

  updatePollStatus(token, workspaceId, channelId, messageId, attachments) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/update_poll_status?token=$token';

    try {
      var response = await Dio().post(url, data: {'attachments': attachments, 'message_id': messageId});
      var resData = response.data;
      sl.get<Auth>().showAlertMessage(resData['message'], !resData['success']);
    } catch (e) {
      sl.get<Auth>().showAlertMessage("update poll status failed", true);
      print(e.toString());
    }
  }

  updatePollMessage(payload) async {
    final message = payload["message"];
    final index = _data.indexWhere((e) => "${e["channelId"]}" == "${message["channel_id"]}");
    if (index != -1) {
      final int indexMessage = _data[index]["messages"].indexWhere((e) => e["id"] == message["id"]);

      if (indexMessage != -1) {
        List messages = _data[index]["messages"];
        messages[indexMessage]["attachments"] = message["attachments"];
        messages[indexMessage]["current_time"] = message["current_time"];

        if(indexMessage != messages.length - 1 && indexMessage != 0) {
          if(messages[indexMessage - 1]["attachments"].isNotEmpty && messages[indexMessage +  1]["attachments"].isNotEmpty) {
            bool shouldRemoveDate = messages[indexMessage - 1]["attachments"][0]["type"] == "datetime" && messages[indexMessage + 1]["attachments"][0]["type"] == "datetime";

            if(shouldRemoveDate) {
              messages.removeAt(indexMessage + 1);
            }
          }
        }

        (_data[index]["messages"] as List).sort((a, b) => (b["current_time"] ?? 0).compareTo((a["current_time"] ?? 0)));
        notifyListeners();
      }
    }
  }
}
