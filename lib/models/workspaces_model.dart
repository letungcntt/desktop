import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:workcake/common/http_exception.dart';

import 'package:workcake/common/utils.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/services/sharedprefsutil.dart';

import 'models.dart';

class WorkspaceItem {
  final id;
  final name;
  final ownerId;
  final settings;

  WorkspaceItem({this.id, this.name, this.ownerId, this.settings});
}

class Workspaces with ChangeNotifier {
  List _members = [];
  List _data = [];
  Map _currentWorkspace = {};
  int _selectedTab = 0;
  bool _loading = false;
  Map _currentMember = {};
  String _message = "";
  bool _changeToMessage = true;
  List _emojis = [];
  List _mentions = [];
  bool _selectMentionWorkspace = false;
  List _listChannelMembers = [];
  List _preloadIssues = [];

  List get mentions => _mentions;
  List get emojis => _emojis;
  List get members => _members;
  List get data => _data;
  Map get currentWorkspace => _currentWorkspace;
  bool get loading => _loading;
  Map get currentMember => _currentMember;
  String get message => _message;
  bool get changeToMessage => _changeToMessage;
  bool get selectMentionWorkspace => _selectMentionWorkspace;
  List get listChannelMembers => _listChannelMembers;
  List get preloadIssues => _preloadIssues;

  Workspaces() {
    getTab().then((value) {
      _selectedTab = value;
      notifyListeners();
    });
  }

  Future<dynamic> setNullMentions(value) async {
    _selectMentionWorkspace = value;
    // if (value) _isUnread = false;
    notifyListeners();
  }

  int get tab => _selectedTab;
  set tab(int value) => setTab(value);

  void setTab(value) {
    _selectedTab = value;
    sl.get<SharedPrefsUtil>().setTab(value);
    notifyListeners();
  }

  Future<dynamic> changeToMessageView(value) async {
    _changeToMessage = value;
    notifyListeners();
  }

  Future<int> getTab() async {
    final tab = sl.get<SharedPrefsUtil>().getTab();
    return tab;
  }

  Future<dynamic> getListWorkspace(context, String token) async {
    final currentUserId = Provider.of<Auth>(context, listen: false).userId;
    var snapshot = await Hive.openBox("snapshotData:$currentUserId");
    final url = Utils.apiUrl + 'workspaces?token=$token';

    _data = snapshot.get("workspaces") ?? [];
    Provider.of<Channels>(context, listen: false).setDataChannels(snapshot.get("channels") ?? []);

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _data = _mergeSnapshotWithData(_data, responseData["workspaces"]);
        _listChannelMembers = responseData["list_channel_members"];
        Provider.of<Channels>(context, listen: false).setDataChannels(responseData["channels"]);

        snapshot.put("workspaces", _data);
        snapshot.put("channels", responseData["channels"]);

        getLastInfoWorkspaceAndChannel(context);

        var data = _data.map((e){
          e["isShowChannel"] = true;
          e["isShowPinned"] = false;
          e["emojis"] =  e["emojis"].map((e) {
            List split = (Utils.unSignVietnamese(e["name"]).split(" "));
            var emojiId = split.where((ele) => ele.length > 0).toList().join("_");
            return {...e, "type": "custom", "emoji_id": emojiId};
          }).toList();
          return e;
        }).toList();
        var box = await Hive.openBox("stateShowPinned:$currentUserId");
        var _boxData = box.get("data");
        if (_boxData == null) {
          box.put("data", data);
        }
        _data = data;
        _mentions = data.map((e) => {
          "fetching": false,
          "workspace_id": e["id"],
          "data": [],
          "disableLoadMore": false,
          "unread": e["un_read_mention"]
        }).toList();
        // neu co currentWorkspace reload laij metiooj
        getMentions(token, _currentWorkspace["id"], false);
      } else {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  getLastInfoWorkspaceAndChannel(context) {
    var box = Hive.box('lastSelected');
    var lastChannelId = box.get('lastChannelId');
    var isChannel = box.get('isChannel');
    var lastChannelSelected = box.get("lastChannelSelected");
    Provider.of<Channels>(context, listen: false).setLastChannelFromHive(lastChannelSelected ?? []);
    final auth = Provider.of<Auth>(context, listen: false);
    final channels = Provider.of<Channels>(context, listen: false).data;

    if (lastChannelId != null && isChannel == 1) {
      final index = channels.indexWhere((e) => e["id"] == lastChannelId);

      if (index != -1) {
        final channel = channels[index];
        final workspaceId = channel["workspace_id"];
        Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(auth.token, workspaceId, context);
        Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channel["id"]);
      } 
    } 
  }

