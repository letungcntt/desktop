import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/dataSourceEmoji.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:encrypt/encrypt.dart' as En;
import 'package:googleapis/drive/v3.dart' as gdrive;
import 'package:crypto/crypto.dart';
import 'package:workcake/models/models.dart';
import '../../data_channel_webrtc/device_socket.dart';
import '../../media_conversation/drive_api.dart';
import '../../media_conversation/model.dart';
import 'message_conversation.dart';


// IOS dang bi loi isar
// IOS se tiep dung dung Hive, ko co tinh nang search
// ko co tinh nang load message from hive khi mat ket noi
// se dung Hive den khi nao isar ho tro

class MessageConversationServices{
  
  static var isar;
  static bool isBackUping = false;
  static var _statusBackUpController = StreamController<StatusBackUp>.broadcast(sync: false);
  static Stream<StatusBackUp> get statusBackUp => _statusBackUpController.stream;

  static bool isRestoring = false;
  static var _statusRestoreController = StreamController<StatusRestore>.broadcast(sync: false);
  static Stream<StatusRestore> get statusRestore => _statusRestoreController.stream;
// ham nay bi bo do cac thiet bi da chay v2
  static moveMessageFromHive(List listConversations)async {
  }

  static Future<MessageConversation?> processJsonMessage(Map data, {bool moveFromHive = false, List listConversations = const []}) async {
    try {
      if (!Utils.checkedTypeEmpty(data["id"]) || !Utils.checkedTypeEmpty(data["conversation_id"])) throw {};
      return MessageConversation()
        ..attachments = parseListString(data["attachments"] ?? [])
        ..message = data["message"]
        ..messageParse = await parseStringAtt(data)
        ..conversationId = getNewConversationId(data["conversation_id"] ?? "", [])
        ..success = data["success"] ?? true
        ..count = data["count"] ?? 0
        ..fakeId = data["fake_id"]
        ..insertedAt = data["time_create"] ?? ""
        ..isBlur = data["is_blur"] ?? false
        ..isSystemMessage = data["is_system_message"] ?? false
        ..parentId = data["parent_id"] ?? ""
        ..publicKeySender = data["public_key_sender"]
        ..sending = data["sending"] ?? false
        ..currentTime =  data["current_time"] ?? 100000
        ..dataRead = []
        ..id = data["id"] ?? ""
        ..userId = data["user_id"] ?? ""
        ..infoThread = parseListString(data["info_thread"])
        ..localId = data["local_id"] ?? (data["current_time"] % 100000000000000)   
        ..lastEditedAt = data["last_edited_at"] ?? ""
        ..action = data["action"] ?? "insert";
    } catch (e) {
      print("data ____ $data  $e");
      print("e: $e");
      return null;
    }


  }

  static String getNewConversationId(String id, List dataConversationIds){
    var index = dataConversationIds.indexWhere((element) => element["old_id"] == id);
    if (index == -1) return id;
    return dataConversationIds[index]["conversation_id"];
  }

  static Future<String> parseStringAtt(Map data)async{
    String result = data["message"] ?? "";
    List atts = data["attachments"] ?? [];
    for (Map att in atts){
      switch (att["type"]) {
        case "mention":
          for (Map mention in att["data"]){
            switch (mention["type"]) {
              case "all":
                result += "@all";
                break;
              case "text":
                  result += mention["value"];
                break;
              default:
                try {
                  Box directBox = await Hive.openBox('direct');
                  DirectModel dm = directBox.values.firstWhere((element) => element.id == data["conversation_id"]);
                  var user  =  dm.user.firstWhere((element) => element["user_id"] == mention["value"]);
                  result += "@" + (user["full_name"] ?? user["name"] ?? "");
                } catch (e) {
                }
            }
          }
          break;
        default:
      }
    }
    return unSignVietnamese(result.trim());
  }

  static unSignVietnamese(String text){
    final _vietnamese = 'aAeEoOuUiIdDyY';
    final _vietnameseRegex = <RegExp>[
      RegExp(r'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ'),
      RegExp(r'À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ'),
      RegExp(r'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ'),
      RegExp(r'È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ'),
      RegExp(r'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ'),
      RegExp(r'Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ'),
      RegExp(r'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ'),
      RegExp(r'Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ'),
      RegExp(r'ì|í|ị|ỉ|ĩ'),
      RegExp(r'Ì|Í|Ị|Ỉ|Ĩ'),
      RegExp(r'đ'),
      RegExp(r'Đ'),
      RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'),
      RegExp(r'Ỳ|Ý|Ỵ|Ỷ|Ỹ')
    ];

    var result = text;
    for (var i = 0; i < _vietnamese.length; ++i) {
      result = result.replaceAll(_vietnameseRegex[i], _vietnamese[i]);
    }
    return result.toLowerCase();
  }

  static List<String> parseListString(List? data){
    if (data == null) return [];
    return data.map((e) => jsonEncode(e)).toList();
  }

  static getTimeKey(key) {
    try {        
      var tkey = key.toString().split("__")[0];
      return DateTime.parse(tkey).toUtc().millisecondsSinceEpoch;
    } catch (e) {
      return 0;
    }
  }

