// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:workcake/E2EE/GroupKey.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/direct_message/dm_confirm_shared.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/media_conversation/stream_media_downloaded.dart';
import 'package:workcake/services/queue.dart';
import 'package:workcake/services/upload_status.dart';
import 'package:image/image.dart' as img;
import '../E2EE/x25519.dart';
import 'models.dart';

class NumberUnreadConversation{
  int _currentTime = 0;
  int _unreadCount = 0;

  int get currentTime => this._currentTime;

  set currentTime( value) => this._currentTime = value;

  int get unreadCount => this._unreadCount;

  set unreadCount( value) => this._unreadCount = value;

  NumberUnreadConversation(int currentTime, int unreadCount){
    this._currentTime = currentTime;
    this._unreadCount = unreadCount;
  }


  updateFromObj(Map obj){
    if (obj["current_time"] < this._currentTime) return;
    this._unreadCount = obj["count"];
    this._currentTime =  obj["current_time"];
  }

  Map toJson(){
    return {
      "current_time": this._currentTime,
      "unread_count": this._unreadCount
    };
  }
}

class DirectMessage with ChangeNotifier {
  var _selectedId;
  List<DirectModel> _data = [];
  bool _fetching = false;
  dynamic _socket;
  dynamic _channel;
  List _dataMessage = [];
  List _messagesDirect = [];
  bool _isFetching = false;
  DirectModel _directMessageSelected = DirectModel(
      "", 
      [],
      "",
      false,
      0,
      {},
      false,
      0,
      {},
      "",
      null
    );
  var _lengthData;
  List<Map> dataDMMessages = [];
  bool _selectedFriend = true;
  var _pairKey;
  bool _showDirectSetting = false;
  var _errorCode;
  bool _isLogoutDevice = false;
  Scheduler queueReGetDataDiectMessage = Scheduler();
  Map _dataMentionConversations = {};
  bool _selectedMentionDM = false;
  var _idMessageToJump;
  List _deviceCanCreateOtp = [null];
  Map dataUnreadMessage = {};
  Map dataInfoThreadMessage = {};
  int _page = 0;
  int _limit = 30;
  bool disableCallApiLoadDirect = false;
  NumberUnreadConversation _unreadConversation = NumberUnreadConversation(0, 0);


  // statusConversation = "init" la tao dummy cho hoi thoai, cho tao hoi thoai
  Map defaultConversationMessageData = {
    "statusConversation": "created", //["init", "created", "creating"]
    "conversation_id": "",
    "messages": [],
    "active": true,
    "inserted_at": DateTime.now().toString(),
    "isFetching": false,
    "isFetchingUp": false,
    // "disableLoad": true,
    "disableLoadDown": false,
    "disableLoadUp": true,
    "disableHiveDown": false,
    "disableHiveUp": false,
    "queue": null,
    "conversationKey": null,
    "page": 0,
    "numberNewMessage": null,
    "last_current_time": DateTime.now().microsecondsSinceEpoch,
    "latest_current_time": DateTime.now().microsecondsSinceEpoch,
  };

  NumberUnreadConversation get unreadConversation => _unreadConversation;

  bool get selectedMentionDM => _selectedMentionDM;

  Map get dataMentionConversations => _dataMentionConversations;

  List get data => _data;

  String get selectedId => _selectedId;

  dynamic get socket => _socket;

  bool get fetching => _fetching;

  bool get isFetching => _isFetching;

  dynamic get channel => _channel;

  List get dataMessage => _dataMessage;

  List get messagesData => _messagesDirect;

  dynamic get pairKey => _pairKey;

  DirectModel get directMessageSelected => _directMessageSelected;
  
  int get lengthData => _lengthData;

  bool get selectedFriend => _selectedFriend;

  bool get showDirectSetting => _showDirectSetting;

  dynamic get errorCode =>  _errorCode;

  dynamic get idMessageToJump =>  _idMessageToJump;

  bool get isLogoutDevice => _isLogoutDevice;


  updateUnreadConversation(Map? obj){
    if (obj == null) return;
    _unreadConversation.updateFromObj(obj["data"]);
    var option= obj["option"];
    DirectModel? dm = getModelConversation(option["conversation_id"]);
    if (dm != null) {
      dm.seen = option["status"] == "read";
    }
    notifyListeners();
  }

  openDirectSetting(value) async {
    _showDirectSetting = value;
    var box = await Hive.openBox('drafts');
    box.put('openSetting', value);
    notifyListeners();
  }

  onChangeSelectedFriend(value) {
    _selectedMentionDM = false;
    _selectedFriend = value;
    _dataMentionConversations["seen"] = false;
    notifyListeners();
  }

  onChangeProfileFriend(data){
    if(_directMessageSelected.id != ""){
      _directMessageSelected.user.map((e){
        if(e["user_id"] == data["user_id"]){
          e["avatar_url"] = data["avatar_url"];
          e["full_name"] = data["full_name"];
        }
        return e;
      }).toList();
    }
    notifyListeners();
  }

  updateUnreadLocal(DirectModel directMessage, String userId, String token) async {
    await directMessage.markUnreadMessage(token, userId);
    notifyListeners();
  }
  // flow moi tao hoi thoai
  setSelectedDM(DirectModel dm, token, {bool isCreate = false}) async {
    // xoa last_message_readed cuar _directMessageSelected;
    if (_directMessageSelected.id != "" && _directMessageSelected.id != dm.id){
      removeMarkNewMessage(_directMessageSelected.id);
    }
    // tat ca tao hoi thoai deu tao dummy truoc
    // chi that su tao khi gui tin nhan dau tien
    // isCreate dung de check truong hojp tao
    // neu chon 1 hoi thoai da co thif dm.id luoon luoon co gia tri, tao hoi thoai thi = ""
    var indexConv = -1;
    String conversationDummy = MessageConversationServices.shaString(dm.user.map((e) => e["user_id"]).toList());
    if (dm.id == ""){
      indexConv = _data.indexWhere((ele) {
        return MessageConversationServices.shaString(ele.user.map((e) => e["user_id"]).toList()) == MessageConversationServices.shaString(dm.user.map((e) => e["user_id"]).toSet().toList());
      });
      // hoi thoai group co the tao trung
      if ((dm.user.length > 2) && isCreate) {
        // co gang tim xem da co hoi thoai dummy hay chua, neu chua co thi tao moi, neu co roi thi dung cai cu
        indexConv = _data.indexWhere((element) => !Utils.checkedTypeEmpty(element.id) && element.id == conversationDummy);
      }
    } else {
      indexConv = _data.indexWhere((element) => element.id == dm.id);
    }
    if (indexConv != -1) dm = _data[indexConv];
    else {
      // neu select 1 hoi thoai chua co (dummy hoi thoai) can set lai 1 id, (thuong la hash id cac thanh vien)
      // them luon vao _dataMessage voi khoi taoj conversationKey = GroupKey();
      // se ban kem id gia luc tao nen va update lai khi tao thanh cong

      var dataConversationDummy = {
        ...defaultConversationMessageData,
        "messages": [{
          ...MessageConversationServices.getHeaderMessageConversation(),
          "inserted_at": DateTime.now().toString(),
          "current_time":  DateTime.now().microsecondsSinceEpoch
        }],
        "conversation_id": conversationDummy,
        "conversationKey": GroupKey([], conversationDummy),
        "statusConversation": "init",
        "queue": Scheduler()
      };
      var indexDMDataMessage = dataDMMessages.indexWhere((element) => element["conversation_id"] == conversationDummy);
      if (indexDMDataMessage == -1){
        dataDMMessages = dataDMMessages + [dataConversationDummy];
      }
      dm.id = conversationDummy;
      dm.seen = true;
    }
    var directId = dm.id;
    if (directId != "") {
      List<DirectModel> newData = List.from(_data);
      int index = newData.indexWhere((e) => e.id == dm.id);

      if (index != -1) {
        newData[index].seen = true;
        newData[index].newMessageCount = 0;
        newData[index].archive = dm.archive;
        _data = newData;
      } else {
        dm.name = dm.name;
        dm.displayName = Utils.checkedTypeEmpty(dm.displayName) ? dm.displayName :getNameDM(dm.user, "", dm.name, hasIsYou: false);
        _data = [dm] + _data;
      }
      var boxSelect = await  Hive.openBox('lastSelected');
      boxSelect.put("lastConversationId", directId);
      boxSelect.put("isChannel", 0);
      var box = Hive.box('direct');
      var listKey = box.keys.toList();
      for (var i = 0; i < listKey.length; i++) {
        DirectModel dm = box.get(listKey[i]);
        if (dm.id == directId) {
          dm.seen = true;
          dm.newMessageCount = 0;
          box.put(listKey[i], dm);
        }
      }
    } 

    _directMessageSelected = dm;
    _messagesDirect = [];
    _lengthData = null;
    _selectedFriend = false;
    _selectedMentionDM = false;
    notifyListeners();
  }

  // setDirectMessage(DirectModel dm, token) async{
  //   var directId = dm.id;
  //   if (directId != "") {
  //     List newData = List.from(_data);
  //     int index = newData.indexWhere((e) => e.id == dm.id);

  //     if (index != -1) {
  //       newData[index].newMessageCount = 0;
  //       newData[index].archive = dm.archive;
  //       _data = newData;
  //     }
  //     var box = Hive.box('direct');
  //     var listKey = box.keys.toList();
  //     for (var i = 0; i < listKey.length; i++) {
  //       DirectModel dm = box.get(listKey[i]);
  //       if (dm.id == directId) {
  //         box.put(listKey[i],DirectModel(
  //           dm.id,
  //           dm.user,
  //           dm.name,
  //           true,
  //           0,
  //           dm.snippet,
  //           dm.archive,
  //           dm.updateByMessageTime
  //         )).then((value){
  //           print("${dm.id} ${dm.archive}");
  //         });
  //       }
  //     }
  //   } 