  changeListChannelMembers(data) {
    final channelId = data["new_user"]["channel_id"];
    final workspaceId = data["new_user"]["workspace_id"];
    final userId = data["new_user"]["id"];
    int index = _listChannelMembers.indexWhere((e) => e["id"] == channelId && e["workspace_id"] == workspaceId);
    if (index != -1) {
      // khi nguoi khac tham gia add members
      int indexUser = _listChannelMembers[index]["members"].indexWhere((e) => e == userId);
      if(indexUser == -1) _listChannelMembers[index]["members"].add(userId);
    } else {
      _listChannelMembers.add({
        "id": channelId,
        "workspace_id": workspaceId,
        "members": [userId]
      });
    }
  }

  Future<dynamic> selectWorkspace(String token, int workspaceId, context) async {
    var index = _data.indexWhere((element) => element["id"] == workspaceId);
    if (index != -1){
      _currentWorkspace = _data[index];
      await Provider.of<Threads>(context, listen: false).getThreadsDesktop(token, workspaceId, false);
    }

    notifyListeners();
  }

  Future<dynamic> getInfoWorkspace(String token, int workspaceId, context) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId?token=$token';
    try{
      final response = await Utils.getHttp(url);

      if (response["success"] == true) {
        if (response["workspace"]["id"] != currentWorkspace["id"]) return;
        _members = response["member"];
        _currentMember = response["current_member"];
        Provider.of<Channels>(context, listen: false).getChannelMembers(_listChannelMembers, _members, workspaceId);
      } else {
        throw HttpException(response['message']);
      }
    } catch(e){
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  onSelectWorkspace(context, workspaceId) {
    final auth = Provider.of<Auth>(context, listen: false);
    setTab(workspaceId);
    selectWorkspace(auth.token, workspaceId, context);
    getInfoWorkspace(auth.token, workspaceId, context);
    getMentions(auth.token, workspaceId, false);
    Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);
    final selectedMentionWorkspace = selectMentionWorkspace;
    if (selectedMentionWorkspace) {
      auth.channel.push(event: "read_workspace_mentions", payload: {"workspace_id": workspaceId});
    }

    if(Platform.isMacOS) {
      Timer(Duration(seconds: 0), () {
        Utils.updateBadge(context);
      });
    }
  }

  updateCurrentMember(data) {
    _currentMember = data;
    notifyListeners();
  }

  Future<dynamic> changeRoleWs(String token, String userId, int roleId) async {
    final url = Utils.apiUrl + 'workspaces/${_currentWorkspace['id']}/change_role_ws?token=$token';
    try {
      final body = {
        "user_id": userId,
        "role_id": roleId
      };
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);
      if (Utils.checkedTypeEmpty(responseData["success"])) {
        _members = responseData["members"];
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
    }

    notifyListeners();
  }