  static getMessageFromHive(idDirectMessage, int page, int size) async{
    var directMessageBox = Hive.lazyBox("direct_$idDirectMessage");
    var dataKey = directMessageBox.keys.toList();
    var r = dataKey;
    r.sort((a, b) {
      return getTimeKey(a) < getTimeKey(b) ? -1 : 1;
    });
    var listkeyMessage = r;
    var length = listkeyMessage.length;
    var start = length - page *size;
    var end = start - size;
    if (start < 0) start = 0;
    if (end < 0) end = 0;
    var listKeys = listkeyMessage.sublist(end, start);
    var dataR = [];
     for (var i = 0; i < listKeys.length; i++) {
      // return unix to iso string;
      var key = listKeys[i];
      dataR = [await directMessageBox.get(key)] + dataR;
    }
    return dataR;
  }

  static getNameOfConverastion(String convId, List sources){
    var index  =  sources.indexWhere((element) => element.id  == convId);
    if (index == -1) return "";
    return sources[index].name ?? sources[index].user.reduce((value, element) => "$value ${element["full_name"]}");
  }

  static Future<List> getFromHive(idConversation,int page,int size)async {
    LazyBox thread =  await Hive.openLazyBox("thread_$idConversation");
    List keys = thread.keys.toList();
    List result  = [];
    for (var i = size * page ; i < min(keys.length, size * (page +1)); i++){
      if (keys[i] != null)
        result +=[await thread.get(keys[i])];
    }
    return result;
  }

  static List<Map> parseListStringToListMap(List<String>? data){
    if (data == null) return [];
    return data.map((e) => jsonDecode(e) as Map).toList();
  }

  static Map parseMessageToJson(MessageConversation message){
    return {
      "attachments": parseListStringToListMap(message.attachments),
      "local_id": message.localId,
      "message": message.message ?? "",
      "conversation_id": message.conversationId ?? "",
      "success": message.success ?? true,
      "count": message.count ?? 0,
      "fake_id": message.fakeId ?? "",
      "time_create": DateTime.fromMicrosecondsSinceEpoch(message.currentTime ?? 0, isUtc: true).toString(),
      "is_blur": message.isBlur ?? false,
      "is_system_message": message.isSystemMessage ?? false,
      "parent_id": message.parentId ?? "",
      "public_key_sender": message.publicKeySender ?? "",
      "sending": message.sending ?? false,
      "current_time": message.currentTime ?? 0,
      "data_read": parseListStringToListMap(message.dataRead),
      "info_thread": parseListStringToListMap(message.infoThread),
      "id": message.id ?? "",
      "user_id": message.userId ?? "",
      "last_edited_at": message.lastEditedAt ?? "",
      "action": message.action ?? "insert",
    };
  }

  static Future<List> searchMessage(String text, {int limit = 10, int offset = 0, bool parseJson = false}) async {
    if (Platform.isLinux ) return [];
    Isar isar = await getIsar();
    // var m  =  DateTime.now().microsecondsSinceEpoch;
    List<MessageConversation> dataIsar = await isar
      .messageConversations
      .where()
      .filter()
      .messageParseContains(unSignVietnamese(text))
      // .messageParseWordStartsWith(unSignVietnamese(text))
      .sortByCurrentTimeDesc()
      .distinctById()
      // .messageParseWordEqualTo(text)
      .offset(offset)
      .limit(limit)
      .findAll();
      // print(data);
    // print("DateTime.now().microsecondsSinceEpoch : ${DateTime.now().microsecondsSinceEpoch -m}  ${data.length}");
    List uniqIds = dataIsar.map((e) => e.id).toSet().toList();
    List<MessageConversation> data = uniqIds.map((e) => dataIsar.firstWhere((element) => element.id == e)).toList();
    if (parseJson){
      return data.map((e) => parseMessageToJson(e)).toList();
    }
    return data;
  }

  static Future<List> getMessageDown(String conversationId, int deleteTime, {int currentTime = 0, int limit = 10, int offset = 0, bool parseJson = false, bool isParentMessage = true}) async {
    var boxDm = Hive.box("direct");
    DirectModel? dm  = boxDm.get(conversationId);
    if (dm == null || deleteTime >= currentTime || currentTime == 0) return [];
    try {
      Isar isar = await getIsar();
      // print("currentTime $currentTime   $conversationId");
      List<MessageConversation> dataIsar = await isar
        .messageConversations
        .where()
        .parentIdConversationIdEqualTo("", conversationId)
        .filter()
        .currentTimeBetween(deleteTime, currentTime)
        .sortByCurrentTimeDesc()
        .distinctById()
        .optional(offset > -1, (m) => m.offset(offset))
        .limit(limit)
        .findAll();
      dataIsar = dataIsar.where((element) => element.currentTime != deleteTime && element.currentTime != currentTime).toList();
      // lay thong tin thread
      // print("DateTime.now().microsecondsSinceEpoch  $currentTime :${data.length} ${DateTime.now().microsecondsSinceEpoch -m}");
      if (parseJson) {
        List result = dataIsar.map((e) => parseMessageToJson(e)).toList();
        return await Future.wait(result.map((e) async{
          return await loadInfoThreadMessage(dm, e);
        }));
      }
      return dataIsar;
    } catch (e) {
      print("getMessageDown $e");
      return [];
    }
  }