  //   _messagesDirect = [];
  //   _lengthData = null;
  //   _selectedFriend = false;
  //   _selectedMentionDM = false;
  //   notifyListeners();
  // }

// co 2 flow tao dm
// ----- tao qua modal (modal create dm)
//      + tao moi binh thuong,
// ----- tao qua dummy direct 
//      + dummy dm se co san id, vi the khi tao moi, can cap nhat lai dummy do
// data = {
//   "users": [""],
//   "name": "",
//   "dummy_id": ""(truong nay danh cho truong hoop dummy)
// };
  Future<dynamic> createDirectMessage(String token, Map data, context, userId) async {
    LazyBox box  = Hive.lazyBox('pairkey');
    final url = "${Utils.apiUrl}direct_messages/create?token=$token&device_id=${await box.get('deviceId')}";
    try {
      final response = await Dio().post(url, data: {
        "data" : await Utils.encryptServer({
          ...data, 
          "users": data["users"].map((u) => u["user_id"]).toList()
        })
      });
      var res = response.data;
      if (res["success"]) {
        // reload direct message
        var dm  = DirectModel(
          res["conversation_id"],
          data["users"], data["name"] ?? "",
          true, 0, {}, false, 0, {}, getNameDM(data["users"], userId, data["name"] ?? ""),
          null
        );
        // tu dong chon hoi thpai do luon
        _directMessageSelected = dm;
        if (!Utils.checkedTypeEmpty(data["isDesktop"])){
          if (context != null) Navigator.pop(context);
        }
        if (data["dummy_id"] != null) {
          var indexData = _data.indexWhere((element) => element.id == data["dummy_id"]);
          if (indexData != -1){
            dm.snippet = _data[indexData].snippet;
            _data[indexData] = dm;
          }
          setSelectedDM(dm, token);

          var indexDummy = dataDMMessages.indexWhere((element) => element["conversation_id"] == data["dummy_id"]);
          if (indexDummy != -1){
            dataDMMessages[indexDummy] = {
              ...dataDMMessages[indexDummy],
              "conversation_id": dm.id,
              "statusConversation": "created",
              // them truong nay da cho nhung tin nhan dc gui di ma dang tao hoi thoai(chi co conversation dummy_id, chua co conversatioin_id )
              "dummy_id": data["dummy_id"],
            };
          }
        } else {
          _data = [dm] + _data;
        }
        await getDataDirectMessage(token, userId, isReset: true,);
        return res["conversation_id"];
      }
      // trong truong hojp gui y/c tao conversation 1-1, ma da ton tai,thi chon conv do luon
      if (res["data"] != null ){
        Map resDM = res["data"];
        var index  =  _data.indexWhere((element) => element.id == resDM["conversation_id"]);
        if (index != -1){
          setSelectedDM(_data[index], token);
          if (data["isDesktop"]) {
            _selectedMentionDM = false;
            _selectedFriend = false;}
          else {
            if (context != null){
              Navigator.pop(context);
              Provider.of<Messages>(context, listen: false).openConversation(true);
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  handleShowFloatingNewMessage(Map data) {
    var index = _dataMessage.indexWhere((element) => element["id"] == data["id"]);
    if (index >= 0)
      _dataMessage[index] = data;
    else
      _dataMessage += [data];

    notifyListeners();
  }

  // message from direct_message
  // truong hop numberNewMessage != null thi se ko cap nhat vao Provider, them moi vao issar;
  onDirectMessage(List data, userId, insertHive, isDecrypted, String token, context, {bool isInMessageView = true}) async {
    // giai ma tin nhan
    try {
      for(var i =0; i< data.length; i++){
        var indexDM  =  _data.indexWhere((element) {
          DirectModel y = element;
          return y.id == data[i]["conversation_id"];
        });
        if (indexDM == -1){
          var hasInfoDM = await getInfoDirectMessage(token, data[i]["conversation_id"]);
          if (hasInfoDM){
            onDirectMessage([data[i]],  userId, insertHive, isDecrypted, token, context, isInMessageView: isInMessageView);
            continue;
          } else {
            continue;
          }
        }
        DirectModel dm =  _data[indexDM];
        // setHideConversation(dm.id, false, context);
        var dataConverstionCurrent = getCurrentDataDMMessage(data[i]["conversation_id"]);
        if (dataConverstionCurrent != null ){
          // lay thong tin cua conv
          var dataM = data[i];
          if (!isDecrypted && (dataM["is_system_message"] == null || !dataM["is_system_message"])){
            var convKey = dataConverstionCurrent["conversationKey"];
            var da = await convKey.decryptMessage(dataM);
            if (Utils.checkedTypeEmpty(data[i]["is_system_message"])){
              da = {
                "success": true,
                "message": data[i]
              };
            }
            if (!da["success"]) continue;
            dataM  = Utils.mergeMaps([dataM, da["message"]]);
          }

          var name = dm.user.where((element) {  return element["user_id"] == data[i]["user_id"];});
          var newData = {
            "message": dataM["message"],
            "attachments": dataM["attachments"],
            "title": (name.length == 0 ? "BOT" : name.toList()[0]["full_name"].toString() + " đến " + (dm.name != "" ? dm.name : dm.user.map((u) { return u["full_name"]; }).join(", "))),
            "conversation_id": dataM["conversation_id"],
            "show": true,
            "id": dataM["id"],
            "user_id": dataM["user_id"],
            "time_create": dataM["inserted_at"],
            "fake_id": dataM["fake_id"],
            "count": 0,
            "current_time": dataM["current_time"],
            "is_system_message": dataM["is_system_message"]
          };

          // show floating message
          if (userId != dataM["user_id"]) handleShowFloatingNewMessage(newData);

          // save on Hive
          if (insertHive){
            // update snippet + user_read
            updateSnippet(dataM);
            List successIds = await MessageConversationServices.insertOrUpdateMessage(dataM);
            // danh dau da doc neu dang trong conversation do
            if (_directMessageSelected.id != "" && _directMessageSelected.id == dataM["conversation_id"] && token != "" && isInMessageView){
              markReadConversationV2(token, dataM["conversation_id"], successIds as List<String>, [], true);
            } else markReadConversationV2(token, dataM["conversation_id"], successIds as List<String>, [], false);
          }

          // update snippet
          // ktra lai xem trong truong hop tao dummy hoi thoai, neu tao xit, se mo di
          updateSnippet({...newData, "statusSnippet": insertHive ? "created" : "dummy"});

          // sort direct_message
            // danh dau la da doc tin nhan khi tin nhan la cua minh hoac dang trong view tin nhan do
          dm.seen = (dataM["user_id"] == userId) || (_directMessageSelected.id == dataM["conversation_id"] && isInMessageView);
          dm.updateByMessageTime = dataM["current_time"];
          var newIndex = _data.indexWhere((element) => element.id == dm.id);
          if (newIndex != -1){
            _data = _data.where((element) => element.id != dm.id).toList();
            _data.insert(0, dm);
          }

          // ktra new_id_message
          markNewMessage(dataM, context);
          // cap nhat vao provider
          // ktra numberNewMessage != null
          if (dataM["data_read"] != null)
            updateListReadConversation(dm.id, dataM["data_read"]);   
          if (dataConverstionCurrent["numberNewMessage"] == null){
            List dataConversationCurrentMessage = dataConverstionCurrent["messages"];
            var indexFakeId = dataConversationCurrentMessage.indexWhere((element) => (element["fake_id"] != null) && (element["fake_id"] == data[i]["fake_id"]));
          
            if (indexFakeId != -1) {
              dataConverstionCurrent["messages"][indexFakeId]= Utils.mergeMaps([
                dataConverstionCurrent["messages"][indexFakeId],
                dataM,
                {"isBlur": false, "success": true, "sending": false},
              ]);

              dataConverstionCurrent["messages"] = sortMessagesByDay(uniqById(dataConverstionCurrent["messages"]));
            } else {
              dataConverstionCurrent["messages"] = sortMessagesByDay(uniqById([dataM] + dataConverstionCurrent["messages"]));
            }
          } else {
           dataConverstionCurrent["numberNewMessage"] += 1;
          }
        }
      }
      notifyListeners();
    } catch (e, _) {
      print(e.toString());
    }
  }

  

  // ignore: missing_return
  // defau;t get from Hive, api will overrirde
  setData(List data, {String currentUserId = ""}) async {  
    LazyBox boxKey = Hive.lazyBox("pairKey");
    // loc nhung direact message cua nguoi dung
    Map keys = {};
    List<DirectModel> uniq = [];
    for(var i in data){
      if (keys[i.id] == null) {
        keys[i.id] = true;
        uniq += [i];
      }
    }

    uniq = uniq.where((element) => element.user.indexWhere((ele) => ele["user_id"] == currentUserId) != -1).toList();
    uniq.sort((a, b) => (b.userRead["current_time"] ?? 0).compareTo(a.userRead["current_time"] ?? 0));
    _data = uniq.sublist(0, uniq.length > _limit ? _limit : uniq.length);
    dataDMMessages = await Future.wait(
      _data.map((d) async {
      // print("d.snippet    ${d.snippet} ${d.name}");
        return {
          ...defaultConversationMessageData,
          "conversation_id": d.id,
          "queue": Scheduler(),
          "active": false,
          "conversationKey": GroupKey.parseFromJson(await boxKey.get(d.id))
        };
      })
    );
    var box = Hive.box("lastSelected");
    var idSelected = box.get("lastConversationId");
    var indexSelected  =  _data.indexWhere((element) => element.id == idSelected);
    if (indexSelected != -1) _directMessageSelected = _data[indexSelected];
    // notifyListeners();
  }

  Future saveDataFromDirectMessage(message, userId) async {
    try {
      await MessageConversationServices.insertOrUpdateMessage(message);
    } catch (e) {
      print(e);
    }
  }

  Future getMessageMissed(token) async {
    final urlMiss = Utils.apiUrl + 'direct_messages/missed?token=$token';
    try {
      var response = await Dio().get(urlMiss);
      var dataRes = response.data;
      if (dataRes["success"]) {
        var data = dataRes["data"];
        for (var i = 0; i < data.length; i++) {
          var result = {};
          var box = await Hive.openLazyBox("direct_${data[i]["conversation_id"]}");
          var message = data[i]["message"];
          for (var j = 0; j < message.length; j++) {
            result[message[j]["inserted_at"]] = message[j];
          }
          box.putAll(result);
        }
      }
      else{
        throw HttpException("Error miss message");
      }
    } catch (e) {
      print("e miss message: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }
  Future<List<Map>> processDataDirectMessage(List dataSource, String token) async {
    var direct = Hive.box('direct');
    return await Future.wait((dataSource).map((conv) async {
      var currentUserId = conv["current_user"];
      var local  = direct.get(conv["conversation_id"]);
      var snippet = local == null ? {} : local.snippet;
      if ((snippet as Map).isEmpty){
        var lastMessage = await MessageConversationServices.getLastMessageOfConversation(conv["conversation_id"], isCheckHasDM: false);
        if (lastMessage != null) snippet = lastMessage;
      }
      DirectModel dm  = DirectModel(
        conv["conversation_id"], 
        conv["user"], 
        conv["name"] ?? "", 
        conv["seen"], 
        conv["new_message_count"], 
        snippet, 
        conv["is_hide"] ?? false, 
        conv["update_by_message"],
        conv["user_read"],
        getNameDM(conv["user"], currentUserId, conv["name"] ?? ""),
        conv['avatar_url']
      );
      int deleteTime = dm.getDeleteTime(currentUserId);
      if ((dm.snippet["current_time"] ?? 0 ) <= deleteTime) dm.snippet = {};
      MessageConversationServices.deleteHistoryConversation(conv["conversation_id"], currentUserId, deleteTime);
      dm..displayName = dm.getNameDM(currentUserId);
      if (conv["need_broadcast"]) {
        await dm.broadcastSharedKey(currentUserId, token);
        // sau khi broadcast xong can phai goij lai api
        return {
          "needReload": true
        };
      }   
      if (dm.id == _directMessageSelected.id){
        _directMessageSelected = dm;
      }
      var indexMessageData = dataDMMessages.indexWhere((element) => element["conversation_id"] == dm.id);
      var currentDataMessageConv = indexMessageData == -1 ? null : dataDMMessages[indexMessageData];
      return {
        "needReload": false,
        "dm": dm,
        "dataMessageConversation": {
          ...defaultConversationMessageData,
          "conversation_id": dm.id,
          "messages": currentDataMessageConv == null ? [] : currentDataMessageConv["messages"],
          "active": false,
          "queue": currentDataMessageConv == null ? Scheduler() : currentDataMessageConv["queue"],
          "type": conv["type"],
          "dummy_id": currentDataMessageConv == null ? null : currentDataMessageConv["dummy_id"],
          "conversationKey": await dm.getConversationKey(currentUserId, token, conv["type"]),
          "inserted_at": conv["inserted_at"],

        }
      };
    }));
  }

  Future getDataDirectMessage(token, String currentUserId, {bool isReset = false, bool isLoadMore = false}) async {
    if (_fetching && !isReset) return;
    var nextPage = _page;
    if (isLoadMore) nextPage = nextPage + 1;
    if (isReset){
      disableCallApiLoadDirect = false;
      nextPage = 0;
    }

    if (disableCallApiLoadDirect) return;
    _errorCode =  null;
    _fetching = true;
    notifyListeners();
    var box = Hive.lazyBox('pairKey');
    var lastSelected = Hive.box('lastSelected');
    var currentId = _directMessageSelected.id != "" ? _directMessageSelected.id : lastSelected.get('lastConversationId');
    final url = Utils.apiUrl + 'direct_messages/v2?token=$token&device_id=${await Utils.getDeviceId()}&limit=$_limit&page=$nextPage&current_id=$currentId';
    try {
      final response = await Dio().get(url);
      var resData = response.data;
      if (!Utils.checkedTypeEmpty(resData["success"])){
        _errorCode = "${resData["error_code"]}";
        _deviceCanCreateOtp = resData["device_can_create_otp"] ?? [];
        _fetching = false;
        notifyListeners();
        return;
      }
      var responseData = await Utils.decryptServer(resData["data"]);
      if (responseData["success"] == false) {
        _errorCode =  responseData["error_code"];
        _fetching = false;
        notifyListeners();
        throw HttpException(responseData["message"]);
      } else {
        // save to db
        await box.put("id_default_private_key", responseData["data"]["id_default_private_key"]);
        List dataResults = await processDataDirectMessage(responseData["data"]["data"], token);
        _unreadConversation.updateFromObj(responseData["data"]["data_unread"]);
        if (dataResults.where((element) => element["needReload"]).toList().length > 0) {
          _fetching = false;
          _page = 0;
          disableCallApiLoadDirect = false;
          return await getDataDirectMessage(token, currentUserId, isReset: true);
        }
        disableCallApiLoadDirect = dataResults.length == 0;
        _errorCode= null;
        _fetching = false;
        _page = nextPage;
        await saveDataToProvider(dataResults, isReset);
        getDataMessageOnConversationNeed(token, responseData["data"]["data"], currentUserId);
        notifyListeners();
        loadUnreadMessage(token);
        checkCurrentDM(token, currentUserId);
        checkReSendMessageError(token);
        ServiceMedia.autoDownloadAttDM();
        return;
      }
    } catch (e) {
      print("RFghymjnlerthner $e");
      // _data = [];
      _errorCode= null;
      _fetching = false;
      notifyListeners();
      return [];
    }
  }

  saveDataToProvider(List dataResults, bool isReset) async {
    var direct = Hive.box('direct');
    List<DirectModel> data = dataResults.map((e) => e["dm"] as DirectModel).toList();
    List<Map> dataDMMes = dataResults.map((result) {
      Map dataConver =  result["dataMessageConversation"];
      var indexDataMessageConversations = dataDMMessages.indexWhere((element) => element["conversation_id"] == dataConver["conversation_id"]);
      return {
        ...dataConver,
         "messages": indexDataMessageConversations == -1 ? [] : dataDMMessages[indexDataMessageConversations]["messages"]
      };
    }).toList();
    if (isReset){
      await direct.deleteAll(direct.keys);
      _data = data;
      // do tin nhan dc lay tu local truoc khi ca api dc goin hoac bi thay doi trong vong lap ma ko cap nhat lai
      // nen khi lay data Conversation xong thi can phai merge data local tranh bi loop
      // chi merge tin nhan, cac tham so khac set ve mac dinh
      // cac tham so: last_id, latest_id se chi dc set theo gia tri cua api, khong set = dataDMMessages[indexDataMessageConversations]["messages"].last["id"]
      dataDMMessages = dataDMMes;
    } else {
      Map<String, DirectModel> index= {};
      List total = _data + data;
      for (var i=0; i <total.length; i++) {
        index[total[i].id] = total[i];
      }
      _data = index.values.toList();
      _data.sort((DirectModel a, DirectModel b) =>( b.userRead["current_time"] ?? 0).compareTo(a.userRead["current_time"] ?? 0));
      Map<String, Map> indexDMMess= {};
      List<Map> totalDMMes = (dataDMMessages + dataDMMes);
      for (var i=0; i <totalDMMes.length; i++) {
        indexDMMess[totalDMMes[i]["conversation_id"]] = totalDMMes[i];
      }
      dataDMMessages = indexDMMess.values.toList();
    }
    await direct.putAll(
      Map.fromIterable(data, key: (v) => v.id, value: (v) => v)
    );
  }


  checkCurrentDM(String token, String currentUserId){
    try {
      DirectModel? dm = getModelConversation(_directMessageSelected.id);
      if (dm == null){
        _directMessageSelected = _data[0];
        var boxSelect = Hive.box('lastSelected');
        boxSelect.put("lastConversationId", _directMessageSelected.id);
      }
      getMessageFromApi(_directMessageSelected.id, token, true, null, currentUserId);      
    } catch (e) {
    }
  }

// 
  Future<bool> getInfoDirectMessage(String token, String conversationId) async {
    try {
      var indexD = _data.indexWhere((element) => element.id == conversationId);
      if (indexD != -1) return true;
      final url = "${Utils.apiUrl}direct_messages/$conversationId?token=$token&device_id=${await Utils.getDeviceId()}";
      var response = await Dio().get(url);
      var resData = response.data;
      if (!resData["success"]) return false;
      var responseData = await Utils.decryptServer(resData["data"]);
      List<Map> dataResults = await processDataDirectMessage(responseData["data"]["data"], token);
      if (dataResults.length == 0) return false;
      List<DirectModel> data = dataResults.map((e) => e["dm"] as DirectModel).toList();

      if (dataResults.where((element) => element["needReload"]).toList().length > 0) return getInfoDirectMessage(token, conversationId);
      Map<String, DirectModel> index  = {};
      List total = _data + data;
      for (var i=0; i <total.length; i++) {
        if (index[total[i].id] == null) index[total[i].id] = total[i];
      }

      _data = index.values.toList();
          _data.sort((a, b) => (b.userRead["current_time"] ?? 0).compareTo(a.userRead["current_time"] ?? 0));
      var direct = Hive.box('direct');
      await direct.putAll(
        Map.fromIterable(data, key: (v) => v.id, value: (v) => v)
      );
      dataDMMessages = dataDMMessages + dataResults.map((result) => result["dataMessageConversation"] as Map).toList();
      return true;
      
    } catch (e, t) {
      print("getInfoDirectMessage: $t and $conversationId");
      return false;
    }

  }
  

  Future getDataMessageOnConversationNeed(String token, List dataSource, String currentUserId) async {
    List listConverIdNeedGetMessage = dataSource.map((e) {
      if (e["new_message_count"] > 0) return e["conversation_id"];
      var index = _data.indexWhere((element) => element.id  == e["conversation_id"]);
      if (index == -1) return e["conversation_id"];
      return ((_data[index]).userRead["current_time"] ?? 0) == e["update_by_message"] ? null : e["conversation_id"];
    }).where((element) => element != null).toList();
    return await Future.wait(listConverIdNeedGetMessage.map((r) async {
      await getMessageFromApi(r, token, true, null, currentUserId, isNotiffy: false);
    }));
  }

  updateListReadConversation(String conversationId, Map dataUser) {
    // dataUser  = {
    //   current_time: int  => thoi gian cua tin nhan cuoi cung,
    //   last_user_id_send_message: string => user_id cuar nguoi nhan tin cuoi cung
    //   user_id: string  =>  user_id cuar nguoi doc tin nhan cuoi cung
    // }
    var indexConversation = _data.indexWhere((element) => element.id == conversationId);
    if (indexConversation != -1){
      // neu currentTime > currentTime hien taij  => thay the  =  data moi
      if ((_data[indexConversation].userRead["current_time"] ?? 0) < dataUser["current_time"])
        _data[indexConversation].userRead = {
          "current_time": dataUser["current_time"],
          "last_user_id_send_message": dataUser["last_user_id_send_message"],
          "data": [dataUser["user_id"]]
        };
        // update hive
      // neu currentTime == currentTime hien taij  => then user_id moiws vafo
      else if (_data[indexConversation].userRead["currentTime"] == dataUser["currentTime"])
        _data[indexConversation].userRead["data"] =  ([] + _data[indexConversation].userRead["data"] + [dataUser["user_id"]]).toSet().toList();

      else {}
      var box  = Hive.box("direct");
      box.put(_data[indexConversation].id, _data[indexConversation]);
      // no thing
      notifyListeners();
    }
  }

  updateDirectMessage(Map dataMessage, updateHive, _fromApi, isDecrypted, {int retryTime = 50})async{
    if (retryTime == 0) return;
    try {
      int indexConverstionCurrent  = dataDMMessages.indexWhere((element) => element["conversation_id"] == dataMessage["conversation_id"]);
      if (indexConverstionCurrent == -1) return;

      Map dataConverstionCurrent = dataDMMessages[indexConverstionCurrent];
      if (dataConverstionCurrent["conversationKey"] == null) return throw {};
      var dataM  = dataMessage;
      if (!isDecrypted){
         var messageDe = await dataConverstionCurrent["conversationKey"].decryptMessage(dataMessage);

        // ket thuc neu giai ma sai
        if (messageDe == null || (messageDe != null && !messageDe["success"])) return;
        dataM = messageDe["message"];
      }

      // update on Hive
      if (updateHive){
        MessageConversationServices.insertOrUpdateMessage(dataM, type: "update");
      }
      // upd""ate onProvider
      if (indexConverstionCurrent != -1){
        List dataConversationCurrentMessage = dataConverstionCurrent["messages"];
        int indexCurrentMessage  =  dataConversationCurrentMessage.indexWhere((element) => element["id"] == dataM["id"]);
        if (indexCurrentMessage != -1 && Utils.checkedTypeEmpty(dataM["id"])){
          dataConversationCurrentMessage[indexCurrentMessage] = Utils.mergeMaps([
            dataConversationCurrentMessage[indexCurrentMessage],
            dataM,
            {"status_decrypted": "success"}
          ]);
        }
        else {
          // update by fake_id
          int indexCurrentMessageFake  =  dataConversationCurrentMessage.indexWhere((element) => element["fake_id"] == dataM["fake_id"]);
          if (indexCurrentMessageFake != -1 && Utils.checkedTypeEmpty(dataM["fake_id"])){
            dataConversationCurrentMessage[indexCurrentMessageFake] = Utils.mergeMaps([
              dataConversationCurrentMessage[indexCurrentMessageFake], 
              dataM,
              {"status_decrypted": "success"}
            ]);
          }
        }
      }

      dataConverstionCurrent["messages"] = sortMessagesByDay(uniqById(dataConverstionCurrent["messages"]));
    
      notifyListeners();
    } catch (e) {
      await Future.delayed(Duration(seconds: 2));
      return updateDirectMessage(dataMessage, updateHive, _fromApi, isDecrypted, retryTime: retryTime -1);
    }
  }

  void updateCountChildMessage(dataM, String token) async{
    for (var i = 0; i< dataM.length; i++){
      Map dataMessage = dataM[i];
      int indexConverstionCurrent  = dataDMMessages.indexWhere((element) => element["conversation_id"] == dataMessage["conversation_id"]);        
      if (indexConverstionCurrent != -1){
        var dataDe = await dataDMMessages[indexConverstionCurrent]["conversationKey"].decryptMessage(dataMessage);
        if (dataDe != null && dataDe["success"])
          dataMessage = dataDe["message"];
        else continue;
        List dataConversationCurrentMessage = dataDMMessages[indexConverstionCurrent]["messages"];
        int indexCurrentMessage  =  dataConversationCurrentMessage.indexWhere((element) => element["id"] == dataMessage["parent_id"]);
        if (indexCurrentMessage != -1){
          dataConversationCurrentMessage[indexCurrentMessage]["count"] = dataConversationCurrentMessage[indexCurrentMessage]["count"] == null ? 0 :  dataConversationCurrentMessage[indexCurrentMessage]["count"]+ 1;

          final newUser = {
            "user_id": dataMessage["user_id"],
            "inserted_at": dataMessage["inserted_at"],
            "avatar_url": dataMessage["avatar_url"],
            "full_name": dataMessage["full_name"],
          };
          if (dataConversationCurrentMessage[indexCurrentMessage]["info_thread"] != null) {
            dataConversationCurrentMessage[indexCurrentMessage]["info_thread"] = [] + [newUser] + dataConversationCurrentMessage[indexCurrentMessage]["info_thread"];
          } else {
            dataConversationCurrentMessage[indexCurrentMessage]["info_thread"] = [] + [newUser];
          }
        }
        List successIds = await MessageConversationServices.insertOrUpdateMessage(dataMessage);   
        markReadConversationV2(token, dataMessage["conversation_id"], successIds as List<String>, [], false); 
      }
    }
    notifyListeners();
  }

  getMessageFromApiDown(idDirectMessage, isReset, token, String currentUserId, {int size = 0, bool isNotiffy = false}) async {
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    DirectModel? dm = getModelConversation(idDirectMessage);
    if (currentDataDMMessage == null || dm == null || currentDataDMMessage["isFetching"] || currentDataDMMessage["conversationKey"] == null) return;
    try {
      if (isReset || !currentDataDMMessage["disableLoadDown"]){
        currentDataDMMessage["isFetching"] = true;
        if (isReset) currentDataDMMessage["last_current_time"] = DateTime.now().microsecondsSinceEpoch; 
        var url = "${Utils.apiUrl}/direct_messages/$idDirectMessage/messages?token=$token&is_desktop=true&device_id=${await Utils.getDeviceId()}&last_current_time=${currentDataDMMessage["last_current_time"]}";  
        if (size != 0 ) url += "&size=$size";
        var response = await Dio().get(url);
        var resData = response.data;
        if (resData["success"] && resData["data"].length > 0) {
          await processDataMessageFromApi(idDirectMessage, resData["data"],  currentDataDMMessage["last_current_time"], false, dm.getDeleteTime(currentUserId), token: token, hasMark: isNotiffy);
        } else {
          await processDataMessageFromApi(idDirectMessage, [],  currentDataDMMessage["last_current_time"], false, dm.getDeleteTime(currentUserId), token: token, hasMark: isNotiffy);
          currentDataDMMessage["disableLoadDown"] = true;
        }
        currentDataDMMessage["isFetching"] = false;
        notifyListeners();
      }
      if (currentDataDMMessage["disableLoadDown"]){
        // lay tin nhan dang co trong isar
        await getMessageFromHiveDown(idDirectMessage, currentDataDMMessage["last_current_time"], token, currentUserId);
      }

    } catch (e){
      print("gdhfhgjguikyt $e");
      // neu loi api thi disableLoadDown = true
      currentDataDMMessage["disableLoadDown"] = true;
      currentDataDMMessage["isFetching"] = false;
      notifyListeners();
    }
   
  }

  getMessageFromHiveUp(idDirectMessage, int rootCurrentTime, String token, String currentUserId, {int limit = 30, bool includeRootMessage = false, bool forceLoad = false})async {
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    DirectModel? dm = getModelConversation(idDirectMessage);
    if (dm == null) return;
    if ((currentDataDMMessage == null || Utils.checkedTypeEmpty(currentDataDMMessage["disableHiveUp"] || currentDataDMMessage["isFetchingUp"])) && !forceLoad ) return;
    currentDataDMMessage["isFetchingUp"] = true;
    List dataFromIsar = await MessageConversationServices.getMessageUp(idDirectMessage, dm.getDeleteTime(currentUserId), currentTime: rootCurrentTime, parseJson: true, limit: limit);
    await processDataMessageFromHive(idDirectMessage, includeRootMessage ? dataFromIsar : dataFromIsar.where((element) => element["current_time"] != rootCurrentTime).toList(), token, type: "up");
    currentDataDMMessage["isFetchingUp"] = false;
    notifyListeners();
  }

  getMessageFromHiveDown(String idDirectMessage, int rootCurrentTime, String token, String currentUserId, {bool forceLoad = false}) async {
    // tra ve list data trong Hive,
    // ktra roi them nhung data chua co trong Provider
    // check disable load from Hive
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    DirectModel? dm = getModelConversation(idDirectMessage);
    if ( dm == null ) return;
    if ((currentDataDMMessage == null || Utils.checkedTypeEmpty(currentDataDMMessage["disableHiveDown"] || currentDataDMMessage["isFetching"])) && !forceLoad ) return;
    currentDataDMMessage["isFetching"] = true;
    // lay tin nhan cuoi cung
    // trong truong hop ko co id cua tin nhan cuoi cung lay tin nhan moi nhat cua hoij thoaij
    List dataFromIsar = await MessageConversationServices.getMessageDown(idDirectMessage, dm.getDeleteTime(currentUserId), currentTime: rootCurrentTime, parseJson: true);
    // dataFromIsar = dataFromIsar.where((ele) => ele["id"] != (messageLastId == null ? "" : messageLastId["id"] )).toList();// ham nay de fix loi tin 1 tin nhan bi insert nhiefu lan
    await processDataMessageFromHive(idDirectMessage, rootCurrentTime == 0 ? [] : dataFromIsar, token);
    currentDataDMMessage["isFetching"] = false;
    notifyListeners();
  }

  getMessageFromApiUp(idDirectMessage, token, String currentUserId, {int size = 0, bool forceLoad = false}) async {
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    DirectModel? dm = getModelConversation(idDirectMessage);
    if (currentDataDMMessage == null || dm == null || currentDataDMMessage["isFetchingUp"] || currentDataDMMessage["conversationKey"] == null) return;
    try {
      if (!currentDataDMMessage["disableLoadUp"]){
        var url = "${Utils.apiUrl}/direct_messages/$idDirectMessage/messages?token=$token&device_id=${await Utils.getDeviceId()}&latest_current_time=${currentDataDMMessage["latest_current_time"]}";  
        currentDataDMMessage["isFetchingUp"] = true;
        notifyListeners();
        if (size !=0 ) url += "&size=$size";
        var response  = await Dio().get(url);
        var resData = response.data;
        if (resData["success"] && resData["data"].length > 0) {
          currentDataDMMessage["latest_id"] = (resData["data"].last)["id"];
          await processDataMessageFromApi(idDirectMessage, resData["data"], currentDataDMMessage["latest_current_time"], false,  dm.getDeleteTime(currentUserId), token: token, type: "up");
        } else {
          await processDataMessageFromApi(idDirectMessage, [], currentDataDMMessage["latest_current_time"], false,  dm.getDeleteTime(currentUserId), token: token, type: "up");
          currentDataDMMessage["numberNewMessage"] = null;
          currentDataDMMessage["disableLoadUp"] = true;
        }
        currentDataDMMessage["isFetchingUp"] = false;
        notifyListeners();
      } else {
        await getMessageFromHiveUp(idDirectMessage, currentDataDMMessage["latest_current_time"], token, currentUserId);
      }      
    } catch (e) {
       print("getMessageFromApiUp $e");
      // neu loi api thi disableLoadDown = true
      currentDataDMMessage["disableLoadUp"] = true;
      currentDataDMMessage["isFetchingUp"] = false;
      notifyListeners();
    }

  }

  processDataMessageFromApi(idDirectMessage,List dataMessage, int rootCurrentTime, isReset, int deleteTime, {String token = "", String type = "down", bool hasMark = true}) async {
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    // print("currentDataDMMessage: $currentDataDMMessage");
    if (currentDataDMMessage == null) return;
    var messageIsSnippet;
    var resultMessage = [];
    List resultUpdate = [];
    List<String> errorMessageIds = [];
    for (var i = dataMessage.length - 1; i >= 0; i -- ) {
      if (dataMessage[i]["action"] == "delete" || dataMessage[i]["action"] == "delete_for_me") {
        Map daM = {
          ...dataMessage[i],
          "conversation_id": idDirectMessage
        };
        resultUpdate = [] + resultUpdate + [daM];
        resultMessage = [] + [daM] + resultMessage;
        messageIsSnippet = daM;
        continue;
      }
      // print("________$i");
      var message = dataMessage[i];
      var dataM, messageOnHive;
      // giai tin nhan + get from isar can boc trong tung try {} catch() {} de tranh xit 1 cai dan den catch => mat data
      try {
        dataM = await currentDataDMMessage["conversationKey"].decryptMessage(dataMessage[i]);
      } catch (e) {
      }
      try {
        messageOnHive = await MessageConversationServices.getListMessageById(message["id"], idDirectMessage);
      } catch (e) {
      }
      if (messageOnHive != null){
        messageOnHive = {
          "success": true,
          "message": messageOnHive
        };
      }

      if (Utils.checkedTypeEmpty(dataMessage[i]["is_system_message"])){
        dataM = {
          "success": true,
          "message": dataMessage[i]
        };
      }
      
      // gop data local va data api
      // neu ko giai dc se lay data local
      // trong truong hop ko giai dc, ko co local thi van them vao danh sach nhwung ko render ra nua,
      var dataMessageEnd = Utils.mergeMaps([
        dataMessage[i],
        {
          "message": "",
          "attachments": [],
          "last_edited_at": null
        },
        messageOnHive != null && messageOnHive["success"] ? messageOnHive["message"] : {},
        dataM != null && dataM["success"] ? dataM["message"] : {},
        {"conversation_id": idDirectMessage}
      ]);

      if ((dataM == null || (dataM != null && !dataM["success"])) && messageOnHive == null) {
        errorMessageIds += [dataMessage[i]["id"]];
        dataMessageEnd={
          ...dataMessageEnd,
          "status_decrypted": "decryptionFailed"
        };
      } else {
        resultUpdate += [dataMessageEnd];
        messageIsSnippet = dataMessageEnd;
      }
      resultMessage = [] + [dataMessageEnd] + resultMessage;
      
    }

    List dataMergeLocal = await MessageConversationServices.mergeDataLocal(idDirectMessage, resultMessage, rootCurrentTime, type, deleteTime);
    if (type == "down"){
       currentDataDMMessage["last_current_time"] =  dataMergeLocal.length == 0 ? 0 : dataMergeLocal.last["current_time"];
    }
    if (type == "up"){
      currentDataDMMessage["latest_current_time"] =  dataMergeLocal.length == 0 ? 0 : dataMergeLocal.first["current_time"];
    }
    List<String> successIds = await MessageConversationServices.insertOrUpdateMessages(resultUpdate);
    if (messageIsSnippet != null && type == "down"){
      // lay het tin chua gui ra roi gui lai, uu tien de len dau
      updateSnippet(Utils.mergeMaps([messageIsSnippet, {"conversation_id": idDirectMessage}]));
    }
    getInfoUnreadMessage(
      dataMergeLocal,
      token, 
      idDirectMessage
    );
    getLocalPathAtts(dataMergeLocal);
    if (isReset) {
      currentDataDMMessage["messages"] = sortMessagesByDay(uniqById([] + dataMergeLocal + getMessageErrorSavedOnHive(idDirectMessage)));
    } else {
      currentDataDMMessage["messages"] = sortMessagesByDay(uniqById([] +  currentDataDMMessage["messages"] + dataMergeLocal + getMessageErrorSavedOnHive(idDirectMessage)));
    }

    currentDataDMMessage["active"] = true;
    markReadConversationV2(token, idDirectMessage, successIds, errorMessageIds, hasMark);
  }

  // ham nay chi dc goi trong processDataMessageFromApi() va onDirectMessage()
  markReadConversationV2(String token, String conversationId, List<String> successIds, List<String> errorIds, bool hasMark) async {
    String url = "${Utils.apiUrl}direct_messages/$conversationId/mark_read_v2?token=$token&device_id=${await Utils.getDeviceId()}&version_api=2";
    Dio().post(url, data: {
      "data": await Utils.encryptServer({
        "version_api": 2,
        "success_ids": successIds,
        "error_ids": errorIds,
        "has_mark": hasMark
      })
    });
  }

  List uniqById(List dataSource){
    return MessageConversationServices.uniqById(dataSource);  
  }

  getLocalPathAtts(List messages){
    try {
      List total = messages.map((e){
        ServiceMedia.getAllMediaFromMessageViaIsolate(e);
        return e != null ? (e["attachments"] ?? []) : [];
      }).fold([], (acc, ele) => acc += ele);
      for (var i = 0; i < total.length; i++){
        var y  = total[i];
        if (Utils.checkedTypeEmpty(y["content_url"])){
          if (!Utils.checkedTypeEmpty(y["key_encrypt"])){
            StreamMediaDownloaded.instance.setStreamOldFileStatus(y["content_url"]);
          } else {
            StreamMediaDownloaded.instance.setStreamDownloadedStatus(y["content_url"]);
          }
        }
      }
    } catch (e, trace) {
      print("getLocalPathAtts: $e $trace");
    } 
  }

  processDataMessageFromHive(idDirectMessage,List data, String token, {String type = "down"}){
    var currentDataDMMessage = getCurrentDataDMMessage(idDirectMessage);
    try {
      if (currentDataDMMessage == null) return;

      // chi tin  nhan chua co moi them
      List results = data;
      getInfoUnreadMessage(
        results,
        token, 
        idDirectMessage
      );

      getLocalPathAtts(data);
      currentDataDMMessage["messages"] = uniqById( [] + currentDataDMMessage["messages"] + results);
      if (type == "down") {
        currentDataDMMessage["disableHiveDown"] =  data.length == 0 || currentDataDMMessage["last_id"] == ((currentDataDMMessage["messages"] as List).last ?? {})["id"];
        currentDataDMMessage["last_current_time"] = currentDataDMMessage["messages"].length == 0 ? 0 : ((currentDataDMMessage["messages"] as List).last ?? {})["current_time"];   
      }   
      else {
        currentDataDMMessage["disableHiveUp"] =  data.length == 0 || currentDataDMMessage["latest_id"] == ((currentDataDMMessage["messages"] as List).first ?? {})["id"];
        currentDataDMMessage["latest_current_time"] = currentDataDMMessage["messages"].length == 0 ? DateTime.now().microsecondsSinceEpoch : ((currentDataDMMessage["messages"] as List).first ?? {})["current_time"];   
      }
      if (data.length == 0){
        currentDataDMMessage["messages"] += [{
          ...MessageConversationServices.getHeaderMessageConversation(),
          "inserted_at": currentDataDMMessage["inserted_at"]
        }];
      }
      currentDataDMMessage["messages"] = sortMessagesByDay(uniqById(currentDataDMMessage["messages"]));
    } catch (e, trace) {
      print("processDataMessageFromHive: $e  $trace");
      currentDataDMMessage["disableHiveDown"] = true;
    }
  }


  getCurrentDataDMMessage(idDirectMessage){
    int indexDM  = dataDMMessages.indexWhere((element) => element["conversation_id"] == idDirectMessage || (element["dummy_id"] ?? "_____") == idDirectMessage);
    if (indexDM == -1) return null;
    return dataDMMessages[indexDM];
  }

  sortMessagesByDay(messages) {
    messages = messages.where((e) => e["is_datetime"] == null).toList();
    List listMessages = [];

    for (var i = 0; i < messages.length; i++) {
      try {
        listMessages.add(messages[i]);

        if ((i + 1) < messages.length) {
          if (messages[i+1]["time_create"] == null ||  messages[i]["time_create"] == null) continue;
          var currentDay = DateFormat('MM-dd').format(DateTime.parse(messages[i]["time_create"]).add(Duration(hours: 0)));
          var nextday = DateFormat('MM-dd').format(DateTime.parse(messages[i+1]["time_create"]).add(Duration(hours: 0)));

          if (nextday != currentDay) {
            var stringDay = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(messages[i]["time_create"]).add(Duration(hours: 0)));
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

    for (int index = 0; index < listMessages.length; index++) {
      try {
        int length = listMessages.length;
        var isFirst = (index + 1) < length ? ((listMessages[index + 1]["user_id"] != listMessages[index]["user_id"]) || (listMessages[index + 1]["is_system_message"] == true)) : true;
        var isLast = index == 0  ? true : listMessages[index]["user_id"] != listMessages[index - 1]["user_id"] ;
        bool showNewUser = false;

        if ((index + 1) < length) {
          showNewUser = (listMessages[index + 1]["current_time"] == null || listMessages[index]["current_time"] == null) ? false : (listMessages[index]["current_time"] - listMessages[index + 1]["current_time"]).abs() > 600000000;
        }
        
        var firstMessage = index + 1 < length && listMessages[index + 1]["is_datetime"] != null;

        listMessages[index]["isFirst"] = isFirst;
        listMessages[index]["isLast"] = isLast;
        listMessages[index]["showNewUser"] = showNewUser;
        listMessages[index]["firstMessage"] = firstMessage;
        listMessages[index]["index"] = index;
      } catch (e) {
        continue;
      }
    }

    return listMessages;
  }

  getMessageFromApi(idDirectMessage, token, isReset, isLatest, String currentUserId, {bool isNotiffy = true}) async{
    if (!Utils.checkedTypeEmpty(isLatest) ) return await getMessageFromApiDown(idDirectMessage, isReset, token, currentUserId, isNotiffy: isNotiffy);
    return await getMessageFromApiUp(idDirectMessage, token, currentUserId);
  }

  getMessageFromHive(idDirectMessage,int page,int size) async{
    var directMessageBox = Hive.lazyBox("direct_$idDirectMessage");
    var dataKey = directMessageBox.keys.toList();
    var r = dataKey;
    r.sort((a, b) {
      return getTimeKey(a) < getTimeKey(b) ? -1 : 1;
    });
    var listkeyMessage = r;

    // get listKey 
    var length = listkeyMessage.length;
    var start = length - page *size;
    var end = start - size;
    if (start < 0) start = 0;
    if (end < 0) end = 0;
    var listKeys = listkeyMessage.sublist(end, start);

    // get message
    var dataR = [];
     for (var i = 0; i < listKeys.length; i++) {
      // return unix to iso string;
      var key = listKeys[i];
      dataR = [await directMessageBox.get(key)] + dataR;
    }
    return dataR.toList();
  }

  getTimeKey(key) {
    try {        
      var tkey = key.toString().split("__")[0];
      return DateTime.parse(tkey).toUtc().millisecondsSinceEpoch;
    } catch (e) {
      return 0;
    }
  }

  deleteMessage(String token, String convId, Map message, {String type = "delete"})async{
    // message =  %{
    //   "id": "",
    //   "current_time": 232342
    //   "sender_id": "senderId"
    // }

    final url = "${Utils.apiUrl}direct_messages/$convId/delete_messages?device_id=${await Utils.getDeviceId()}&token=$token";
    var response = await Dio().post(url, data: {
      "data": await Utils.encryptServer({
        "data_messages": [message],
        "type": type
      })
    });
    var res = response.data;
    if (res["success"]){
      updateDeleteMessage(token, convId, message["id"], type: type);
    }
  }

  updateDeleteMessage(String token, String conversationId, String messageId, {String type = "delete"}) async {
    try {
      var currentDataDMMessage = getCurrentDataDMMessage(conversationId);
      DirectModel? dm = getModelConversation(conversationId);
      if (dm== null) return;
      String messageSnippetId = dm.snippet["message_id"] ?? "__________";
      Map? localMessage  = await MessageConversationServices.getListMessageById(messageId, conversationId);
      List successIds = await MessageConversationServices.insertOrUpdateMessage({
        "conversation_id": conversationId,
        "id": messageId,
        "action": localMessage!["action"] == "delete_for_me" ? "delete_for_me" : type,
        "message": "",
        "attachments": []
      }, type: "update");
      var indexM = (currentDataDMMessage["messages"] as List).indexWhere((element) => element["id"] == messageId);
      if (indexM != -1) {
        currentDataDMMessage["messages"][indexM]["action"] = currentDataDMMessage["messages"][indexM]["action"] == "delete_for_me" ? "delete_for_me" : type;
        if (type == "delete_for_me") currentDataDMMessage["messages"] = sortMessagesByDay(uniqById(currentDataDMMessage["messages"]));   
      }

      if (successIds.contains(messageSnippetId)){
        updateSnippet({
          ...dm.snippet,
          "action": type
        });
      }

      markReadConversationV2(token, conversationId, successIds as List<String>, [], false);
      notifyListeners();
    } catch (e) {
      print("updateDeleteMessage: $e");
    }
  }
  
  resetStatus(token, String currentUserId) {
    try {
      final idDirectMessage = _directMessageSelected.id;
      dataDMMessages = _data.map((d) {
        // get queue of dm
        var index = dataDMMessages.indexWhere((element) => element["conversation_id"] == d.id);
        Scheduler queue = index == -1 ? Scheduler() : dataDMMessages[index]["queue"];
        Map? conversationKey = index == -1 ? null : dataDMMessages[index]["conversationKey"];
        String? dummyId =  index == -1 ? null : dataDMMessages[index]["dummy_id"];
        if (d.id == idDirectMessage) {
          return {
            ...defaultConversationMessageData,
            "conversation_id": d.id,
            "messages":  sortMessagesByDay(dataDMMessages[index]["messages"]),
            "queue": queue,
            "inserted_at": dataDMMessages[index]["inserted_at"],
            "conversationKey": conversationKey,
            "dummy_id": dummyId,
            "last_current_time": DateTime.now().microsecondsSinceEpoch,
            "latest_current_time": DateTime.now().microsecondsSinceEpoch,
          };
        } else {
          return {
            ...defaultConversationMessageData, 
            "conversation_id": d.id,
            "queue": queue,
            "inserted_at": dataDMMessages[index]["inserted_at"],
            "conversationKey": conversationKey,
            "dummy_id": dummyId,
            "last_current_time": DateTime.now().microsecondsSinceEpoch,
            "latest_current_time": DateTime.now().microsecondsSinceEpoch,
          };
        }
      }).toList();
      if (_directMessageSelected.id != "") getMessageFromApiDown(_directMessageSelected.id, true, token, currentUserId);
      notifyListeners();      
    } catch (e) {
    }
    
  }

  handleSendDirectMessage(Map message, token) async {
    // var dataMessage = {
    //   "message": _message,
    //   "attachments": [],
    //   "title": "",
    //   "conversation_id": "1252453464ghtry34b645",
    //   "show": true,
    //   "id": "",
    //   "user_id": "fgsdgfdgd",
    //   "time_create": "",
    //   "count": 0,
    //   "sending": true,
    //   "success": true,
    //   "fake_id": fakeId,
    //   "current_time": DateTime.now().millisecondsSinceEpoch * 1000,
    //   "isSend": true,
    //   "isThread": true
    // };

    // truong hop gui tin nhan tu hoi thoai dummy, se goi api tao hoi thoaij truoc(them vafo hang doi dau tien)
    // tin nhan dummy cung se dc them vao luon
    var convId  =  message["conversation_id"];
    var indexDM = dataDMMessages.indexWhere((element) => element["conversation_id"] == convId || convId == (element["dummy_id"] ?? "_____"));
    if (indexDM == -1) return;
    var currentDataMessageConversation = dataDMMessages[indexDM];
    if (currentDataMessageConversation["numberNewMessage"] != null) resetOneConversation(convId);
    // set isBlur khi hang doi !=[], neu == [] ko set(mac dinh la false)
    Scheduler queue  = currentDataMessageConversation["queue"];
    if (queue.getLength() != 0) message["isBlur"] = true;
    if (!Utils.checkedTypeEmpty(message["isThread"])){
      if (message["isSend"]){
        await onDirectMessage([message], message["user_id"], false, true, "", null);
      } else {
        await updateDirectMessage(message, false, false, true);
      }
    }
  
    if (currentDataMessageConversation["statusConversation"] == "init") {
      currentDataMessageConversation["statusConversation"] = "creating";
      var indexData = _data.indexWhere((ele) => ele.id == convId);
      queue.schedule(()async { return await createDirectMessage(
        token, {
          "dummy_id": currentDataMessageConversation["conversation_id"],
          "users": _data[indexData].user,
          "name": _data[indexData].name,
        },
        null,
        message["user_id"]
      );});
    }
    queue.schedule(( ) async {return await queueBeforeSend(Map.from(message), token);});
  }

  updateIsBlurMessage(Map message){
    // find message
    var convId = message["conversation_id"];
    var fakeId  = message["fake_id"];
    var indexConv  =  dataDMMessages.indexWhere((element) => element["conversation_id"] == convId);
    if (indexConv == -1) return;
    var indexMessage  =  dataDMMessages[indexConv]["messages"].indexWhere((ele) => ele["fake_id"] == fakeId);
    if (indexMessage == -1) return;
    Map providerMessage  =  dataDMMessages[indexConv]["messages"][indexMessage];
    // print("providerMessage $providerMessage");
    if (providerMessage["sending"]) {
      providerMessage["isBlur"] = true;
      notifyListeners();
    }
  }

  // neu tin nhan da bi mo, no chi cap nhat lai khi gui thanh cong
  Future queueBeforeSend(Map message, token) async{
    try {
      LazyBox box  = Hive.lazyBox('pairKey');
      // sau 2s caajp nhaajt giao dien, neu chua gui xong thi cap nhat isBlur.
      // if (message["isThread"] != null && !message["isThread"])
      //   Timer.run(() async{
      //     await Future.delayed(Duration(seconds: 2));
      //     updateIsBlurMessage(message);
      // });

      // e2eMessagse
      // dam bao tim lai conversation_id doio voi cac tin gui di truoc ca khi hoi thoai dc tao
      var indexConv = dataDMMessages.indexWhere((element) => element["conversation_id"] == message["conversation_id"] || message["conversation_id"] == (element["dummy_id"] ?? "_____"));
      message["conversation_id"] = dataDMMessages[indexConv]["conversation_id"];
      List listMentions =  [];
      // remove dummy uploaf file
      for (var i =0; i < message["attachments"].length; i++){
        if (message["attachments"][i]["type"] == "mention"){
          for( int u = 0; u< message["attachments"][i]["data"].length; u++){
            if (message["attachments"][i]["data"][u]["type"] == "user" || message["attachments"][i]["data"][u]["type"] == "all" ){
              listMentions += [message["attachments"][i]["data"][u]["value"]];
            }
          }
        }
        if (message["attachments"][i]["type"] == "befor_upload")
          message["attachments"][i] = {
            "content_url": message["attachments"][i]["content_url"],
            'preview': message["attachments"][i]["preview"],
            "key": message["attachments"][i]["key"], 
            "mime_type":  message["attachments"][i]["mime_type"],
            "name": message["attachments"][i]["name"],
            "image_data": message["attachments"][i]["image_data"],
            "url_thumbnail" : message["attachments"][i]["url_thumbnail"],
            "key_encrypt" : message["attachments"][i]["key_encrypt"]
          };
      }

      if (listMentions.indexWhere((element) => element == message["conversation_id"]) != -1){
        listMentions =  [message["conversation_id"]];
      }
      var dataMessageToEncrypt = {
        "message": message["message"],
        "attachments": message["attachments"],
        "last_edited_at": Utils.checkedTypeEmpty(message["isSend"]) ? null : DateTime.now().toString()
      };
      var mEncrypt  =  jsonEncode(dataMessageToEncrypt);
      var resultDataToSend = Map.from({...message, "height": 0});
      resultDataToSend["attachments"] = [];    
      resultDataToSend["message"] = "";
      Map dataToSend = {};

      var convKey =  dataDMMessages[indexConv]["conversationKey"];

      if (convKey == null){
        message["success"] = false;
        message["sending"] = false;
        message["isBlur"] = true;
        return updateDirectMessage(message, false, false, true);
      }

      var messageEn = await convKey.encryptMessage(mEncrypt, message["user_id"], Utils.checkedTypeEmpty(message["isThread"]));
      if (!Utils.checkedTypeEmpty(messageEn["success"])) {
        message["success"] = false;
        message["sending"] = false;
        message["isBlur"] = true;
        message["extraError"] = "encrypt messahe faai;";
        return updateDirectMessage(message, false, false, true);
      } 
      dataToSend["message"] =  messageEn["message"];
      dataToSend["pKey_sender"] = convKey.nextPublicKey;
      resultDataToSend["messages"] = [dataToSend];
      resultDataToSend["mentions"] = listMentions;
      resultDataToSend["public_key_sender"] = convKey.getPublicKeySender(message["user_id"]);
      // print("message $message");

      String url = Utils.apiUrl + "direct_messages/" + message["conversation_id"] + "/messages";
      if (!Utils.checkedTypeEmpty(message["isThread"])){
        if (message["isSend"]) {
          url = url + "?token=$token&device_id=${await box.get("deviceId")}";
        } else {
          url = url + "/${message["id"]}/update_messages?token=$token&device_id=${await box.get("deviceId")}";
        }
      } else {
        if (message["isSend"]) {
          url = "${Utils.apiUrl}direct_messages/${message["conversation_id"]}/thread_messages/${message["parentId"]}/messages?token=$token&device_id=${await box.get("deviceId")}";
        } else {
          url = "${Utils.apiUrl}direct_messages/${message["conversation_id"]}/thread_messages/${message["parentId"]}/messages/${message["id"]}/update_messages?token=$token&device_id=${await box.get("deviceId")}";
        }
    
      }    // updateDirectMessage(message, false, false);
      var response = await Dio().post(url, data: {"data": await Utils.encryptServer(resultDataToSend)});
      if (!message["isSend"]) return;
      var dataRes = response.data;
      if (dataRes["success"]) {
        var dm = getModelConversation(message["conversation_id"]);
        dataUnreadMessage[dataRes["data"]["id"]] = {
          "current_time": dataRes["data"]["current_time"],
          "data": dm!.user.map((e) => e["user_id"]).where((element) => element != message["user_id"]).toList()
        };
        await MessageConversationServices.insertOrUpdateMessage({
          ...message,
          ...dataRes["data"], 'parent_id': message['parentId'], 'is_thread': message["isThread"]
        });
        if (!Utils.checkedTypeEmpty(message["isThread"])) {
          if (message["isSend"]){
            updateDirectMessage({
              ...message,
              "current_time": dataRes["data"]["current_time"],
              "isBlur": false,
              "sending": false
            }, false, false, true);
            updateListReadConversation(message["conversation_id"],{
              "last_user_id_send_message": message["user_id"],
              "user_id": message["user_id"],
              "current_time": dataRes["data"]["current_time"]
            });
            updateSnippet(message);
          }
        }
        // message["isBlur"] = false;
        // message["sending"] = false;
        deleteDraftMessage(message["fake_id"]);
        // updateDirectMessage(message, false, false, true);
      }
      if (!dataRes["success"]) {
        message["isBlur"] = true;
        message["success"] = false;
        message["sending"] = false;
        if ("${dataRes["error_code"]}" ==  "219"){
          message["isBlur"] = false;
          deleteDraftMessage(message["fake_id"]);
        } else {
          insetMessageErrorToReSend(message);
        }
        updateDirectMessage(message, false, false, true);
      }
    } catch (e) {
      if (!message["isSend"]) return;
      print("queueBeforSend $e, $message");
      message["isBlur"] = true;
      message["success"] = false;
      message["sending"] = false;
      insetMessageErrorToReSend(message);
      updateDirectMessage(message, false, false, true);
        // all error 500 need to save
        // var box = Hive.lazyBox("messageError");
        // await box.put(message["fake_id"], message);
    }
  }

  insetMessageErrorToReSend(Map message) async {
    try { 
      var currentDirectMessage  = getCurrentDataDMMessage(message["conversation_id"]);
      if (Utils.checkedTypeEmpty(currentDirectMessage) && Utils.checkedTypeEmpty(currentDirectMessage["statusConversation"] == "created")){
        var queueBox = Hive.box('queueMessages');
        var oldData = queueBox.get(message["fake_id"]);
        queueBox.put(message["fake_id"],
          {...message, ...(oldData ?? {})}
        );
      }  
    } catch (e) {
    }
  }

  deleteDraftMessage(id){
    Box boxQueueMessages = Hive.box('queueMessages');
    boxQueueMessages.delete(id);
  }

  getSuggestMention(idDirectMessage, text, token) async{
    final url  = "${Utils.apiUrl}direct_messages/$idDirectMessage/get_mentions?token=$token&text=$text";
    try {
      var  response = await Dio().get(url);
      var resData  =  response.data;
      if (resData["success"]){
        return resData["data"];
      }
      else return [];
    } catch (e) {
      print(e);
      return [];
    }
  }


  resetData() {
    _data = [];
    _dataMessage = [];
    _messagesDirect = [];
    _isFetching = false;
    dataDMMessages = [];
    _selectedFriend = false;
    _selectedMentionDM = false;
  }

  setKey(pairKey){
    _pairKey = pairKey;
  }

  Future<dynamic> uploadThumbnail(String token, workspaceId, file, type) async {
    FormData formData = FormData.fromMap({
      "data": MultipartFile.fromBytes(
        file["path"], 
        filename: file["filename"],
      ),
      "content_type": type,
      "filename": file["filename"]
    });

    final url = Utils.apiUrl + 'workspaces/$workspaceId/contents/v2?token=$token';
    try {
      final response = await Dio().post(url, data: formData);
      final responseData = response.data;
      return responseData;
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  uploadImage(String token, workspaceId, file, type, Function onSendProgress,) async {
    var imageData = file["image_data"];
    if (type == "image") {
      var decodedImage = await decodeImageFromList(file["path"]);
      imageData = {
        "width": decodedImage.width,
        "height": decodedImage.height
      };

      if (file["path"].length > 1299999) {
        img.Image? imageTemp = img.decodeImage(file["path"]);

        if (imageTemp != null) {
          file["path"] = img.encodeJpg(imageTemp, quality: 70);
        }
      }
    }

    String key = "";
    key = (await X25519().generateKeyPair()).secretKey.toString();
    file = {
      ...file,
      "path": base64Decode((await Utils.encrypt(base64Encode(file["path"]), key)))
    };

    var result  = {};
    try {
      final url = Utils.apiUrl + 'workspaces/$workspaceId/contents/v2?token=$token';
      num percent = 0;
      FormData formData = FormData.fromMap({
        "data": MultipartFile.fromBytes(
          file["path"], 
          filename: file["filename"],
        ),
        "content_type": type,
        "mime_type": type,
        "image_data" : imageData,
        "filename": file["filename"],
      });

      final response = await Dio().post(url, data: formData, onSendProgress: (count, total) {
        if ((count*100/total).round() - percent > 1) {
          percent = (count*100/total).round();
          StreamUploadStatus.instance.setUploadStatus(key, count/total);
        }
      });
      final responseData = response.data;
      // remove att type  = "before_upload"
      if (responseData["success"]) {
        result = {
          "success": true,
          "content_url":  Uri.encodeFull(responseData["content_url"]),
          "mime_type": type.replaceAll(".", ""),
          "name": file["name"] ?? "",
          "image_data": imageData ?? responseData["image_data"],
          "filename": file["filename"],
        };
        if (file["mime_type"].toString().toLowerCase() == "mov" || file["mime_type"].toString().toLowerCase() == "mp4") {
          var res = await uploadThumbnail(token, workspaceId, file["upload"], type);
          result["url_thumbnail"] = res["content_url"];
        }
      } 
      else result =  {
        "success": false
      };
    } catch (e, trace) {   
      print("ERRRRRRRRR:   $e __ $trace");
      result =  {
        "success": false
      };
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    return Utils.mergeMaps([result, {"name": file["filename"], "type": "befor_upload", 'preview': file['preview'], "key_encrypt": key}]);
  }

  // luu y, chi luwu khi hoi thoai co trang thai created
  // luon luon luu lai message trong box('queueMessages'), chi xoa khi gui thanh cong, hoac bi loi uniq_contrains index
  // att chi luwu lai duong dan, se khoi tao lai gia tri khi gui di

  sendMessageWithImage(List atts, Map message, token)async {

    if (atts.length == 0) return handleSendDirectMessage(message, token);
    for(var i = 0; i< atts.length; i ++){
      atts[i]["att_id"] = Utils.getRandomString(10);
    }
    // make dummy
    try {
      var noDummyAtts = atts.where((element) => element["content_url"] != null && element["mime_type"] != "share").toList();
      var dummyAtts = atts.where((element) => element["content_url"] == null && element["mime_type"] != "share").map((e) {
        return {
          "att_id": e["att_id"],
          "name": e["name"],
          "type": "befor_upload",
          "progress": "0",
          'preview': e['preview'],
        };
      }).toList();
      message["attachments"] =  (Utils.checkedTypeEmpty(message["attachments"]) ? message["attachments"] : []) + dummyAtts + noDummyAtts;
      if (!Utils.checkedTypeEmpty(message["isThread"])){
        if (message["isSend"])onDirectMessage([message], message["user_id"], false, true, "", null);
        else updateDirectMessage(message, false, null, true);
      } 
      List resultUpload = await Future.wait(
        atts.where((element) => element["content_url"] == null && element["mime_type"] != "share").map((item) async{
          var uploadFile = await getUploadData(item);
          return uploadImage(token, null, uploadFile, uploadFile["mime_type"] ?? "image", (){});
        })
      );
      // create a message that noti user atts upload fail
      List failAtt =  resultUpload.where((element) => !element["success"]).toList();
      List successAtt = resultUpload.where((element) => element["success"]).toList();
      message["attachments"].removeWhere((ele) => ele["type"] == "befor_upload");
      message["attachments"] =  message["attachments"] + noDummyAtts + successAtt;
      if(message["attachments"].length > 0 || message["message"] != ""){
        handleSendDirectMessage(Map.from(message), token);
      }
      if (failAtt.length > 0){
        var messagFail = Map.from(message);
        messagFail["fake_id"] = Utils.getRandomString(20);
        messagFail["current_time"] =  messagFail["current_time"] + 1;
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
      message["isBlur"] = true;
      updateDirectMessage(message, false, false, true);
    }  
    // make a message fail
  }

  removeMessageWhenUploadAttFailed(message){
    try {
      var currentDataDMMessage = getCurrentDataDMMessage(message["conversation_id"]);
      if (currentDataDMMessage != null){
        currentDataDMMessage["messages"] = currentDataDMMessage["messages"].where((e) => e["fake_id"] != message["fake_id"]).toList();
      }      
    } catch (e) {
      print("removeMessageWhenUploadAttFailed: $e");
    }

  }

  createMessageUploadFail(message){
    int indexConverstionCurrent  = dataDMMessages.indexWhere((element) => element["conversation_id"] == message["conversation_id"]);
    if (indexConverstionCurrent != -1){
      dataDMMessages[indexConverstionCurrent]["messages"] = [message] + dataDMMessages[indexConverstionCurrent]["messages"];  
      notifyListeners();
    }
  }

  getUploadData(Map file) async {
    file = {
      ...file,
      "mime_type": file["mime_type"].replaceAll(".", "")
    };
    var data = file["file"];
    var imageData;
    var uploadFile;

    if (file["mime_type"] == "image" || file["type"] == "image") {
      var decodedImage = await decodeImageFromList(file["file"]);
      imageData = {
        "width": decodedImage.width,
        "height": decodedImage.height
      };
    }

    if (file["mime_type"].toString().toLowerCase() == "mov" || file["mime_type"].toString().toLowerCase() == "mp4") {
      await VideoCompress.getByteThumbnail(
        file["path"],
        quality: 50, 
        position: -1 
      ).then((value) async {
        var decodedImage = await decodeImageFromList(value!);
        imageData = {
          "width": decodedImage.width,
          "height": decodedImage.height
        };
        uploadFile = {
          "filename": file["name"],
          "path": value,
          "image_data": imageData
        };
      });
       if(file["mime_type"].toString().toLowerCase() == "mov" && !Platform.isWindows) {
        var pathOther = await getTemporaryDirectory();
        var bytesFile;
        String out = pathOther.path + "/${file["name"].toString().toLowerCase().replaceAll(" ", "").replaceAll(".mov", "")}.mp4";
        File tempFile = File(file["path"]);
        bytesFile = await tempFile.readAsBytes();
        File newFile = File(pathOther.path +  "/${file["name"].toString().toLowerCase().replaceAll(" ", "")}");
        await newFile.writeAsBytes(bytesFile, mode: FileMode.write);
        await FFmpegKit.execute('-y -i ${newFile.path} -c copy $out').then((session) async {
          final returnCode = await session.getReturnCode();
          if(ReturnCode.isSuccess(returnCode)) {
            File u = File(out);
            data = u.readAsBytesSync();
            await u.delete();
            print("Converted Successfully");
          }
          else if (ReturnCode.isCancel(returnCode)) {
            print("Session Cancel");
          }
          else {
            print("Convert Failed");
          }
        });
        await newFile.delete();
      }
    }

    return {
      "filename": file["name"],
      "path": data,
      "length": data.length,
      "mime_type": file["mime_type"],
      "name": file["name"],
      "progress": "0",
      "image_data": imageData,
      "upload" : uploadFile,
      'preview': file['preview'],
    };
  }

  updateSnippet(message) async {
    var box = Hive.box('direct');
    DirectModel? dm = getModelConversation(message["conversation_id"]);
    if (dm == null) return;
    var snippetNew = {
      "message": message["message"],
      "attachments": message["attachments"],
      "conversation_id": message["conversation_id"],
      "user_id": message["user_id"],
      "current_time": message["current_time"],
      "statusSnippet": message["statusSnippet"] ?? "created",
      "message_id": message["id"]
    };
    if (message["current_time"] < (dm.snippet["current_time"] ?? 0)) return;
    if (message["action"] == "insert" || message["action"] == null){
      dm.snippet = snippetNew;
      dm.seen = message["current_time"] <= (dm.userRead["current_time"] ?? 0) ? dm.seen : false;
      box.put(dm.id, dm);
      notifyListeners();  
      return;      
    } else if (message["action"] == "delete"){
      dm.snippet = {
        ...(dm.snippet),
         "message": "[This message was deleted.]",
      };
      dm.seen = message["current_time"] <= (dm.userRead["current_time"] ?? 0) ? dm.seen : false;
      box.put(dm.id, dm);
      notifyListeners();
      return;
    } if (message["action"] == "delete_for_me"){
      Map? lastMessage = await MessageConversationServices.getLastMessageOfConversation(message["conversation_id"]);
      if (lastMessage != null) {
        dm.snippet = {
          "message": lastMessage["action"] == "delete" ?  "[This message was deleted.]" : lastMessage["message"],
          "attachments": lastMessage["attachments"],
          "conversation_id": lastMessage["conversation_id"],
          "user_id": lastMessage["user_id"],
          "current_time": lastMessage["current_time"],
          "statusSnippet": lastMessage["statusSnippet"] ?? "created",
          "message_id": lastMessage["id"]
        };
        dm.seen = true;
        await box.put(dm.id, dm);
        notifyListeners();
      }
    }
  }

  setDataDefault(){
    _data = [];
    notifyListeners();
  }

  handleRequestConversationSync(dataM, context)async {
    //  giai ma data de lay thong tin
    var result ;
    for (var i = 0; i < dataM["device_id"].length; i++){
      var dataDe = await Utils.decryptServer(dataM["device_id"][i]);
      if (dataDe["success"]) {
        result = dataDe["data"];
        break;
      }
    }

    if (result != null) {
      showDialog(
        builder: (BuildContext context) { 
          return Container(
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              insetPadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.all(0),
              content: Container(
                width: 448,
                height: 360,
                child: Center(
                  child: DMConfirmShared(deviceId: result["device_id"], data: dataM),
                )
              )
            )
          );
        },
        context: context
      );
    }
  }

  logoutDevice(data)async{
    LazyBox box  =  Hive.lazyBox('pairKey');
    var deviceId  = await box.get('deviceId');
    _isLogoutDevice = true;
    notifyListeners();
    for(var  i =0; i < data["data"].length; i++){
      Map result  =  await Utils.decryptServer(data["data"][i]);
      if (result["success"]){
        if (deviceId  ==  result["data"]["device_id"]){
          _data = [];
          dataDMMessages = [];
          _errorCode = "";
          notifyListeners();
        }
      }
    }
    _isLogoutDevice = false;
    notifyListeners();
  }

  setUnreadCountConv(data) async{
    // find index
    var conversationId = data["conversation_id"];
    var index  =  _data.indexWhere((element) => element.id == conversationId);
    if (index  == -1) return;
    DirectModel dm  =  _data[index];
    dm.newMessageCount = 0;
    dm.seen = true;
    notifyListeners();
  }


  reGetDataDiectMessage(token, String currentUserId) {
    queueReGetDataDiectMessage.scheduleOne(() {
      return getDataDirectMessage(token, currentUserId);
    });
  }

  setSelectedMention(value){
    _selectedMentionDM  = value;
    _selectedFriend = false;
    notifyListeners();
  }


  Future<dynamic> getMentionConversations(String token) async {
    if (!Utils.checkedTypeEmpty(  _dataMentionConversations["isFetching"])){
      _dataMentionConversations["isFetching"] = true;
      String url = "${Utils.apiUrl}users/mention_conversations?token=$token";
      try {
        var response = await Dio().get(url);
        var resData = response.data;
        if (resData["success"]){
          List  dataResult = [];
          for(int i = 0; i < resData["data"].length; i++){
            var dataMention ;
            try {
              dataMention =  await decryptMessageMention(resData["data"][i]);
            } catch (e) {
            }
            if (dataMention == null){
              try {
                dataMention = await MessageConversationServices.getListMessageById(resData["data"][i]["message"]["id"], "");
                if (dataMention != null) 
                dataMention =  [Utils.mergeMaps([
                  resData["data"][i],
                  {
                    "message": dataMention, 
                    "name": getConversationName(resData["data"][i]["conversation_id"]) ?? ""
                  }]
                )];
              } catch (e) {
              }
            }
            if (dataMention != null) dataResult += dataMention;
          }
          _dataMentionConversations["isFetching"] = false;
          _dataMentionConversations["data"] = dataResult;
        }
        notifyListeners();
      } catch (e) {
        _dataMentionConversations["isFetching"] = false;
        print("gdfgjhgfkghjv $e");
      }
    }
  }

  getConversationName(String idConversation){
    var indexConversation = _data.indexWhere((element) => element.id  ==idConversation);
    if (indexConversation == -1) return null;
    return _data[indexConversation].name != "" ? _data[indexConversation].name : _data[indexConversation].user.map((u) => u["full_name"]).toList().join(", ");
  }
   
  decryptMessageMention(dataMentionConversation) async {
    // lay ten conversation
    var indexConversation = _data.indexWhere((element) => element.id  == dataMentionConversation["conversation_id"]);
    if (indexConversation == -1) return null;
    String name  =  _data[indexConversation].name != "" ? _data[indexConversation].name : _data[indexConversation].user.map((u) => u["full_name"]).toList().join(", ");
    // print("_data[indexConversation].name ${_data[indexConversation].name}   ${_data[indexConversation].user}");
    var indexConversationData = dataDMMessages.indexWhere((element) => element["conversation_id"] == dataMentionConversation["conversation_id"]);
    if (indexConversationData != -1){
      var  dataDecrypt = await dataDMMessages[indexConversationData]["conversationKey"].decryptMessage(dataMentionConversation["message"]);

      // print("dataDecrypt,m $dataMentionConversation $dataDecrypt");
      if (dataDecrypt == null || !dataDecrypt["success"]){
        var boxHive   =  await Hive.openLazyBox("direct_" + dataMentionConversation["conversation_id"]);
        String key = dataMentionConversation["message"]["time_create"] == null ? DateTime.now().add(new Duration(hours: -7)).toIso8601String() : dataMentionConversation["message"]["time_create"];
        key += "__${dataMentionConversation["message"]["id"]}";
        dataDecrypt = await boxHive.get(key);
        if (Utils.checkedTypeEmpty(dataDecrypt)){
          return  [Utils.mergeMaps([dataMentionConversation, {"message": dataDecrypt, "name": name}] )];
        }
        return null;
      } else {
        return [Utils.mergeMaps([dataMentionConversation, {"message": dataDecrypt["message"], "name": name}] )];
      }
    }
   }

  newMentionConversation(mention) async {
    var dataMention =  await decryptMessageMention(mention);
    if (dataMention == null){

    } else {
      _dataMentionConversations["data"] = [] + dataMention + _dataMentionConversations["data"];
      _dataMentionConversations["seen"] = !_selectedMentionDM;
      notifyListeners();
    }
  }

  setMessageConversationFromMention(idDirectMessage, Map message){
    var currentDataMessageConversations = getCurrentDataDMMessage(idDirectMessage);
    if (currentDataMessageConversations == null) return;

    var indexMessage =  currentDataMessageConversations["messages"].indexWhere((ele) => ele["id"] == message["id"]);
    if (indexMessage == -1){
      currentDataMessageConversations["active"] = true;
      currentDataMessageConversations["latest_current_time"] = message["current_time"];
      currentDataMessageConversations["last_current_time"] = message["current_time"];
      currentDataMessageConversations["messages"] =  [Utils.mergeMaps([
        message,
        {"showSkeleton": true, "isFromMention": true}
      ])];
    }
    else {
      currentDataMessageConversations["messages"][indexMessage] = Utils.mergeMaps([
        currentDataMessageConversations["messages"][indexMessage],
        {"isFromMention": true}
      ]);
    }
    notifyListeners();

  }

  setIdMessageToJump(id){
    _idMessageToJump = id;
    notifyListeners();
  }

  void checkDeviceRequestSyncDataFromNotification(Map dataDevice, String token, BuildContext context) async {
    try {
      final url = "${Utils.apiUrl}/direct_messages/check_device_request_from_notification?token=$token&device_id=${await Utils.getDeviceId()}";
      var res = await Dio().post(url, data: {
      "data": await Utils.encryptServer({
        "device_id_request": dataDevice["device_id"],
        "current_time": DateTime.now().millisecondsSinceEpoch
      })
    });
    if (res.data["success"]){
      var data  = await Utils.decryptServer(res.data["data"]);
      showDialog(
        builder: (BuildContext context) { 
          return Container(
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              insetPadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.all(0),
              content: Container(
                width: 448,
                height: 360,
                child: Center(
                  child: DMConfirmShared(deviceId: data["data"]["device_id_request"], data: dataDevice),
                )
              )
            )
          );
        },
        context: context
      );
    }
    } catch (e) {
      print("r_________ $e");
    }
  }
  
  // remove
  setHideConversation(idDirectMessage, isHide, context) async{
    return;
    // if (context == null) return;
    // List listDm = Provider.of<DirectMessage>(context, listen: false).data.toList();
    // var index = listDm.indexWhere((element) => element.id == idDirectMessage);
    // var directMessage;

    // if (index != -1) { 
    //   directMessage = listDm[index];
    //   final token = Provider.of<Auth>(context, listen: false).token;
    //   LazyBox box = Hive.lazyBox('pairKey');
    //   final url = "${Utils.apiUrl}direct_messages/$idDirectMessage/set_hide?token=$token&device_id=${await box.get("deviceId")}";
    //   try {
    //     var response = await Dio().post(url, data: {"data": await Utils.encryptServer({"hide": isHide})});
    //     var dataRes = response.data;

    //     if (dataRes["success"]) {
    //       var newD = DirectModel(
    //         directMessage.id,
    //         directMessage.user,
    //         directMessage.name,
    //         true, 0,
    //         directMessage.snippet, 
    //         isHide,
    //         directMessage.updateByMessageTime
    //       );
    //       Provider.of<DirectMessage>(context, listen: false).setDirectMessage(newD, token);
    //     }
    //   } catch (e){
    //     print(e);
    //     // sl.get<Auth>().showErrorDialog(e.toString());
    //   }
    // }
  }

  updateOnlineStatus(Map data){
    // data  = {
    //   "user_id": "",
    //   "is_online": true/false
    // }
    _data.map((e) {
      int indexUser  = e.user.indexWhere((element) => element["user_id"] == data["user_id"]);
      if (indexUser != -1){
        e.user[indexUser]["is_online"] = data["is_online"];
      }
    }).toList();

    notifyListeners();
  }

  // khi dang ko focus app, khi dang ko trong view, va khong phai tin nhan cua minh
  markNewMessage(Map message, context){
    try {
      if (message["user_id"] == Provider.of<Auth>(context, listen: false).userId) return;
      var conversationId = message["conversation_id"];
      var isFocusApp = Provider.of<Auth>(context, listen: false).onFocusApp;
      if (
        (directMessageSelected.id != message["conversation_id"])
        || ((directMessageSelected.id == conversationId) && !isFocusApp)
      ){
        var currentDataDMMessage = getCurrentDataDMMessage(conversationId);
        if (!Utils.checkedTypeEmpty(currentDataDMMessage["last_message_readed"]))
          currentDataDMMessage["last_message_readed"] = message["id"];
      }
    } catch (e) {
    }
  }

  removeMarkNewMessage(String idConversation){
    try {
      var conversationId = idConversation;
      var currentDataDMMessage = getCurrentDataDMMessage(conversationId);
      if (Utils.checkedTypeEmpty((currentDataDMMessage["last_message_readed"]))){
        currentDataDMMessage["last_message_readed"] = "";
        notifyListeners();
      }
    } catch (e) {
    }
  }

  // luu lai context cua tin nhan
  // moi khi can lay height = context.size!.height ?? 0
  void updateHeightMessage(conversationId, id, BuildContext context) {
    try {
      var currentDataDMMessage = getCurrentDataDMMessage(conversationId);
      var indexMessage = (currentDataDMMessage["messages"] as List).indexWhere((element) => element["id"] == id);
      if (indexMessage != -1){
        currentDataDMMessage["messages"][indexMessage]["height"] = context;
      }
    } catch (e) {
    }
  }

  // xu ly message de nhay den nhay den
  Future<void> processDataMessageToJump(Map message, String token, String currentUserId) async {
    var conversationId = message["conversation_id"];
    var indexDM = _data.indexWhere((dm) => dm.id  == conversationId);

    Map? messageRoot = await MessageConversationServices.getListMessageById(message["id"], message["conversation_id"]);
    if (messageRoot == null) return;

    if (indexDM == -1) return;
    // neu message nhay den chua co
    // + Reset tat conversationDataMessage ve mac dinh
    // goij api load 2 chiefutinhs tu message jump
    // cap nhat new_message_countve 0
    // new co tin nhan moi, 
    // scroll xuong den khi nao khong the load moi dc nua
    // hoac click vafoso tin moi => reset laij hoi thoaij
    // neu gui tin moi => reset lai hoi thoai
    // viec nhay den tin nhan do view hien thi dam nhan
    var indexDataMessage = dataDMMessages.indexWhere((element) => element["conversation_id"] == conversationId);
    if (indexDataMessage == -1) return;
    dataDMMessages[indexDataMessage] = {
      ...defaultConversationMessageData,
      ...dataDMMessages[indexDataMessage],
      "latest_current_time": messageRoot["current_time"],
      "last_current_time": messageRoot["current_time"],
      "messages": [],
      "isFetching": true,
      "isFetchingUp": true,
      "disableLoadDown": false,
      "disableLoadUp": false,
      "disableHiveDown": false,
      "disableHiveUp": false,
      "numberNewMessage": 0,
    };

    notifyListeners();

    Future getDown() async{
      await getMessageFromHiveDown(conversationId, messageRoot["current_time"], token, currentUserId, forceLoad: true);
    }

    Future getUp() async{
      await getMessageFromHiveUp(conversationId, messageRoot["current_time"], "", currentUserId, limit: 10, includeRootMessage: true, forceLoad: true);
    }
    await Future.delayed(Duration(milliseconds: 250));
    await Future.wait([
      getDown(),
      getUp()
    ]);
    var currentDataDMMessage = getCurrentDataDMMessage(conversationId);

    currentDataDMMessage["messages"] = sortMessagesByDay(uniqById( [] + [messageRoot] + currentDataDMMessage["messages"]));
    setIdMessageToJump(message["id"]);
    setSelectedDM(_data[indexDM], ""); 
    setSelectedMention(false);
    notifyListeners();
    
  }


// khoi phuc 1 conversation ve mac dinh
  resetOneConversation(String conversationId){
    var indexDataMessage = dataDMMessages.indexWhere((element) => element["conversation_id"] == conversationId);
    if (indexDataMessage == -1) return;
    dataDMMessages[indexDataMessage] = {
      ...defaultConversationMessageData,
      "conversation_id": conversationId,
      "inserted_at": dataDMMessages[indexDataMessage]["inserted_at"],
      "conversationKey": dataDMMessages[indexDataMessage]["conversationKey"],
      "queue": dataDMMessages[indexDataMessage]["queue"],
      "dummy_id": dataDMMessages[indexDataMessage]["dummy_id"],
      "last_current_time": DateTime.now().microsecondsSinceEpoch,
      "latest_current_time": DateTime.now().microsecondsSinceEpoch,
    };
    notifyListeners();
  }

  findConversationFromListUserIds(List userids){
    try {
      var index = _data.indexWhere((element) => 
        MessageConversationServices.shaString(element.user.map((u) => u["user_id"]).toList())
        == MessageConversationServices.shaString(userids)
      );
      return _data[index];
    } catch (e) {
      return null;
    }
  }

  getTextDescriptionSyncData(){
    try {
      if ("$errorCode" == "203" ){
      if (_deviceCanCreateOtp.length == 0) return "You must logout all device";
      String nameDevice = _deviceCanCreateOtp.map((e) => e["name"]).toList().join(" or ");
      return "Open Panchat app on $nameDevice to get OTP and tap 'Sync data'";
    }
    return "";
    } catch (e) {
      return "Open Panchat app on others devices to get OTP and tap 'Sync data'";
    }
  }

// ham nay chi dc su dung khi them nguoi dung khi hoi thoai dang trong trang thai init
// vi luc nay hoi thoai chua that su dc tao nen ko can goi api, 
// chi remove khi hoi thoai >= 3 nguoif
  inviteMemberWhenConversationInDummy(user, idConversation){
    var indelInData = _data.indexWhere((element) => element.id == idConversation);
    if (indelInData == -1) return;
    DirectModel currentDataConv = _data[indelInData];
    var isExisted = currentDataConv.user.indexWhere((element) => element["user_id"] == user["id"]);
    var newDataConvUser = isExisted != -1 
    ? currentDataConv.user.where((element) => element["user_id"] != user["id"]).toList()
    : ([] + currentDataConv.user + [{...user, "user_id": user["id"]}]);
    // only remove
    if (newDataConvUser.length < 3) return;
    currentDataConv.user = newDataConvUser;
    currentDataConv.name = getNameDM(newDataConvUser, "", currentDataConv.name, hasIsYou: false);
    if (_directMessageSelected.id == idConversation) _directMessageSelected = currentDataConv;
    notifyListeners();

  }

  changeNameConvDummy(value, idConversation) {
    var indelInData = _data.indexWhere((element) => element.id == idConversation);
    if (indelInData == -1) return;
    DirectModel currentDataConv = _data[indelInData];
    currentDataConv.name =  Utils.checkedTypeEmpty(value) ? value : getNameDM(currentDataConv.user, "", currentDataConv.name, hasIsYou: false);
  
    if (_directMessageSelected.id == idConversation) _directMessageSelected = currentDataConv;
    notifyListeners();

  }

  cutOldMessageOnConversation(String directId) {
    dataDMMessages = dataDMMessages.map((conv) {
      if (conv["conversation_id"] == directId) return conv;
      bool isCut = (conv["messages"] as List).length > 60;
      if (!isCut) return conv;
      List newListCuted = uniqById(isCut ? conv["messages"].sublist(0, 60): conv["messages"]);
      return {
        ...defaultConversationMessageData,
        ...conv,
        "messages": newListCuted,
        "last_current_time": newListCuted.length > 0 ? newListCuted.first["current_time"] : DateTime.now().microsecondsSinceEpoch,
        "disableLoadDown": false,
        "disableHiveDown": false
      };
    }).toList();
  }

  List getMessageErrorSavedOnHive(idConv){
    var boxQueueMessage = Hive.box('queueMessages');
    List messageQueues = boxQueueMessage.values
      .where((ele) => ele["conversation_id"] == idConv)
      .map((e) {return {...e, "current_time": DateTime.now().millisecondsSinceEpoch * 1000};})
      .toList();
    return messageQueues; 
  }

  checkReSendMessageError(token) async {
    try {
      var box = Hive.box('queueMessages');
      // ignore: unnecessary_null_comparison
      List queueMessages = box.values.toList().where((e) => Utils.checkedTypeEmpty(e["conversation_id"])).toList();
      queueMessages.sort((a, b) => a["current_time"].compareTo(b["current_time"]));
      for(var i = 0; i< queueMessages.length; i++){
        var dataMessage = queueMessages[i];
        if (dataMessage["retries"] == 0 || (!Utils.checkedTypeEmpty(dataMessage["message"]) && dataMessage["attachments"].length == 0)) {
          box.delete(dataMessage["fake_id"]);
          continue;
        }
        box.put(queueMessages[i]["fake_id"], {
          ...(queueMessages[i] as Map),
          "retries": ((queueMessages[i] as Map)["retries"] ?? 5) - 1
        });

        print("reSend: ${queueMessages[i]}");
        queueBeforeSend(queueMessages[i], token);
      }      
    } catch (e) {
    }  
  }

  // roi hoi thaoi, set lai _directMessageSelected 
  void leaveConversation(String conversationId, String token, String currentUserId) async {
    var url ="${Utils.apiUrl}/direct_messages/leave_conversation?token=$token&device_id=${await Utils.getDeviceId()}";
    Dio().post(
      url,
      data: {
        "data": await Utils.encryptServer({
          "conversation_id": conversationId,
          "key": Utils.getRandomString(10)
        })
      }
    ).then((value) async {
      if(value.data["success"]) {
        int index = _data.indexWhere((ele) => ele.id == conversationId);
        if(index != -1) _data.removeAt(index);

        if (_directMessageSelected.id == conversationId){
         leaveOrDeleteConversation(conversationId, currentUserId);
        }

        notifyListeners();
        getDataDirectMessage(token, currentUserId, isReset: true);
      }
    });
  }

  leaveOrDeleteConversation(String conversationId, String currentUserId) async {
    _data = _data.where((element) => element.id != conversationId).toList();
    _directMessageSelected = _data.where((element) => element.id != conversationId).toList()[0];
    var boxSelect = await  Hive.openBox('lastSelected');
    boxSelect.put("lastConversationId", _directMessageSelected.id);
  }

  DirectModel? getModelConversation(String? idConversation){
    try {
      _data.map((e) => print(e));
      var index  = _data.indexWhere((element) {
        return  "${element.id}" == "$idConversation";
      });  
      return _data[index];    
    } catch (e) {
      return null;
    }
  }

  String getNameDM(List users, String userId, String name, {bool hasIsYou = true}){
    try {
      if (name != "") return name;
      if (users.length == 1) return users[0]["full_name"];
      var result = "";
      List userInConv = users;
      bool isGroup = userInConv.length > 2;
      for (var i = 0; i < userInConv.length; i++) {
        if (userInConv[i]["user_id"] == userId || (userInConv[i]["status"] != null && userInConv[i]["status"] != "in_conversation")) continue;
        if (i != 0 && result != "") result += ", ";
        result += userInConv[i]["full_name"];
      }
      return (isGroup && hasIsYou ? "You, " : "" )+  result;      
    } catch (e) {
      return "";
    }
  }


  getInfoUnreadMessage(List messages, String token, String conversationId) async {
    try {
      // chi tinh message do minh gui di
      final url = "${Utils.apiUrl}direct_messages/$conversationId/get_info_message?token=$token&device_id=${await Utils.getDeviceId()}";
      final response = await Dio().post(url, data: {
        "data" : await Utils.encryptServer({
          "message_ids": messages.map((e) => e["id"]).toList()
        })
      });
      dataInfoThreadMessage = {
        ...dataInfoThreadMessage,
        ...(response.data["data_thread"] ?? {})
      };
      await Future.wait(((response.data["data_thread"] ?? {}) as Map).keys.map((idMessage) async {
        MessageConversationServices.insertOrUpdateMessage({
          "id": idMessage,
          "count": dataInfoThreadMessage[idMessage]["count"],
          "conversation_id": conversationId
        }, type: "update");
      }));
      dataUnreadMessage = {
        ...dataUnreadMessage,
        ...(response.data["data"] ?? {})
      };

      notifyListeners();    
    } catch (e) {
      print("getInfoUnreadMessage: $e");
    }
  }

  dataMessageUnread(data){
    List keys = (data as Map).keys.toList();
    for(var i = 0; i < keys.length ; i++){
      var key = keys[i];
      var oldData = dataUnreadMessage[key] ?? {};
      if (int.parse("${data[key]["current_time"]}") > int.parse("${(oldData[key] ?? {})["current_time"] ?? 0}")) dataUnreadMessage[key] = data[key];
    }
  }

  updateThreadUser(data){
    var newData = data["data"]["data_thread"];
    // newData  = %{
    //   "thread_id" => id_thread,
    //   "message_id" => message_id,
    //   "is_read" => true
    // }

    dataInfoThreadMessage[newData["message_id"]] = {
      ...((dataInfoThreadMessage[newData["message_id"]] ?? {}) as Map),
      ...(newData as Map)
    };
    notifyListeners();
  }

  Future loadUnreadMessage(String token) async {
    try {
      final url = '${Utils.apiUrl}direct_messages/get_all_message_unread?token=$token&device_id=${await Utils.getDeviceId()}';
      var response = await Dio().get(url);
      var res = response.data;
      List dataMessages =  res["data"] as List;
      List dataSuccess =(await Future.wait(dataMessages.map((message) async {
        try {
          if (message["action"] == "delete" || message["action"] == "delete_for_me") return message;
          var currentDataDMMessage = getCurrentDataDMMessage(message["conversation_id"]);
          var convKey = currentDataDMMessage["conversationKey"];
          var decrypted = await convKey.decryptMessage(message);
          if (decrypted["success"]){
            return decrypted["message"];
          }
          return null;
        } catch (e) {
          return null;
        }

      }))).where((element) => element != null).toList();
      List successIdMessages = await MessageConversationServices.insertOrUpdateMessages(dataSuccess);
      // if (successIdMessages.length > 0) resetStatus(token);
      var grouped = dataSuccess.groupBy("conversation_id");
      grouped.map((dataConv){
        var convId  = ((dataConv as Map).keys.toList())[0];
        List<String> successIds = (dataConv[convId] as List).map((e) => e["id"].toString()).where((element) => successIdMessages.contains(element)).toList();
        // update laij snippet
        try {
          updateSnippet((dataConv[convId] as List).where((ele) =>  successIdMessages.contains(ele["id"]) && !Utils.checkedTypeEmpty(ele["parent_id"])).toList()[0]);
        } catch (e) {
          print("update snnnnn: $e");
        }
        markReadConversationV2(token, convId, successIds, [], false);
      }).toList();
    } catch (e) {
      print("loadUnreadMessage: $e");
    }
  }

  Future updateSettingConversationMember(String convId, Map change, String token, String userId) async {
    try {
      String url = "${Utils.apiUrl}direct_messages/$convId/setting_member?token=$token&device_id=${await Utils.getDeviceId()}";
      var response = await Dio().post(url, data: {
        "data": await Utils.encryptServer(change)
      });
      print("response:$convId ${response.data}");
      if (response.data["success"]){
        DirectModel? dm = getModelConversation(convId);
        if (dm == null) return;
        var indexUser = dm.user.indexWhere((element) => element["user_id"] == userId);
        if (indexUser == -1) return;
        dm.user[indexUser] = {
          ...(dm.user[indexUser] as Map),
          ...change
        };
        if (_directMessageSelected.id == convId) {
          _directMessageSelected = dm;
        }

        notifyListeners();
      }      
    } catch (e) {
    }
  }

  void changeConversationName(Map data, String currentUserId) {
    try {
      var convId = data["conversation_id"];
      var dm = getModelConversation(convId);
      if (dm != null) {
        dm.name = data["name"];
        dm.displayName = getNameDM(dm.user, currentUserId, data["name"]);
        var box = Hive.box("direct");
        box.put(dm.id, dm);
        notifyListeners();
      }      
    } catch (e) {
    }
  }

  Future deleteHistoryConversationApi(String token, String conversationId, String currentUserId) async {
    try {

      DirectModel? dm = getModelConversation(conversationId);
      if(dm == null) return;
      var url = "${Utils.apiUrl}direct_messages/${dm.id}/delete_history?token=$token&device_id=${await Utils.getDeviceId()}";
      var response = await Dio().post(url, data: {
        "data": await Utils.encryptServer({
          "conversation_id": dm.id,
        })
      });
      if (response.data["success"]){
        
      }      
    } catch (e) {
    }
  
  }

  void deleteHistoryConversation(Map? data, userId) {
    try {
      if (data == null) return;
      var convId = data["conversation_id"];
      var time = data["time"];
      MessageConversationServices.deleteHistoryConversation(convId, userId, time);
      DirectModel? dm = getModelConversation(convId);
      if (dm == null) return;
      if ((dm.snippet["current_time"] ?? 0 )<= time) dm.snippet = {};
      var box = Hive.box('direct');
      box.put(dm.id, dm);
      int indexUser = dm.user.indexWhere((element) => element["user_id"] == userId);
      dm.user[indexUser]["delete_time"] = time;
      resetOneConversation(convId);
    } catch (e) {
    }
  }

  void updateConversation(data, token, userId) {
    int index = _data.indexWhere((DirectModel ele) => ele.id == data['conversation_id']);

    if(index != -1) {
      _data[index]..avatarUrl = data['changes']['avatar_url'];
      if(_directMessageSelected.id == data['conversation_id']) _directMessageSelected..avatarUrl = data['changes']['avatar_url'];
      notifyListeners();
    }
  }
}

 extension UtilListExtension on List{
  groupBy(String key) {
    try {
      List<Map<String, dynamic>> result = [];
      List<String> keys = [];

      this.forEach((f) => keys.add(f[key]));

      [...keys.toSet()].forEach((k) {
        List data = [...this.where((e) => e[key] == k)];
        result.add({k: data});
      });

      return result;
    } catch (e) {
      // printCatchNReport(e, s);
      return this;
    }
  }
}