  Future<dynamic> createWorkspace(context, String token, String name, contentUrl) async {
    final url = Utils.apiUrl + 'workspaces?token=$token';
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    try {
      Response response = await Dio().post(
        url,
        // headers: Utils.headers,
        data: json.encode({'name': name, 'content_url': contentUrl}),
      );

      final responseData = response.data;
      if (responseData["success"] == true) {
        _data = [responseData["workspace"]]  +  _data;
        var channel = responseData["channel"];
        channel["snippet"] = {};
        channel["user_count"] = 1;
        _currentMember = {
          "user_id": currentUser["id"],
          "role_id": 1,
          "notify": true ,
          "nickname": currentUser["full_name"],
          "number_unread_threads": 0
        };
        _members = [];
        _members.add(currentUser);
        _listChannelMembers.add({
          "workspace_id": responseData["workspace"]["id"],
          "id": channel["id"],
          "members": [currentUser["id"]]
        });
        Provider.of<Channels>(context, listen: false).insertDataChannel({
          ...channel,
          "user": currentUser
        });
      } else {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> inviteToWorkspace(String token, workspaceId, text, type, userId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/send_invitation?token=$token';
    try{
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({'id': userId, 'text': text, 'type': type}));
      final responseData = json.decode(response.body);

      _message = responseData['message'] ?? "";
    } catch(e, trace) {
      print("$e $trace");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    if (type == 1) {
      var key = "$workspaceId";
      var box = Hive.box('invitationHistory');
      List invitationHistory = box.get(key) ?? [];
      final index = invitationHistory.indexWhere((e) => e['email'] == text);
      DateTime now = DateTime.now();

      if (index == -1) {
        invitationHistory.insert(0, {'email': text, 'date': now});
        if (invitationHistory.length > 10) invitationHistory.sublist(0, 9);
        box.put(key, invitationHistory);
      } else {
        invitationHistory[index] =  {'email': text, 'date': now};
        box.put(key, invitationHistory);
      }
    }

    return _message;
  }

  // ignore: missing_return
  Future setWorkspaceFromHive(data){
    _data = data;
    return data;
  }

  Future<dynamic> uploadAvatarWorkspace(String token, workspaceId, file, type) async {
    final body = {
      "file": file,
      "content_type": type
    };

    final url = Utils.apiUrl + 'workspaces/$workspaceId/contents?token=$token';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);
      final workspace = new Map.from(currentWorkspace);

      workspace["avatar_url"] = responseData["content_url"];
      

      if (responseData["success"] == true) {
        changeWorkspaceInfo(token, workspaceId, workspace);
      } else if (responseData['success'] == false) {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> changeWorkspaceInfo(String token, workspaceId, body) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/change_info?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _currentWorkspace = body;
        final index = _data.indexWhere((e) => e["id"].toString() == workspaceId.toString());
        _data[index]["name"] = body["name"];
        _data[index]["avatar_url"] = body["avatar_url"];
      } else {
        throw HttpException(responseData['message']);
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> changeWorkspaceMemberInfo(String token, workspaceId, member) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/change_member_info?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(member));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _currentMember = member;
      } else {
        throw HttpException(responseData['message']);
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> deleteWorkspace(String token, int workspaceId, context) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/delete_workspace?token=$token';
    // var box = await Hive.openBox("lastSelected");
  
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers);
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _selectedTab = 0;

        notifyListeners();
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  deleteMemberFromWorkspace(context, token, data) {
    final workspaceId = data["workspace_id"];
    final index = _data.indexWhere((element) => element["id"] == workspaceId);
    if (index != -1) {
      _data.removeAt(index);
      getListWorkspace(context, token);
      _selectedTab = 0;
    }
  }

  updateWorkspace(data){
    // {avatar_url: null, name: 45, settings: {}, workspace_id: 18}
    var workspaceId  = data["workspace_id"];
    var lastIndex  = _data.lastIndexWhere((element) {return element["id"] == workspaceId; });
    if (lastIndex >= 0){
      _data[lastIndex]["name"] = data["name"];
    }
    if (_currentWorkspace["id"] == workspaceId ){
      _currentWorkspace["name"] = data["name"];
    }
    notifyListeners();
  }

  Future<String> joinWorkspaceByInvitation(token, workspaceId, text, type, userInvite, messageId) async{
    final url = Utils.apiUrl + 'workspaces/$workspaceId/join_workspace?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({'text': text, 'type': type, "user_invite" : userInvite, "message_id" : messageId}));
      final responseData = json.decode(response.body);
      _message = responseData['message'];
      if (responseData["success"] == false) {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    return _message;
  }

  Future<String> declineInviteWorkspace(token, workspaceId, userInvite, messageId) async{
    final url = Utils.apiUrl + 'workspaces/$workspaceId/decline_invite?token=$token';
    try {
      final response = await http.post(Uri.parse(url),
        headers: Utils.headers,
        body: json.encode({'workspace_id' : workspaceId, 'user_invite' : userInvite, 'message_id' : messageId})
      );
      final responseData = json.decode(response.body);
      _message = responseData["message"];
      if(responseData == false){
        throw HttpException(responseData["message"]);
      }
    } catch (e) {
      print(e);
    }
    return _message;
  }

  joinWorkByCode(token, textCode, currentUser) async {
    final key = textCode.split("-");
    final workspaceId = key[1].toString().trim();
    var type;
    var user;

    if (currentUser["email"] != null || currentUser["email"] != "") {
      type = 1;
      user = currentUser["email"];
    } else {
      type = 2;
      user = currentUser["email"];
    }

    final url = Utils.apiUrl + 'workspaces/$workspaceId/join_workspace?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({'text': user, 'type': type}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == false) {
        _message = responseData['message'];
        // throw HttpException(responseData['message']);
        return {"status": responseData["success"], "message": _message};
      } else {
        if (user != null) {
          _message = "Join Workspace Complete !";
          return responseData["success"];
        }
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  resetData() {
    _members = [];
    _data = [];
    _selectedTab = 0;
    _loading = false;
    _currentMember = {};
    _message = "";
  }

  Future<List> searchMember(String text, String token, workspaceId)async{
    try {
      final url = Utils.apiUrl + 'workspaces/$workspaceId/get_workspace_member?value=$text&token=$token';
      var response  = await Dio().get(url);
      var res  = response.data;
      if (res["success"]) return res["members"];
      return [];
    } catch (e) {
      // sl.get<Auth>().showErrorDialog(e.toString());
      return [];
    }
  }

  Future<dynamic> deleteChannelMember(String token, workspaceId, channelId, list, {String type = ""}) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/delete_member?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({"list": list, "type": type}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _members = responseData["members"];
      } else {
        throw HttpException(responseData['message']);
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  onSaveStatePinned(context, id, isShowChannel, isShowPinned) async{
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var box = await Hive.openBox("stateShowPinned:${currentUser["id"]}");
    var data = box.get("data");
    int index = data.indexWhere((e) => e["id"] == id);
    if (index > -1) {
      data[index]["isShowChannel"] = isShowChannel ?? data[index]["isShowChannel"];
      data[index]["isShowPinned"] = isShowPinned ?? data[index]["isShowPinned"];
    }
    box.put("data", data);
    // _data = data;
  }

  setDefaultEmojiData(List data){
    _emojis =  data;
    notifyListeners();
  }

  addEmojiWorkspace(Map data){
    var workspaceId  =  data["workspace_id"];
    var indexW =  _data.indexWhere((element) => "${element["id"]}" == "$workspaceId");
    if (indexW != -1){
      _data[indexW]["emojis"] = (Utils.checkedTypeEmpty(_data[indexW]["emojis"]) ? _data[indexW]["emojis"] : []) + [data];
      if (_currentWorkspace["id"] == workspaceId)
        _currentWorkspace["emojis"] = _data[indexW]["emojis"];
      notifyListeners();
    }
  }

  newWorkspaceMember(data) {
    final newUser = data["new_user"];
    List list = List.from(_members);
    final index = list.indexWhere((e) => e["user_id"] == newUser["id"]);

    if (index == -1) {
      list.add(newUser);
      _members = list;
      notifyListeners();
    }
  }

  updateWorkspaceMember(bool isProFile ,data) {
    final index = members.indexWhere((e) => e["id"] == data["user_id"]);
    if(index != -1) {
        if(isProFile) {
          members[index]["avatar_url"] = data["avatar_url"];
          members[index]["full_name"] = data["full_name"];
        } else {
          members[index]["role_id"] = data["role_id"];
          members[index]["nickname"] = data["nickname"];
        }
      }
    notifyListeners();
  }
  // can xu ly cho truowng hop ko trong workspace, nhuwg co mention => data.length > 0 => ko goi api
  // => them bien "bool active" de check trang thai, bien nay gan = true khi lan dau load mention.
  Future<dynamic> getMentions(String token, workspaceId, bool loadMore) async {
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "$workspaceId");
    if (indexW == -1) return;
    Map dataMentionsWorkspace =  _mentions[indexW];
    if (
      dataMentionsWorkspace["fetching"] 
      || dataMentionsWorkspace["disableLoadMore"]
      || (Utils.checkedTypeEmpty( _mentions[indexW]["active"]) && !loadMore)) return;
    try {
       _mentions[indexW]["fetching"] = true;
      int lengthCurrent = dataMentionsWorkspace["data"].length;
      var lastId = lengthCurrent == 0 ? null : dataMentionsWorkspace["data"][lengthCurrent -1];
      String url = "${Utils.apiUrl}workspaces/$workspaceId/mentions?token=$token";
      if (lastId != null) url += "&last_id=${lastId["id"]}";
      var response  = await Dio().get(url);

      if (response.data["success"]){
        _mentions[indexW]["active"] = true;
        _mentions[indexW]["data"] = dataMentionsWorkspace["data"] + await processDataMention(response.data["data"]);
        _mentions[indexW]["disableLoadMore"] = response.data["data"].length  == 0;
      }

      _mentions[indexW]["fetching"] = false;
      notifyListeners();
    } catch (e) {
      print("__________ $e");
      dataMentionsWorkspace["fetching"] = false;
      notifyListeners();
    }
  }

  Future<List> processDataMention(List mentions) async {
    return await Future.wait(
      mentions.map((mention) async {
        if (Utils.checkedTypeEmpty(mention["message"]["id"])) return {
          ...mention,
          "message": (await MessageConversationServices.processBlockCodeMessage([mention["message"]]))[0]
        };
        return mention;
      })
    );
  }

  newMention(data, userId) {
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "${data["workspace_id"]}");
    if (indexW == -1) return;
    _mentions[indexW]["data"] = [] + [data] + _mentions[indexW]["data"];
    final indexMention = _mentions[indexW]["data"].indexWhere((e) => data["id"] == e["id"]);

    if (indexMention != -1) {
      _mentions[indexW]["data"][indexMention]["unread"] = data["creator_id"] != userId;
    }
    notifyListeners();
  }

  updateReadMentionFromMobile(List? data){
    if(data == null) return;
    for (var i = 0; i < data.length; i++) {
      var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "${data[i]["workspace_id"]}");
      if (indexW != -1){
        var dataMentionW = _mentions[indexW];
        List? listMentionId = data[i]["list_mention_id"];
        for(var j = 0; j< listMentionId!.length; j++){
          var indexM = (dataMentionW["data"] as List).indexWhere((element) => element["id"] == listMentionId[j]);
          if (indexM != -1) dataMentionW["data"][indexM]["unread"] = false;
        }
      }
    }
    notifyListeners();
  }

  deleteMention(data){
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "${data["workspace_id"]}");
    if (indexW == -1) return;
    _mentions[indexW]["data"] = _mentions[indexW]["data"].where((e) => e["id"] != data["mention_id"]).toList();
    notifyListeners();
  }

  setNumberUnreadMentions(workspaceId){
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "$workspaceId");
    if (indexW == -1) return;
    
    for (var i = 0; i < _mentions[indexW]["data"].length; i++) {
      _mentions[indexW]["data"][i]["unread"] = false;
    }
    notifyListeners();
  }