  static getUserInfoMessage(DirectModel dm, Map message){
    var indexUser = dm.user.indexWhere((element) => element["user_id"] == message["user_id"]);
    Map ui = {};
    if (indexUser != -1) ui = {
      "full_name": dm.user[indexUser]["full_name"],
      "avatar_url": dm.user[indexUser]["avatar_url"]
    };
    return {
      ...message,
      ...ui
    };
  }

  static Future<Map> loadInfoThreadMessage(DirectModel dm, Map message)async{
    List threads = await getMessageThreadAll(dm.id, message["id"], parseJson: true);
    return {
      ...(getUserInfoMessage(dm, message)),
      "info_thread": threads
    };
  }

  static Future<List> getMessageToTranfer( { int limit = 30, int offset = -1, bool parseJson = false}) async {
    if (Platform.isLinux ) return [];
    try {
      Isar isar = await getIsar();
      List<MessageConversation> data = await isar
        .messageConversations
        .where()
        .sortByCurrentTimeDesc()
        .distinctById()
        .optional(offset > -1, (m) => m.offset(offset))
        .limit(limit)
        .findAll();
      if (parseJson)
        return data.map((e) => parseMessageToJson(e)).toList(); 
      return data;
    } catch (e) {
      print("getMessageToTranfer $e");
      return [];
    }

  }

  static Future<List> getMessageThreadAll(String conversationId, String parentId, { bool parseJson = false}) async {
    var boxDm = Hive.box("direct");
    DirectModel dm  = boxDm.get(conversationId);
    if (Platform.isLinux ) return [];
    try {
      Isar isar = await getIsar();
      List<MessageConversation> data = await isar
        .messageConversations
        .where()
        .filter()
        .parentIdEqualTo(parentId)
        .sortByCurrentTimeDesc()
        .distinctById()
        .findAll();
      if (parseJson)
        return data.map((e) => getUserInfoMessage(dm, parseMessageToJson(e))).toList();
      return data;
    } catch (e){
      print("getMessageThreadAll $e");
      return [];
    }
  }

  static Future<List> getMessageUp(String conversationId, int deleteTime, {int currentTime = 0, int limit = 10, int offset = -1, bool parseJson = false}) async {
    var boxDm = Hive.box("direct");
    DirectModel dm  = boxDm.get(conversationId);
    int timeGreater = deleteTime >= currentTime ? deleteTime : currentTime;

    try {
      Isar isar = await getIsar();
      List<MessageConversation> data = await isar
        .messageConversations
        .where()
        .filter()
        .conversationIdEqualTo(conversationId)
        .and()
        .parentIdEqualTo("")
        .currentTimeGreaterThan(timeGreater)
        .or()
        .currentTimeEqualTo(timeGreater)
        .sortByCurrentTime()
        .distinctById()
        .optional(offset > -1, (m) => m.offset(offset))
        .limit(limit)
        .findAll();
      if (parseJson) {
        List result = data.map((e) => parseMessageToJson(e)).toList();
        return await Future.wait(result.map((e) async{
          return await loadInfoThreadMessage(dm, e);
        }));
      }
      return data;
    } catch (e){
      // print("getMessageUp  $e");
      return [];
    }
  }

  static Future<List> getListMessageByIds(List<String> ids, {bool parseJson = false}) async {
    if (Platform.isLinux ) return [];
    try {
      Isar isar = await getIsar();
      List<MessageConversation> data = await isar
        .messageConversations
        .where()
        .filter()
        .repeat(ids, (q, String id) => q.idEqualTo(id))
        .sortByCurrentTime()
        .findAll();

      if (parseJson) 
        return data.map((e) => parseMessageToJson(e)).toList(); 
      return data;
    } catch (e) {
      // print("getListMessageByIds: $e");
      return [];
    }
  }

  static Future<Map?> getListMessageById(String id, String conversationId) async {
    var boxDm = Hive.box("direct");
    // print("conversationId: $conversationId");
    DirectModel? dm  = boxDm.get(conversationId);
    if (dm == null) return null;
    try {
      Isar isar = await getIsar();
      MessageConversation? data = await isar
        .messageConversations.where()
        .filter()
        .idContains(id)
        // .and()
        // .conversationIdEqualTo(conversationId)
        // .and()
        // .parentIdEqualTo("")
        // .and()
        // .parentIdEqualTo("")
        // .idEqualTo(id)
        // .optional(id != "", (q) => q.idEqualTo(id))
        // .optional(id == "", (q) => q.filter().conversationIdEqualTo(conversationId))
        .sortByCurrentTimeDesc()
        .findFirst();

        // print("$id $data");
      if (data == null) data = await isar.messageConversations.where().parentIdEqualTo(conversationId).sortByCurrentTimeDesc().findFirst();
      if (data == null) return null;
      return loadInfoThreadMessage(dm, parseMessageToJson(data));      
    } catch (e){
      // print("getListMessageById $e");
      return null;
    }

  }

  static Future<List<String>> insertOrUpdateMessage(Map message, {String type = "insert"}) async {
    if (message["message"] == "" && message["attachments"].length == 0 && message["action"] == "insert")  return [];
    if (Platform.isLinux ) {
      await insertHiveOnIOS(message);
      return []; 
    }
    try {
      Isar isar = await getIsar();
      MessageConversation? dataInsert;
      if (type == "insert"){
        dataInsert = await processJsonMessage(message);
      } else {
        var messageExisted =  await isar.messageConversations.where().filter().idContains(message["id"]).findFirst();
        if (messageExisted == null) return [];
        dataInsert = await processJsonMessage({
          ...(parseMessageToJson(messageExisted)),
          ...message
        });
      }
      if (dataInsert == null) return [];
      await isar.writeTxn((isar) async => 
        await isar.messageConversations.put(dataInsert!)
      );  
      return [message["id"]];  
    } catch (e) {
      print("insertOrUpdateMessage $e");
      return [];
    }
  }

  static Future<bool> insertHiveOnIOS(Map message) async {
    try {
      // id la id cua message
      var boxIOS = Hive.lazyBox("messageConversation");
      await boxIOS.put(message["id"], message);    
      return true;  
    } catch (e) {
      return false;
    }
  }

  static Future<bool> insertHiveOnIOSMany(List messages) async {
    try {
      var result = {};
      for(var m in messages){
        result[m["id"]] = m;
      }
      var boxIOS = Hive.lazyBox("messageConversation");
      await boxIOS.putAll(result);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> insertOrUpdateMessages(List messages, {bool moveFromHive = false}) async {
    if (Platform.isLinux ) {
      await insertHiveOnIOSMany(messages);
      return[];
    }
    try {
      Isar isar = await getIsar();
      List<String> successIds = [];
      await isar.writeTxn((isar) async {
        try {
          List<MessageConversation?> dataInsert = await Future.wait(messages.map((e) => processJsonMessage(e, moveFromHive: moveFromHive)));
          List<MessageConversation> many = dataInsert.whereType<MessageConversation>().toList();
          await isar.messageConversations.putAll(many);
          successIds = many.map((e) => e.id).toList().whereType<String>().toList();         
        } catch (e) {
          print("+++++++ $e");
        }

      });
      return successIds;
    } catch (e) {
      print(">>>> insert fail");
      return [];
    }
  }

  static Future<int> getTotalMessage()async{
    if (Platform.isLinux ) return 0;
    Isar isar = await getIsar();
    return isar.messageConversations.where().distinctById().count();
  }

  static Future<Isar> getIsar() async{
    if (isar != null) return isar; 
    var newDir = await getApplicationSupportDirectory();
    var newPath = newDir.path + "/pancake_chat_data_v3";
    isar = await Isar.open(
      schemas: [MessageConversationSchema], 
      directory: newPath,
      inspector: true,
    );
    return isar;
  }

  static List uniqById(List dataSource,  {bool isRemoveDeteforMe = true}){
    // uniq tren id vaf fake_id
    List results = [];
    Map index = {};
    for (var i in dataSource){
      // if (!Utils.checkedTypeEmpty(i["id"] && success)
      var key = Utils.checkedTypeEmpty(i["id"]) ? i["id"] : Utils.checkedTypeEmpty(i["fake_id"]) ? i["fake_id"] : "";
      if ( !Utils.checkedTypeEmpty(key)) continue;
      if (isRemoveDeteforMe &&  i["action"] == "delete_for_me") continue;
      if (index[key] == null){
         results += [i];
         index[key] = results.length -1;
      } else {
        results[index[key]] = Utils.mergeMaps([results[index[key]], i]);
      }
    }
    if (results.length <= 1) return results;
    results.sort((a,  b) => (b["current_time"] ?? ((DateTime.parse(b["inserted_at"] ?? b["time_create"])).toUtc().microsecondsSinceEpoch) ?? 0)
    .compareTo((a["current_time"] ?? ((DateTime.parse(a["inserted_at"] ?? a["time_create"])).toUtc().microsecondsSinceEpoch) ?? 0))); 
    return results;    
  }

  static List processMessageConversationByDay(List dataMessages, DirectModel dataDirectMessage){
    List messages = uniqById(dataMessages);
    // messages la list cac tin nhan lay tu isar/api, dc sap xep theo thu tu tu cu -> moi
    // dau ra la list co dang, thoi gian dc sap xep theo thu tu moi -> cu
    //    [
    //      {"dataTime": "", "messages": []}
    //    ]
    bool showNewUser = false;
    if (messages.length  == 0 ) return [];
    int length = messages.length;
    List results = [];
    for(int index = 0; index < length; index++){
      try {
        // set = true khi do la tin nhan dau tien hoac datetime khac voi tin  nhan truoc do
        bool isShowDate = index == 0;
        DateTime dateTime = DateTime.parse(messages[index]["inserted_at"] ?? messages[index]["time_create"]);
        var isAfterThread = (index + 1) < (length)
          ? (((messages[index + 1]["count"] ?? 0) > 0))
          : true;
        List attachments =  messages[index]["attachments"] != null && messages[index]["attachments"].length > 0
          ? messages[index]["attachments"]
          : [];
        String fullName = "";
        String avatarUrl = "";
        var u = dataDirectMessage.user.where((element) => element["user_id"] == messages[index]["user_id"]).toList();
        if (u.length > 0) {
          fullName = u[0]["full_name"];
          avatarUrl = u[0]["avatar_url"] ?? "";
        }
        var isFirst = (index + 1) < length
          ? ((messages[index + 1]["user_id"] != messages[index]["user_id"]))
          : true;
        var isLast= index == 0  ? true : messages[index]["user_id"] != messages[index - 1]["user_id"] ;
        if (index >= 1){
          DateTime prevDateTime = DateTime.parse(messages[index - 1]["inserted_at"] ?? messages[index - 1]["time_create"]);  
          // print("${dateTime.day }  / ${dateTime.month }  / ${dateTime.year } -----  ${prevDateTime.day }  / ${prevDateTime.month }  / ${prevDateTime.year }");
          isShowDate = dateTime.day != prevDateTime.day || dateTime.month != prevDateTime.month ||  dateTime.year != prevDateTime.year;
        }
        if ((index + 1) < (length)) {
          showNewUser = (messages[index + 1]["current_time"] - messages[index]["current_time"]).abs() < 600000000;
        }
        var currentMessage = Utils.mergeMaps([
          messages[index],
          {
            "isAfterThread": isAfterThread,
            "attachments": attachments,
            "fullName": fullName,
            "avatarUrl": avatarUrl,
            "isFirst": isFirst,
            "isLast": isLast,
            "showNewUser": !showNewUser
          }
        ]);

        // print("isShowDate __ ${isShowDate}");
        if (isShowDate){
          results += [{
            "key": index,
            "dateTime": dateTime,
            "messages": [currentMessage],
          }];
        } else {
          results[results.length - 1]["messages"] = [Utils.mergeMaps([
              messages[index],
              currentMessage
            ])] + results[results.length - 1]["messages"];
        }
      } catch (e) {
        // print("$e   ${messages[index]}");
      }

    }

    // print(results.reversed.toList());
    return results.reversed.toList();
  }


  static List processMessageChannelByDay(List dataSource){
    List messages = dataSource.map((mes) => Utils.mergeMaps([
      mes, 
      {
        "current_time": (DateTime.parse(mes["inserted_at"] ?? mes["time_create"])).toUtc().millisecondsSinceEpoch
      }
    ])).toList();
    // messages la list cac tin nhan lay tu isar/api, dc sap xep theo thu tu tu cu -> moi
    // dau ra la list co dang, thoi gian dc sap xep theo thu tu moi -> cu

    if (messages.length  == 0 ) return [];
    if (messages.length > 1){
      messages.sort((a,  b) => (b["current_time"] ?? 0).compareTo((a["current_time"] ?? 0)));    
    }

    int length = messages.length;
    List results = [];
    for(int index = 0; index < length; index++){
      // set = true khi do la tin nhan dau tien hoac datetime khac voi tin  nhan truoc do
      bool isShowDate = index == 0;
      var e = messages[index];
      DateTime dateTime = DateTime.parse(e["inserted_at"] ?? e["time_create"]);
      var timeStamp = dateTime.toUtc().millisecondsSinceEpoch;
      bool showNewUser = false;

      if (index > 0) {
        DateTime nextTime = DateTime.parse(messages[index - 1]["inserted_at"] ?? messages[index - 1]["time_create"]);
        isShowDate = dateTime.day != nextTime.day || dateTime.month != nextTime.month ||  dateTime.year != nextTime.year;
      }

      if ((index + 1) < (length)) {
        showNewUser = (messages[index]["current_time"] - messages[index + 1]["current_time"]) < 600000;
      }

      var isFirst = (index + 1) < length
        ? ((messages[index + 1]["user_id"] != messages[index]["user_id"]) || messages[index + 1]["is_system_message"])
        : true;
      var isLast= index == 0  ? true : messages[index]["user_id"] != messages[index - 1]["user_id"] ;
      var currentMessage = Utils.mergeMaps([
        messages[index],
        {
          "isChildMessage": false,
          "isFirst": isFirst,
          "isLast": isLast,
          "showNewUser": !showNewUser,
          "current_time": timeStamp,
          "isAfterThread": false
        }
      ]);

      if (isShowDate){
        results += [{
          "dateTime": dateTime,
          "messages": [currentMessage],
        }];
      } else {
        if (results.length > 0)
          results[results.length - 1]["messages"]= [Utils.mergeMaps([
              messages[index],
              currentMessage
            ])] + results[results.length - 1]["messages"];
      }
    }
    return results.reversed.toList();
  }

  static processReaction(List listDataSource){
    List reactions =listDataSource; 
    List resultEmoji = [];
    List totalDataSource = [] + dataSourceEmojis;
    for (int i = 0; i < reactions.length; i++) {
      // check them truong hop da xu ly reactions t
      if (reactions[i]["emoji"] != null) {
        resultEmoji += [reactions[i]];
        continue;
      }
      int indexR = resultEmoji.indexWhere((element) => (element["emoji"] as ItemEmoji).id == reactions[i]["emoji_id"]);
      int indexReactEmoji = totalDataSource.indexWhere((emo) {
        return (emo["id"] ?? emo["emoji_id"]) == reactions[i]["emoji_id"];
      });
      if (indexReactEmoji == -1) {
        continue;
      }
      if (indexR == -1){
        resultEmoji = resultEmoji + [{
          "emoji": ItemEmoji.castObjectToClass(totalDataSource[indexReactEmoji]),
          "users": [reactions[i]["user_id"]],
          "count": 1
        }];
      }
      else {
        resultEmoji[indexR] = {
          "users": resultEmoji[indexR]["users"] + [reactions[i]["user_id"]],
          "count": resultEmoji[indexR]["count"] + 1,
          "emoji": resultEmoji[indexR]["emoji"],
        };
      }
    }
    return resultEmoji;
  }

  static Future<List> processBlockCodeMessage(List data) async {
    return await Future.wait(data.map((mes) async {
      try {
        Map result = mes;
        // process reaction
        try {
          result = {
            ...result,
            "reactions": processReaction(mes["reactions"])
          };          
        } catch (e) { }

        List blockCode = mes["attachments"] != null ? mes["attachments"].where((e) => e["mime_type"] == "block_code").toList() : [];
        List newListHtml = mes["attachments"] != null ? mes["attachments"].where((e) => e["mime_type"] == "html").toList() : [];
        if (newListHtml.length > 0)
          result = Utils.mergeMaps([result, {"snippet":  await Utils.handleSnippet(newListHtml[0]["content_url"], false)} ]);
        if (blockCode.length > 0) 
          result = Utils.mergeMaps([result, {"block_code": await Utils.handleSnippet(blockCode[0]["content_url"], true)} ]);

        int index = mes["attachments"] != null ? mes['attachments'].indexWhere((ele) => ele['mime_type'] == 'share') : -1;
        if(index != -1) {
          final List newData = await processBlockCodeMessage([mes['attachments'][index]['data']]);

          result['attachments'][index]['data'] = newData[0];
        }

        return result;
      } catch (e) {
        print("_____ $e");
        return mes;
      }
    }));
  }

  static shaString(List dataSource){
    dataSource.sort((a, b) {
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    Digest y  = sha256.convert(
      utf8.encode(dataSource.join("_"))
    );

    if (dataSource.length <= 2)
      return base64Url.encode(y.bytes);
    return y.toString();
  }

  static Map getHeaderMessageConversation(){
    return {
      "is_system_message": true,
      "message": "",
      "attachments": [
        {
          "type": "header_message_converastion",
          "data": "Messages and calls in this chat will be encrypted end-to-end. Only participants could read or listen to them."
        }
      ],
      "id": "header_message_converastion",
      "user_id": "",
      "full_name": "",
      "inserted_at": "",
      "isBlur": false,
      "count_child": 0,
      "avatar_url": "",
      "isFirst": false,
      "isLast": false,
      "current_time": 0
    };
  }

  static Future<void> resendMessageConversation(String token, Map dataMessageConversation, BuildContext context, {int retryTime = 5}) async {
    var currentUser = Provider.of<User>(context, listen: false).currentUser;
    if (retryTime == 0) return;
    // check dk de tin nhan dc gui di la app da goi api getDataDirectMessage va success
    bool readyToSend = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(token, dataMessageConversation["conversation_id"]);
    if (readyToSend && Utils.checkedTypeEmpty(currentUser["id"])){
      String conversationId = dataMessageConversation["conversation_id"];
      List listIds = dataMessageConversation["list_message_ids"];
      await Future.wait(listIds.map((id) async {
        Map? dataLocal = await getListMessageById(id, conversationId);
        if (dataLocal != null && dataLocal["user_id"] == currentUser["id"]) {
          Provider.of<DirectMessage>(context, listen: false).queueBeforeSend({
            ...dataLocal,
            "isSend": false
          }, token);
        }
      }));
    } else {
      await Future.delayed(Duration(seconds: 2));
      return resendMessageConversation(token, dataMessageConversation, context, retryTime: retryTime - 1);
    }
  }

static Future<List> mergeDataLocal(String conversationId, List apiData, int rootCurrentTime, String type, int deleteTime ) async {
    try {
      List dataLocal = [];
      if (type == "down")
        dataLocal = await getMessageDown(conversationId, deleteTime, parseJson: true, currentTime: rootCurrentTime);
      else dataLocal = await getMessageUp(conversationId, deleteTime, currentTime: rootCurrentTime, parseJson: true);
      var lengthLocal = uniqById(dataLocal).length;
      if (lengthLocal == 0) return apiData;
      List result = uniqById([] + dataLocal + apiData, isRemoveDeteforMe: false);
      return result.sublist(0, lengthLocal );      
    } catch (e) {
      return [];
    }
  }

  static Future<Map?> getLastMessageOfConversation(String conversationId, {bool isCheckHasDM = true}) async {
    var boxDm = Hive.box("direct");
    DirectModel? dm  = boxDm.get(conversationId);
    if (dm == null && isCheckHasDM) return null;
    try {
      Isar isar = await getIsar();
      MessageConversation? data = await isar
        .messageConversations
        .where()
        .filter()
        .conversationIdEqualTo(conversationId)
        .and()
        .not()
        .actionEqualTo("delete_for_me")
        .and()
        .parentIdEqualTo("")
        .sortByCurrentTimeDesc()
        .findFirst();

        // print("$id $data");
      if (data == null) return null;
      if (!isCheckHasDM) return parseMessageToJson(data);
      if (dm == null) return null;
      return loadInfoThreadMessage(dm, parseMessageToJson(data));      
    } catch (e){
      print("getListMessageById $e");
      return null;
    }

  }

  static deleteHistoryConversation(String conversationId, String userId, int deleteTime) async {
    try {
      if (deleteTime == 0) return;
      Isar isar = await getIsar();
      await isar.writeTxn((isar) async => 
        await isar.messageConversations.where()
        .filter()
        .conversationIdEqualTo(conversationId)
        .and()
        .currentTimeLessThan(deleteTime)
        .deleteAll()
      );  
    } catch (e) {
    }
  }


  static makeBackUpMessageJsonV1(String userId, {String keyE2E = "4PxSnVX5sa2bu3TtH+o2BE0yBWdtvhOa7APGqT5FTCE="}) async {
    try {
      isBackUping = true;
      List total = [];
      _statusBackUpController.add(StatusBackUp(100, "Preparing  messages"));
      int totalMessage  = await getTotalMessage();
      print("total message");
      await Future.delayed(Duration(milliseconds: 300));
      var page = 1000; int totalPage = (totalMessage / page).round() + 1; int size = 1000;
      List<int> pages = List<int>.generate(totalPage, (int index) => index);
      List promissLoadMessages = await Future.wait(pages.map((i) => getMessageToTranfer(limit: size, offset: i * size, parseJson: true)));
      total = promissLoadMessages.reduce((value, element) => value += element);
      String text = jsonEncode(total);
      print("totalEncrypting message");
      await Future.delayed(Duration(milliseconds: 300));
      _statusBackUpController.add(StatusBackUp(101, "Encrypting data"));
      final key = En.Key.fromBase64(keyE2E);
      final iv = En.IV.fromLength(16);
      final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));  
      List<int> bytes = encrypter.encrypt(text, iv: iv).bytes;
      Directory? appDocDirectory;
      await Future.delayed(Duration(milliseconds: 300));
      _statusBackUpController.add(StatusBackUp(102, "Creating backup file"));
      print("Creating backup filee");
      appDocDirectory = await getApplicationDocumentsDirectory();
      var path = appDocDirectory.path;
      String nameBackUp = "backup_message_v1_encrypted_$userId.text";
      File file = File("$path/$nameBackUp");
      await Future.delayed(Duration(milliseconds: 300));
      await file.writeAsBytes(bytes, mode: FileMode.write);
      await Future.delayed(Duration(milliseconds: 300));
      print("Uploading the backup fil");
      _statusBackUpController.add(StatusBackUp(103, "Uploading the backup file"));
      if (userId != "all")
       await DriveService.uploadFile(Media(0, "$path/$nameBackUp", "", "backup_message_v1_encrypted_$userId.text", "backup", "", bytes.length, "", "downloaded"));
      _statusBackUpController.add(StatusBackUp(200, "Done"));
      isBackUping = false;      
    } catch (e) {
      isBackUping = false;    
      _statusBackUpController.add(StatusBackUp(105, "$e"));
    }
  }


  static saveJsonDataMessage(List decryptDataEncoded) async {
    List<Map<String, dynamic>> decryptData = await Future.wait(decryptDataEncoded.map<Future<Map<String, dynamic>>>((e) async {
      return {
        "attachments": parseListString(e["attachments"]),
        "localId": e["local_id"],
        "message": e["message"] ?? "",
        "conversationId": e["conversation_id"] ?? "",
        "success": e["success"] ?? true,
        "count": e["count"] ?? 0,
        "fakeId": e["fake_id"] ?? "",
        "timeCreate": e["time_create"],
        "isBlur": e["is_blur"] ?? false,
        "isSystemMessage": e["is_system_message"] ?? false,
        "parentId": e["parent_id"] ?? "",
        "publicKeySender": e["public_key_sender"] ?? "",
        "sending": e["sending"] ?? false,
        "currentTime": e["current_time"],
        "dataRead": [],
        "infoThread": parseListString(e["info_thread"]),
        "id": e["id"] ?? "",
        "userId": e["user_id"] ?? "",
        "lastEditedAt": e["last_edited_at"] ?? "",
        "action": e["action"] ?? "insert",
        "messageParse": await parseStringAtt(e)

      };
    }));
    try {
      Isar isar = await getIsar();
      await isar.writeTxn((isar) async {
        await isar.messageConversations.importJson(decryptData, replaceOnConflict: true);
      });
    } catch (e) {
      print(">>>> insert fail");
      return [];
    }
  }

  static reStoreBackUpFile(String userId, {String keyE2E = "4PxSnVX5sa2bu3TtH+o2BE0yBWdtvhOa7APGqT5FTCE=", bool hasClear = false}) async {
    try {
      // tim lai file backUp.
      await Future.delayed(Duration(milliseconds: 300));
      _statusRestoreController.add(StatusRestore(110, "Look for backups"));

      Directory? appDocDirectory;
      appDocDirectory = await getApplicationDocumentsDirectory();
      var path  = appDocDirectory.path;
      String nameBackUp = "backup_message_v1_encrypted_$userId.text";
      File file = File("$path/$nameBackUp");
      List<int> dataBackup = [];
      if (file.existsSync()){
        dataBackup = await file.readAsBytes();
      } else {
        await Future.delayed(Duration(milliseconds: 300));
        _statusRestoreController.add(StatusRestore(110, "Search for backup files in the cloud"));
        gdrive.File? driveBackup = await DriveService.getFileBackUpMessage(backupName: "backup_message_v1_encrypted_$userId.text");
        if (driveBackup == null) return;
        else {
          dataBackup = (await DriveService.getContentFile(driveBackup.id ?? ""))!;
        }
      }

      await Future.delayed(Duration(milliseconds: 300));
      _statusRestoreController.add(StatusRestore(111, "Decrypt backup data"));

      final key = En.Key.fromBase64(keyE2E);
      final iv  =  En.IV.fromLength(16);
      final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));  
      var encrypted =  En.Encrypted(dataBackup as Uint8List);
      var dataDecrypt =  encrypter.decrypt(encrypted, iv: iv);

      await Future.delayed(Duration(milliseconds: 300));
      _statusRestoreController.add(StatusRestore(112, "Processing"));

      var decryptDataEncoded = jsonDecode(dataDecrypt);
      await saveJsonDataMessage(decryptDataEncoded);
      await Future.delayed(Duration(milliseconds: 300));
      _statusRestoreController.add(StatusRestore(200, "Done"));

      if (hasClear && file.existsSync()){
        file.deleteSync();
      }
    } catch (e, trace) {
      print("reStoreBackUpFile: $e : $trace");
      _statusRestoreController.add(StatusRestore(103, "error $e"));
    }
  }