  updateUnreadMentionInConver(message, userId) {
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "${message["workspace_id"]}");
    if (indexW == -1) return;

    for (var i = 0; i < _mentions[indexW]["data"].length; i++) {
      if (_mentions[indexW]["data"][i]["type"] == "channel" && _mentions[indexW]["data"][i]["channel_id"] == message["channel_id"]) {
        if (message["user_id"] == userId) {
          _mentions[indexW]["data"][i]["unread"] = false;
        }
      }
    }
  }

  updateUnreadMention(workspaceId, sourceId, isIssue) {
    var indexW = _mentions.indexWhere((element) => "${element["workspace_id"]}" == "$workspaceId");
    if (indexW == -1) return;
    var indexMention = _mentions[indexW]["data"].indexWhere((e) => (isIssue ? e["issue"]["id"] : e["source_id"]) == sourceId);
    if (indexMention == -1) return;
    _mentions[indexW]["data"][indexMention]["unread"] = false;
    notifyListeners();
  }

  updateMentionWorkspace(data){
    var indexW = _mentions.indexWhere((element) => element["workspace_id"] == data["workspace_id"]);
    if (indexW == -1) return;
    var indexMention = _mentions[indexW]["data"].indexWhere((ele) => ele["id"] == data["mention_id"]);
    if (indexMention == -1) return;
    if (_mentions[indexW]["data"][indexMention]["type"] == "channel"){
      _mentions[indexW]["data"][indexMention]["message"] = Utils.mergeMaps([ _mentions[indexW]["data"][indexMention]["message"], data["message"]]);
    } else if (_mentions[indexW]["data"][indexMention]["type"] == "issues") {
      _mentions[indexW]["data"][indexMention]["issue"]["description"] = data["message"]["text"];
    } else {
      _mentions[indexW]["data"][indexMention]["issue_comment"]["comment"] = data["message"]["text"];
    }
    notifyListeners();
  }

  clearMentionWhenClickChannel(workspaceId, channelId) {
    var indexW = _mentions.indexWhere((element) => element["workspace_id"] == workspaceId);
    if (indexW == -1) return;

    for (var i = 0; i < _mentions[indexW]["data"].length; i++) {
      var mention = _mentions[indexW]["data"][i];
      if (mention["channel_id"] == channelId) {
        mention["unread"] = false;
      }   
    }
  
    notifyListeners();
  }

  updateReactionMessageMention(data){
    var reaction = data["reactions"];
    var indexMentionWorkspace = _mentions.indexWhere((ele) => ele["workspace_id"] == reaction["workspace_id"]);
    if (indexMentionWorkspace != -1){
      var indexMessage = _mentions[indexMentionWorkspace]["data"].indexWhere((mention) => mention["message"]["id"] == reaction["message_id"]);
      if (indexMessage != -1){
        _mentions[indexMentionWorkspace]["data"][indexMessage]["message"] = Utils.mergeMaps([
          _mentions[indexMentionWorkspace]["data"][indexMessage]["message"],
          {
            "reactions": MessageConversationServices.processReaction(reaction["reactions"])
          }
        ]);
        notifyListeners();
      }
    }
  }

  updateDeleteWorkspace(context, token, data) {
    final workspaceId = data["workspace_id"];

    if (currentWorkspace["id"] == workspaceId) {
      getListWorkspace(context, token);
      _selectedTab = 0;
      notifyListeners();
    } else {
      final index = _data.indexWhere((e) => e["id"] == workspaceId);

      if (index != -1) {
        _data.removeAt(index);
        notifyListeners();
      }
    }
  }

  updateOnlineStatus(workspaceId, channelId, data) {
    final indexMember = _members.indexWhere((e) => e["id"] == data["user_id"]);

    if (indexMember != -1) {
      _members[indexMember]["is_online"] = data["is_online"];
      notifyListeners();
    }
  }

  getPreloadIssue(token) async {
    final url = "${Utils.apiUrl}workspaces/preload_issue?token=$token";

    try {
      final response = await Utils.getHttp(url);

      if (response["success"] == true) {
        _preloadIssues = response["issues"];
      } else {
        throw HttpException(response['message']);
      }
    } catch(e){
      print(e);
    }
  }

  updatePreloadIssue(context, payload) {
    final indexWs = _data.indexWhere((e) => e["id"] == payload["workspace_id"]);
    if (indexWs == -1) return;
    final dataChannel = Provider.of<Channels>(context, listen: false).data;
    final indexChannel = dataChannel.indexWhere((e) => e["id"] == payload["channel_id"]);
    if (indexChannel == -1) return;
    final channel = dataChannel[indexChannel];
    payload["channel_name"] = channel["name"];
    _preloadIssues.insert(0, payload);
  }

  leaveWorkspace(token, workspaceId, userId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/leave_workspace?token=$token&user_id=$userId';

    try {
      var response  = await Dio().post(url);
      var res  = response.data;

      if (res["success"] == true) {
        final index = _data.indexWhere((e) => e["id"].toString() == workspaceId.toString());
        if (index == -1) return;
        _data.removeAt(index);
        setTab(0);
      } else {
        throw HttpException(res['message']);
      }
    } catch(e){
      print(e);
    }
  }
  _mergeSnapshotWithData(List snapshotData, List data) {
    List __data = [];
    snapshotData.forEach((workspace) {
      final workspaceId = workspace["id"];
      final indexInData = data.indexWhere((wp) => wp["id"] == workspaceId);
      if (indexInData != -1) {
        __data.add(data[indexInData]);
        data.removeAt(indexInData);
      }
    });
    __data = __data + data;
    return __data;
  }
}