  static Future restoreBackUp() async {
    await reStoreBackUpFile("all", hasClear: true);
  }


static syncData(RTCDataChannel channel, String sharedKey, {bool isSecond = false}) async {
    try {

      print("sharedKey: $sharedKey");
      await Future.delayed(Duration(milliseconds: 100));
      DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
        "Preparing messages", 
        DeviceSocket.instance.currentDevice ?? "",
        DeviceSocket.instance.targetDevice ?? "",
        sharedKey
      ));
      List total = []; int maxLength = 90000;
      int totalMessage  = await getTotalMessage();
      var size = 1000; int totalPage = (totalMessage / size).round() + 1;
      List<int> pages = List<int>.generate(totalPage, (int index) => index);
      List promissLoadMessages = await Future.wait(pages.map((i) => getMessageToTranfer(limit: size, offset: i * size, parseJson: true)));
      total = promissLoadMessages.reduce((value, element) => value += element);
      String text = await Utils.encrypt(jsonEncode(total), sharedKey);
      int totalSplits = (text.length / maxLength).round() + 1;
      for(int j = 0; j <= totalSplits; j++){
        Map i = {
          "index": j,
          "data": text.substring([maxLength * j, text.length ].reduce(min),[text.length, maxLength * (j+ 1)].reduce(min))
        };
        String data = json.encode({
          "type": "message",
          "page": i["index"] + 1, // chay tu
          "type_transfer": isSecond ? "second" : "first",
          "total": totalSplits,
          "data": i["data"]
        });
        DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
          "Sending ${i["index"]}/$totalSplits", 
          DeviceSocket.instance.currentDevice ?? "",
          DeviceSocket.instance.targetDevice ?? "",
          sharedKey
        ));
        await Future.delayed(Duration(milliseconds: 50));
        channel.send(RTCDataChannelMessage(data));
      }
      if (isSecond) {
        DeviceSocket.instance.syncDataWebrtcStreamController.add(
          DataWebrtcStreamStatus("Done",
          DeviceSocket.instance.currentDevice ?? "",
          DeviceSocket.instance.targetDevice ?? "",
          sharedKey)
        );
        DeviceSocket.instance.setPairDeviceId("", "", "");
      }
    } catch (e, trace) {
      print("$e , $trace");
    }
  }
}

class StatusBackUp {
  late int statusCode; 
  late String status; 
  StatusBackUp(this.statusCode, this.status);
}
class StatusRestore {
  late int statusCode; 
  late String status; 
  StatusRestore(this.statusCode, this.status);
}


