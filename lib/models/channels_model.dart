// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/common/http_exception.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/service_locator.dart';

class Channels extends ChangeNotifier {
  List _data = [];
  Map _currentChannel = {};
  Map _currentMember = {};
  List _selectedMember = [];
  List _currentCommand = [];
  List _appInChannel = [];
  String _message = "";
  String? _fbToken;
  List _channelGeneral = [];
  bool _showFriends = false;
  bool _showChannelSetting = false;
  bool _showChannelPinned = false;
  bool _showChannelMember = false;
  List _lastChannelSelected = [];
  List _listChannelMember = [];
  List _listPinnedMessages = [];
  List _pinnedMessages = [];
  bool _isIssueLoading = false;
  List _channelMember = [];
  Map _lastFilters = {"page": 1, "filters": [], "isClosed": false, "sortBy": "newest", "text": "", "unreadOnly": false};
  Map? _issueSelected;
  Map? _tempIssueState;
  bool _showFlashMessage = false;
  int numberUnreadIssues = 0;

  List get data => _data;
  Map get currentChannel => _currentChannel;
  List get channelMember => _channelMember;
  Map get currentMember => _currentMember;
  List get selectedMember => _selectedMember;
  List get currentCommand => _currentCommand;
  List get appInChannels => _appInChannel;
  String get message => _message;
  List get channelGeneral => _channelGeneral;
  String? get fbToken => _fbToken;
  bool get showChannelSetting => _showChannelSetting;
  bool get showFriends => _showFriends;
  bool get showChannelPinned => _showChannelPinned;
  bool get showChannelMember => _showChannelMember;
  List get lastChannelSelected => _lastChannelSelected;
  List get pinnedMessages => _pinnedMessages;
  bool get isIssueLoading => _isIssueLoading;
  Map get lastFilters => _lastFilters;
  Map? get issueSelected => _issueSelected;
  Map? get tempIssueState => _tempIssueState;
  List get listChannelMember => _listChannelMember;
  bool get showFlashMessage => _showFlashMessage;


  set tempIssueState(issue) {
    _tempIssueState = issue;
    notifyListeners();
  }

  clearPinnedMessages(){
    _pinnedMessages = [];
  }

  setFlashMessageStatus(value) {
    _showFlashMessage = value;
    notifyListeners();
  }

  onChangeOpenIssue(Map? data) async {
    if (data != null) {
      var box = await Hive.openBox("draftsIssue");
      var boxDraftIssue = box.get(data["id"].toString());
      if (boxDraftIssue != null) data["draftComment"] = boxDraftIssue["draftComment"] ?? "";
    }

    _issueSelected = data;
    notifyListeners();
  }

  getDataMember(id) {
    final index = _listChannelMember.indexWhere((e) => e["id"] == id);

    if (index == -1) {
      return [];
    } else {
      return _listChannelMember[index]["members"];
    }
  }

  setIssueLoading(bool loading) {
   _isIssueLoading = loading;
  }

  loadChannels(String token, workspaceId) {
    List channels = _data.where((e) => e["workspace_id"] == workspaceId && !Utils.checkedTypeEmpty(e["is_archived"])).toList();

    if (channels.length > 0 ) {
      _currentChannel = channels[0] ?? {};
      var box = Hive.box('lastSelected');
      box.put('lastChannelId', _currentChannel["id"]);
      box.put("isChannel", 1);
    } else {
      _currentChannel = {};
    }
    notifyListeners();
  }

  setLastChannelFromHive(List data){
    _lastChannelSelected = data;
  }

  onChangeLastChannel(workspaceId, channelId) {
    int index = _lastChannelSelected.indexWhere((e) => e["workspace_id"] == workspaceId && !Utils.checkedTypeEmpty(e["is_archived"]));
    if (index == -1) {
      _lastChannelSelected.add({
        "workspace_id": workspaceId,
        "channel_id": channelId
      });
    } else {
      _lastChannelSelected[index]["workspace_id"] = workspaceId;
      _lastChannelSelected[index]["channel_id"] = channelId;
    }
    var box = Hive.box('lastSelected');
    box.put("lastChannelSelected", _lastChannelSelected);
    notifyListeners();
  }

  openChannelSetting(value) async {
    _showChannelSetting = value;
    var box = await Hive.openBox('drafts');
    
    box.put('openSetting', value);
    box.put('openAbout', true);
    box.put('openPinned', false);
    box.put('openMember', false);
    box.put('openFriends', false);
    _showChannelMember = false;
    _showChannelPinned = false;
    _showFriends = false;
    notifyListeners();
  }

  openFriends(value) async {
    _showFriends = value;
    var box = await Hive.openBox('drafts');
    box.put('openFriends', value);
    box.put('openSetting', false);
    box.put('openPinned', false);
    box.put('openMember', false);
    _showChannelMember = false;
    _showChannelPinned = false;
    _showChannelSetting = false;
    notifyListeners();
  }

  openChannelMember(value) async {
    _showChannelMember = value;
    var box = await Hive.openBox('drafts');

    _showChannelPinned = false;
    _showChannelSetting = false;
    _showFriends = false;
    box.put('openFriends', false);
    box.put('openSetting', false);
    box.put('openPinned', false);
    box.put('openMember', value);
    notifyListeners();
  }

  openChannelPinned(value) async {
    _showChannelPinned = value;
    var box = await Hive.openBox('drafts');

    _showChannelSetting = false;
    _showChannelMember = false;
    _showFriends = false;
    box.put('openFriends', false);
    box.put('openSetting', false);
    box.put('openMember', false);
    box.put('openPinned', true);
    notifyListeners();
  }

  setCurrentChannel(channelId) async {
    if (_currentChannel["id"] != null) updateLastMessageReaded(_currentChannel["id"], null);
    onChangeOpenIssue(null);

    int index = _data.indexWhere((e) => e["id"] == channelId);

    if (index != -1) {
      _currentChannel = _data[index] ?? {};
    }

    var box = Hive.box('lastSelected');
    box.put('lastChannelId', channelId);
    box.put("isChannel", 1);
    notifyListeners();
  }

  Future<dynamic> selectChannel(var token, workspaceId, channelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId?token=$token');
    var indexPin = _listPinnedMessages.indexWhere((e) => e["id"] == channelId);
    _channelMember = getDataMember(channelId);

    try {
      final response = await http.get(url);
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        if (indexPin == -1) {
          _listPinnedMessages.add({
            "id": channelId,
            "pinnedMessages": responseData["pinned_channel_messages"]
          });

          if (currentChannel["id"] != null || currentChannel["id"] == channelId) { 
            _pinnedMessages = responseData["pinned_channel_messages"];
          }
        } else {
          _pinnedMessages = _listPinnedMessages[indexPin]["pinnedMessages"];
        }

        int index = _data.indexWhere((e) => e["id"] == _currentChannel["id"]);

        if (index != -1) {
          _data[index]["seen"] = true;
          _data[index]["new_message_count"] = 0;
        }

        if (currentChannel["id"] != null && currentChannel["id"] == channelId) {
          _data[index]["labels"] = responseData["labels"];
          _data[index]["milestones"] = responseData["milestones"];
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> createChannel(String token, workspaceId, String name, bool isPrivate, List uids, auth, providerMessage) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels?token=$token');
    try {
      final response = await http.post(
        url,
        headers: Utils.headers,
        body: json.encode(
          {'name': name, 'is_private': isPrivate, "user_ids": uids},
        ),
      );

      final responseData = json.decode(response.body);
      sl.get<Auth>().showAlertMessage(responseData["message"], !responseData["success"]);
      if (responseData["success"]) {
        final data = responseData["data"];
        final channelId = data["id"];

        int index = _data.indexWhere((e) => e["id"] == channelId);
        if (index == -1) {
          insertDataChannel(data);
          insertChannelMember(data);
        }
        onSelectedChannel(workspaceId, channelId, auth, providerMessage);
      }

    } catch (e) {
      print("____ $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  onSelectedChannel(workspaceId, channelId, auth, providerMessage) {
    setCurrentChannel(channelId);
    onChangeLastChannel(workspaceId, channelId);
    selectChannel(auth.token, workspaceId, channelId);
    providerMessage.loadMessages(auth.token, workspaceId, channelId);
    loadCommandChannel(auth.token, workspaceId, channelId);
    getChannelMemberInfo(auth.token, workspaceId, channelId, auth.userId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );
  }

  Future<String> inviteToChannel(String token, workspaceId, channelId, text, type, userId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/send_invitation?token=$token');
    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({'id': userId, 'text': text, 'type': type}));
      final responseData = json.decode(response.body);
       _message = responseData["message"] ?? "";
      if(responseData["success"] == false){
        throw HttpException(responseData['message']);
      }
    } catch(e){
      print(e);
      // // sl.get<Auth>().showErrorDialog(e.toString());
    }
    return _message;
  }

  Future<dynamic> inviteToPubChannel(token, workspaceId, channelId, receiverId) async {
    Uri url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/invite_to_public_channel?token=$token');
    try {
      final body = {
        "receiver_id": receiverId
      };
      final response = await http.post(url, headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);
      _message = responseData["message"] ?? "";
      if (responseData["success"] == false) {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch(e) {
      print(e);
    }
  }

  Future<dynamic> addDevicesToken(
      String token, workspaceId, String? firebaseToken, String platform) async {
    _fbToken = firebaseToken;
    final url = Utils.apiUrl + 'workspaces/$workspaceId/add_devices_token?token=$token';
    try {
      await Dio().post(url, data: json.encode({'firebase_token': firebaseToken, 'platform': platform}));
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> deleteDevicesToken(String token) async {
    final url = Utils.apiUrl + 'workspaces/remove_devices_token?token=$token';
    try {
      await Dio().delete(url, data: json.encode({'firebase_token': _fbToken}));

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> changeChannelInfo(String token, workspaceId, channelId, channel, context) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/channel_info?token=$token');

    try {
      final response = await http.post(url,headers: Utils.headers, body: json.encode(channel));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _currentChannel = channel;
        int index =  _data.indexWhere((e) => e["id"] == channel["id"]);
        _data[index] = channel;
        sl.get<Auth>().showAlertMessage("Cập nhật thành công", false);
      } else {
        if (responseData["error_code"] == 403) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String text = suffixNameChannel(currentChannel["name"]);
              return CustomDialog(
                title: "CHANNEL NAME",
                titleField: 'Channel name',
                displayText: text,
                onSaveString: (value) {
                  int index = _data.indexWhere((e) => e["name"] == value);
                  if(index == -1) {
                    channel["name"] = value;
                    changeChannelInfo(token, workspaceId, channelId, channel, context);
                    Navigator.pop(context);
                  } else {
                    sl.get<Auth>().showAlertMessage("Tên channel đã tồn tại", true);
                  }
                }
              );
            }
          );
          sl.get<Auth>().showAlertMessage("Tên channel đã tồn tại", true);
        }
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  String suffixNameChannel(value) {
    int i = 0;
    String text = value;
    bool check = true;
    while (check) {
      int index = _data.indexWhere((e) => e["name"] == text);
      if (index == -1) break;
      List suffix = text.split("_");
      try{
        int indexCheck = int.parse(suffix.last);
        suffix[suffix.length - 1] = (indexCheck + 1).toString();
        text = suffix.join("_");
      } catch (e) {
        i += 1;
        text = text + "_$i";
      }
    }
    return text;
  }

  Future<dynamic> getChannelMemberInfo(String token, workspaceId, channelId, userId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/member_info?token=$token&userId=$userId');
    if (userId != null) {
      try {
        final response = await http.get(url);
        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          _currentMember = responseData["member"];
        } else {
          throw HttpException(responseData['message']);
        }
        notifyListeners();
      } catch (e) {
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  Future<dynamic> changeChannelMemberInfo(String token, workspaceId, channelId, member) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/change_member_info?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(member));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        _currentMember = member;

        int index = _data.indexWhere((e) => e["id"] == channelId);
        _data[index]["status_notify"] = _currentMember["status_notify"];

      } else {
        throw HttpException(responseData['message']);
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> onSelectChannelMember(List list) async {
    _selectedMember = list;
    notifyListeners();
  }

  Future<dynamic> delChannelToAll(token, workspaceId, channelId) async {
    final indexChannel = _data.indexWhere((element) => element["id"] == channelId);
    if (indexChannel != -1) {
      _data.removeAt(indexChannel);
      loadChannels(token, workspaceId);
    }

    notifyListeners();
  }

  Future<dynamic> deleteChannel(String token, workspaceId, channelId, idGeneral) async {
    if (idGeneral != channelId) {
      final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/delete?token=$token';
      try {
        final response = await http.post(Uri.parse(url), headers: Utils.headers);
        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

          if (indexChannel != -1) {
            _data.removeAt(indexChannel);
            loadChannels(token, workspaceId);
            return _currentChannel;
          }
        } else {
          _message = "Không xóa được channel này !";
          throw HttpException(responseData['message']);
        }

        notifyListeners();
      } catch (e) {
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    } else {
      _message = "Không xóa được channel này !";
    }
  }

  updateProfileChannel(data) {
    _listChannelMember = _listChannelMember.map((channelMember) {
      int indexMember = channelMember["members"].indexWhere((u) => u["id"] == data["user_id"]);
      if(indexMember > -1) {
        channelMember["members"][indexMember]["full_name"] = data["full_name"];
        channelMember["members"][indexMember]["avatar_url"] = data["avatar_url"];
        channelMember["members"][indexMember]["custom_color"] = data["custom_color"];
      }
      return channelMember;
    }).toList();

    if (currentChannel["id"] != null) {
      _channelMember = getDataMember(currentChannel["id"]);
    }

    notifyListeners();
  }

  parseAttachments(attachments) {
    final string = attachments[0]["type"] == "mention" ? attachments[0]["data"].map((e) {
      if (e["type"] == "text" ) return e["value"];
      if (e["type"] == "all") return "@all";
      return "@${e["name"] ?? ""}";
    }).toList().join() : attachments[0]["type"] == "bot" ? "Sent an attachment"  : "Sent an image";

    return string;
  }

  Future<dynamic> updateChannelInfo(payload) async{
    final type = payload["type"];
    final data = payload["data"];

    if (type == "pin_message") {
      final index = _listPinnedMessages.indexWhere((e) => e["id"] == data["channel_id"]);

      if (index != -1) {
        final indexPinnedMessage = _listPinnedMessages[index]["pinnedMessages"].indexWhere((e) => e["id"] == data["id"]);

        if (indexPinnedMessage == -1) {
          _listPinnedMessages[index]["pinnedMessages"].insert(0, data);
        } else {
          _listPinnedMessages[index]["pinnedMessages"].removeAt(indexPinnedMessage);
        }
        notifyListeners();
      } 
    }
  }

  setDataChannels(channels) {
    _data = channels;
    _data.sort((a, b) => a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
    notifyListeners();
  }

  getChannelMembers(listChannelsMembers, membersWorkspace, workspaceId) {
    List listChannelMembersInWorkspace = listChannelsMembers.where((e) => e["workspace_id"] == workspaceId).map((channelMember) {
      List members = channelMember["members"].map((e) {
        int indexMember = membersWorkspace.indexWhere((ele) => ele["id"] == e);
          return indexMember != -1 ? membersWorkspace[indexMember] : null;
      }).where((e) => e != null).toList();

      return {
        "workspace_id": channelMember["workspace_id"],
        "id": channelMember["id"],
        "members": members
      };
    }).toList();

    _listChannelMember = uniqById(_listChannelMember + listChannelMembersInWorkspace);

    if (currentChannel["id"] != null) {
      _channelMember = getDataMember(currentChannel["id"]);
    }

    notifyListeners();
  }

  List uniqById(List dataSource){
    List results = [];
    Map index = {};
    for (var i in dataSource) {
      var key = i["id"];
      if (!Utils.checkedTypeEmpty(key)) continue;
      if (index[key] == null){
        results += [i];
        index[i["id"]] = results.length - 1;
      } else {
        results[index[key]] = Utils.mergeMaps([results[index[key]], i]);
      }
    }
    return results;    
  }

  insertDataChannel(channel) {
    final index = _data.indexWhere((e) => e["id"] == channel["id"]);

    if (index == -1) {
      _data = _data + [channel];
      _data.sort((a, b) {
        return a['name'].toLowerCase().compareTo(b['name'].toLowerCase());
      });
      notifyListeners();
    }
  }

  insertChannelMember(channel) {
    int index = _listChannelMember.indexWhere((e) => e["id"] == channel["id"] && e["workspace_id"] == channel["workspace_id"]);
    if (index != -1) {
      // khi nguoi khac tham gia add members
      int indexUser = _listChannelMember[index]["members"].indexWhere((e) => e["id"] == channel["user"]["id"]);
      if(indexUser == -1) _listChannelMember[index]["members"].add(channel["user"]);
    } else {
      // create channel mac dinh add chinh minh
      _listChannelMember.add({
        "id": channel["id"],
        "workspace_id": channel["workspace_id"],
        "members": [channel["user"]]
      });
    }
  }

  updateChannel(channel, context) {
    var channelId = channel["channel_id"];
    var lastIndex = _data.lastIndexWhere((element) {
      return element["id"] == channelId;
    });

    if (lastIndex >= 0) {
      _data[lastIndex]["name"] = channel["name"] == null ?  _data[lastIndex]["name"] : channel["name"];
      _data[lastIndex]["is_private"] = channel["is_private"] == null ? _data[lastIndex]["is_private"] : channel["is_private"];
      _data[lastIndex]["user_count"] = channel["user_count"] == null ? _data[lastIndex]["user_count"] : channel["user_count"];
      _data[lastIndex]["topic"] = channel["topic"] == null ? _data[lastIndex]["topic"] : channel["topic"];
      _data[lastIndex]["is_archived"] = channel["is_archived"] == null ? _data[lastIndex]["is_archived"] : channel["is_archived"];
      _data[lastIndex]["kanban_mode"] = channel["kanban_mode"] == null ? _data[lastIndex]["kanban_mode"] : channel["kanban_mode"];
    }

    notifyListeners();
  }

  loadCommandChannel(token, workspaceId, channelId) async {
    final url = "${Utils.apiUrl}workspaces/$workspaceId/channels/$channelId/commands?token=$token";
    try {
      var response  = await Dio().get(url);
      var resData = response.data;
      _currentCommand = resData["data"]["commands"];
      _appInChannel = resData["data"]["apps"];
    } catch (e) {
      _currentCommand = [];
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    notifyListeners();
  }

  Future<String> joinChannelByInvitation(token, workspaceId, channelId, userInvite, messageId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/join_channel?token=$token';
    try {
      final response = await http.post(Uri.parse(url),
        headers: Utils.headers,
        body: json.encode({'user_invite' : userInvite, 'message_id' : messageId}));
      final responseData = json.decode(response.body);
      _message = responseData["message"];
      if (responseData["success"] == false) {
        throw HttpException(responseData['message']);
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
    return _message;
  }

  Future<String> declineInviteChannel(token, workspaceId, channelId, userInvite, messageId) async{
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/decline_invite?token=$token';
    try{
      final response = await http.post(Uri.parse(url),
        headers: Utils.headers,
        body: json.encode({'workspace_id' : workspaceId, 'channel_id' : channelId, 'user_invite' : userInvite, 'message_id' : messageId})
      );
      final responseData = json.decode(response.body);
      _message = responseData["message"];
      if(responseData["success"] == false){
        throw HttpException(responseData["message"]);
      }
      notifyListeners();
    } catch(e){
      print(e);
    }
    return _message;
  }

  joinChannelByCode(token, textCode, currentUser) async {
    final key = textCode.split("-");
    final workspaceId = key[1].trim();
    final channelId = key[2].trim();
    var type;
    var text;

    if (currentUser["email"] != null || currentUser["email"] != "") {
      type = 1;
      text = currentUser["email"];
    } else {
      type = 2;
      text = currentUser["email"];
    }

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/join_channel?token=$token';

    try {
      final response = await http.post(Uri.parse(url),
        headers: Utils.headers,
        body: json.encode({'text': text, 'type': type}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == false) {
        _message = responseData['message'];
        // throw HttpException(responseData['message']);
        return {"status": responseData["success"], "message": _message};
      } else {
        _message = S.current.joinChannelSuccess;
        return responseData["success"];
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> leaveChannel(token, workspaceId, channelId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/leave_channel?token=$token';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers);
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final index = _data.indexWhere((e) => e["id"] == channelId);

        if (index != -1) {
          _data.removeAt(index);
          loadChannels(token, workspaceId);
          return _currentChannel;
        } else {

        }
      } else {
        throw HttpException(responseData['message']);
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  deleteMemberFromChannel(token, data) {
    final workspaceId = data["workspace_id"];
    final channelId = data["channel_id"];
    final index = _data.indexWhere((element) => element["id"] == channelId);

    if (index != -1) {
      _data.removeAt(index);
      loadChannels(token, workspaceId);
    }

    notifyListeners();
  }

  updatePinnedChannel(channelId) {
    final index = _data.indexWhere((e) => e["id"] == channelId);

    if (index != -1) {
      _data[index]["pinned"] = !_data[index]["pinned"];
  
      notifyListeners();
    }
  }

  setDataIssue(data) {
    final index = _data.indexWhere((e) => e["id"] == currentChannel["id"]);
    _data[index]["issues:${currentChannel["id"]}"] = data;
    notifyListeners();
  }

  Future<dynamic> getListIssue(token, workspaceId, channelId, page, isClosed, filters, sortBy, text, unreadOnly) async { 
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues?token=$token';
    final index = _data.indexWhere((e) => e["id"] == channelId);

    _lastFilters = {
      "page": page,
      "filters": filters,
      "isClosed": isClosed,
      "sortBy": sortBy,
      "text": text,
      "unreadOnly": unreadOnly
    };

    try {
      // setIssueLoading(true);
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(_lastFilters));

      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        if (index != -1) {
          _data[index]["issues"] = responseData["issues"];
          _data[index]["openIssuesCount"] = responseData["openIssuesCount"];
          _data[index]["closedIssuesCount"] = responseData["closedIssuesCount"];
          _data[index]["totalPage"] = responseData["totalPage"];

          setIssueLoading(false);
          notifyListeners();
        }
        else {
          // sl.get<Auth>().showAlertMessage("Index channel not found", true);
        }
      } else {
        throw HttpException(responseData['message']);
      }
      return responseData["success"];
    } catch (e) {
      // setIssueLoading(false);
      // sl.get<Auth>().showAlertMessage(e.toString(), true);
      return false;
    }
  }

  Future<dynamic> loadMoreIssue(token, workspaceId, channelId, page, isClosed, filters, sortBy, text, {bool unreadOnly = false}) async { 
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues?token=$token&page=$page&isClosed=$isClosed&filters=$filters&text=$text';
    final index = _data.indexWhere((e) => e["id"] == channelId);

    if (!_isIssueLoading) {
      setIssueLoading(true);

      try {
        final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({
          "isClosed": isClosed,
          "filters": filters,
          "page": page,
          "sortBy": sortBy,
          "unreadOnly": unreadOnly
        }));

        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          if (index != -1) {
            _data[index]["issues"] = ( _data[index]["issues"] ?? []) + responseData["issues"];
            _currentChannel = _data[index];

            setIssueLoading(false);
            notifyListeners();

            return responseData;
          }
        } else {
          throw HttpException(responseData['message']);
        }
      } catch (e) {
        setIssueLoading(false);
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  Future<dynamic> getIssue(token, workspaceId, channelId, issueId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues?token=$token';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"issue_id": issueId}));
      final responeData = json.decode(response.body);
      if (responeData["success"] == true && responeData["issues"].length > 0) {
        return responeData["issues"][0];
      }
    } catch (e) {
      print(e.toString());
    }
  }

  setLabelsAndMilestones(channelId, labels, milestones){
    final index = _data.indexWhere((e) => e["id"].toString() == channelId.toString());
    if (index != -1){
      _data[index]["labels"] = labels;
      _data[index]["milestones"] = milestones;
      notifyListeners();
    }
  }

  Future<dynamic> getLabelsStatistical(token, workspaceId, channelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_labels_statistical?token=$token');
    final index = _data.indexWhere((e) => e["id"] == channelId);
    try {
      final response = await http.get(url, headers: Utils.headers);
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
        if(index != -1) {
          _data[index]["labelsStatistical"] = responseData["labels"]; 
          notifyListeners();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getMilestoneStatiscal(token, workspaceId, channelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_milestones_statistical?token=$token');
    final index = _data.indexWhere((e) => e["id"] == channelId);

    try {
      final response = await http.get(url, headers: Utils.headers);
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
        if(index != -1) {
          _data[index]["milestonesStatistical"] = responseData["milestones"];
          notifyListeners();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> createChannelLabel(token, workspaceId, channelId, label) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/create_label?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(label));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final newLabel = responseData["label"];
          _data[indexChannel]["labels"] = _data[indexChannel]["labels"] != null ? [newLabel] + _data[indexChannel]["labels"] : [newLabel]; 
        }
      } else {
        throw HttpException(responseData['message']);
      }

    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> createChannelMilestone(token, workspaceId, channelId, milestone) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/create_milestone?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(milestone));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final newMilestone = responseData["milestone"];
          _data[indexChannel]["milestones"] = _data[indexChannel]["milestones"] != null ? [newMilestone] + _data[indexChannel]["milestones"] : [newMilestone]; 
        }
      } else {
        throw HttpException(responseData['message']);
      }

    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  updateLabelAndMilestone(workspaceId, channelId, token) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_labels_and_milestones?token=$token');
    final indexChannel = _data.indexWhere((element) => element["id"] == channelId);
    if (indexChannel == -1) return;
    try {
      final response = await http.get(url, headers: Utils.headers);
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        _data[indexChannel]["milestones"] = responseData["milestones"];
        _data[indexChannel]["labels"] = responseData["labels"];
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> deleteAttribute(token, workspaceId, channelId, attributeId, type) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/delete?token=$token';
    final body = {
      "attribute_id": attributeId,
      "type": type
    };

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          if (type == "label") {
            final indexLabel = _data[indexChannel]["labels"].indexWhere((e) => e["id"] == attributeId);

            if (indexLabel != -1) {
              _data[indexChannel]["labels"].removeAt(indexLabel);
            }
          } else if (type == "milestone") {
            final indexMilestone = _data[indexChannel]["milestones"].indexWhere((e) => e["id"] == attributeId);

            if (indexMilestone != -1) {
              _data[indexChannel]["milestones"].removeAt(indexMilestone);
            }
          } else {

          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
    
    notifyListeners();
  }

  Future<dynamic> updateLabel(token, workspaceId, channelId, label) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/update_label?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(label));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final indexLabel = _data[indexChannel]["labels"].indexWhere((e) => e["id"] == label["id"]);

          if (indexLabel != -1) {
            _data[indexChannel]["labels"][indexLabel] = label;
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> updateMilestone(token, workspaceId, channelId, milestone) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/update_milestone?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(milestone));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final indexMilestone = _data[indexChannel]["milestones"].indexWhere((e) => e["id"] == milestone["id"]);

          if (indexMilestone != -1) {
            final newMilestone = responseData["milestone"];
            _data[indexChannel]["milestones"][indexMilestone] = newMilestone;
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> createIssue(token, workspaceId, channelId, issue) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/create_issue?token=$token';
    final index = _data.indexWhere((e) => e["id"].toString() == channelId.toString());

    if (index != -1 && lastFilters["page"] == 1) {
      List issues  = _data[index]["issues"] ?? [];
      _data[index]["issues"] = [issue] + issues;
    }

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(issue));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final newIssue = responseData["issue"];
        final key = responseData["key"];
        final indexIssue = _data[index]["issues"].indexWhere((e) => e["key"] == key);
        if (indexIssue != -1) {
          _data[index]["issues"][0] = newIssue;
        }
        
        setFlashMessageStatus(true);
        Future.delayed(Duration(milliseconds: 2000), () {
          setFlashMessageStatus(false);
        });
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showAlertMessage(e.toString(), true);
    }

    notifyListeners();
  }

  Future<dynamic> closeIssue(token, workspaceId, channelId, issueId, isClosed, issueClosedTab) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/close_issue?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"issue_id": issueId, "is_closed": isClosed}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        lastFilters["page"] = lastFilters["page"] - (lastFilters["page"] > 1 && currentChannel["issues"].length == 1 ? 1 : 0);
        getListIssue(token, workspaceId, channelId, lastFilters["page"], lastFilters["isClosed"], lastFilters["filters"], lastFilters["sortBy"], lastFilters["text"], lastFilters["unreadOnly"]);
        notifyListeners();
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> updateIssueTitle(token, workspaceId, channelId, issueId, title, description) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/update_issue?token=$token';
    final indexChannel = _data.indexWhere((e) => e["id"].toString() == channelId.toString());

    if (indexChannel != -1) { 
      final indexIssue = (_data[indexChannel]["issues"] ?? []).indexWhere((e) => e["id"] == issueId);

      if (indexIssue != -1) {
        _data[indexChannel]["issues"][indexIssue]["description"] = description["description"];
      }
      try {
        final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"issue_id": issueId, "title": title, "data": description}));
        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          if (indexIssue != -1) {
            _data[indexChannel]["issues"][indexIssue]["updated_at"] = responseData["issue"]["updated_at"];
            _data[indexChannel]["issues"][indexIssue]["last_edit_description"] = responseData["issue"]["last_edit_description"];
            _data[indexChannel]["issues"][indexIssue]["last_edit_id"] = responseData["issue"]["last_edit_id"];
          }
        } else {
          throw HttpException(responseData['message']);
        }
      } catch (e) {
        print(e);
      }
      notifyListeners();
    }
  }

  Future<dynamic> closeMilestone(token, workspaceId, channelId, milestoneId, isClosed) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/close_milestone?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"milestone_id": milestoneId, "is_closed": isClosed}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        // await getListIssue(token: token, workspaceId: workspaceId, channelId: channelId);
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> updateComment(token, comment) async {
    final channelId = comment["channel_id"];
    final commentId = comment["from_id_issue_comment"];
    final url = Utils.apiUrl + 'workspaces/${comment["workspace_id"]}/channels/$channelId/issues/update_comment?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"comment_id": commentId, "data": comment}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final newComment = responseData["comment"];
          final channel = _data[indexChannel];
          final indexIssue = (channel["issues"] ?? []).indexWhere((e) => e["id"] == newComment["issue_id"]);

          if (indexIssue != -1) {
            final indexComment = channel["issues"][indexIssue]["comments"].indexWhere((e) => e["id"] == commentId);
            channel["issues"][indexIssue]["updated_at"] = responseData["issue"]["updated_at"];

            if (indexComment != -1) {
              channel["issues"][indexIssue]["comments"][indexComment] = newComment;
            }
          }
        }
      } else {
        throw HttpException("error update comment ${responseData['message']}");
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> submitComment(token, comment) async {
    final channelId = comment["channel_id"];
    final issueId = comment["from_issue_id"];
    final url = Utils.apiUrl + 'workspaces/${comment["workspace_id"]}/channels/$channelId/issues/submit_comment?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"data": comment, "issue_id": issueId}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final channel = _data[indexChannel];
          final indexIssue = channel["issues"] != null ? channel["issues"].indexWhere((e) => e["id"] == issueId) : -1;

          if (indexIssue != -1) {
            channel["issues"][indexIssue]["updated_at"] = responseData["issue"]["updated_at"];
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> deleteComment(token, workspaceId, channelId, commentId, issueId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/delete_comment?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"comment_id": commentId, "issue_id": issueId}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final channel = _data[indexChannel];
          final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

          if (indexIssue != -1) {}
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> removeAttribute(token, workspaceId, channelId, issueId, type, attributeId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/remove_attribute?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"issue_id": issueId, "type": type, "attribute_id": attributeId}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final channel = _data[indexChannel];
          final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

          if (indexIssue != -1) {
            final issue = channel["issues"][indexIssue];

            if (type == "milestone") {
              issue["milestone_id"] = null;
            } else if (type == "label") {
              issue["labels"].removeAt(issue["labels"].indexWhere((e) => e == attributeId));
            } else {
              issue["assignees"].removeAt(issue["assignees"].indexWhere((e) => e == attributeId));
            }

            channel["issues"][indexIssue]["updated_at"] = responseData["issue"]["updated_at"];
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  Future<dynamic> addAttribute(token, workspaceId, channelId, issueId, type, attributeId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/add_attribute?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"issue_id": issueId, "type": type, "attribute_id": attributeId}));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final channel = _data[indexChannel];
          final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

          if (indexIssue != -1) {
            final issue = channel["issues"][indexIssue];

            if (type == "milestone") {
              issue["milestone_id"] = attributeId;
            } else if (type == "label") {
              issue["labels"].add(attributeId);
            } else {
              issue["assignees"].add(attributeId);
            }

            channel["issues"][indexIssue]["updated_at"] = responseData["issue"]["updated_at"];
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    notifyListeners();
  }

  clearBadge(channelId,  workspaceId, isAll) {
    if (isAll) {
      final List channels = _data.where((ele) => ele['workspace_id'] == workspaceId).toList();
      for (var i = 0; i < channels.length; i++) {
        channels[i]["new_message_count"] = 0;
      }
    } else {
      final index = _data.indexWhere((e) => e["id"] == channelId);

      if (index != -1) {
        _data[index]["seen"] = true;
        _data[index]["new_message_count"] = 0;
      }
    }
  
    notifyListeners();
  }

  updateChannelSeenStatus(payload) {
    int index = _data.indexWhere((e) => e["id"].toString() == payload["channel_id"].toString());

    if (index != -1) {
      _data[index]["new_message_count"] = payload["new_message_count"];
      _data[index]["seen"] = payload["seen"];
      notifyListeners();
    }
  }

  Future<dynamic> pinMessage(token, workspaceId, channelId, messageId, isPinned) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/pin_channel_message?token=$token';
    final body = {"message_id": messageId, "is_pinned": isPinned};

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {} else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> bulkAction(token, workspaceId, channelId, type, attributeId, listIssue, isRemove, filters, page, sortBy, isClosed) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/bulk_action?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({
        "list_issue": listIssue, 
        "type": type, 
        "attribute_id": attributeId,
        "is_remove": isRemove
      }));

      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        await getListIssue(token, workspaceId, channelId, 1, isClosed, filters, sortBy, "", false);
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> updateUnreadIssue(token, workspaceId, channelId, issueId, userId) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/update_unread_issue?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({
        "issue_id": issueId
      }));

      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

        if (indexChannel != -1) {
          final channel = _data[indexChannel];
          final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

          if (indexIssue != -1) {
            final issue = channel["issues"][indexIssue];
            final indexUser = issue["users_unread"].indexWhere((e) => e == userId);
            issue["comments"] = responseData["comments"];
            _issueSelected?["comments"] = responseData["comments"];

            if (indexUser != -1) {
              issue["users_unread"].removeAt(indexUser);
            }

            notifyListeners();
          }
        }
      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> updateIssueTimeline(token, workspaceId, channelId, issueId, data) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/add_issue_timeline?token=$token';

    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({
        "issue_id": issueId,
        "data": data
      }));

      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {

      } else {
        throw HttpException(responseData['message']);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  updateChannelIssue(token, workspaceId, channelId, issueId, type, data, userId) async {
    final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

    try {
      if (indexChannel != -1) {
        final channel = _data[indexChannel];

        if (issueId != null && channel["issues"] != null) {
          final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

          if (indexIssue != -1) {
            final issue = (channel["issues"] ?? [])[indexIssue];
          
            if (type == "update_timeline") {
              // if (issue["timelines"] != null) issue["timelines"].add(data);
            } else if (type == "add_assignee") {
              final index = (issue["assignees"] ?? []).indexWhere((e) => e == data);

              if (index == -1) {
                issue["assignees"] != null ? issue["assignees"].add(data) : issue["assignees"] = [data];
              }
            } else if (type == "add_label") {
              final index = (issue["labels"] ?? []).indexWhere((e) => e == data);

              if (index == -1) {
                issue["labels"] != null ? issue["labels"].add(data) : issue["labels"] = [data];
              }
            } else if (type == "add_milestone") {
              issue["milestone_id"] = data;
            } else if (type == "remove_assignee") {
              final index = (issue["assignees"] ?? []).indexWhere((e) => e == data);

              if (index != -1) {
                issue["assignees"].removeAt(index);
              }
            } else if (type == "remove_label") {
              final index = (issue["labels"] ?? []).indexWhere((e) => e == data);

              if (index != -1) {
                issue["labels"].removeAt(index);
              }
            } else if (type == "remove_milestone") {
              issue["milestone_id"] = null;
            } else if (type == "add_comment") {
              // issue["comments"].add(data["comment"]);
              issue["users_unread"] = data["users_unread"];

              if (currentChannel["id"] == channelId) {
                if (issue["users_unread"].contains(userId)) {
                  numberUnreadIssues = numberUnreadIssues + 1;
                }
              }

              if (issue["comments_count"] != null) {
                issue["comments_count"] += 1; 
              }
            } else if (type == "delete_comment") {
              final index = (issue["comments"] ?? []).indexWhere((e) => e["id"] == data);

              if (index != -1) {
                issue["comments"].removeAt(index);
              }
            } else if (type == "close_issue") {
              issue["is_closed"] = data;
            } else if (type == "update_issue_title") {
              issue["title"] = data["title"];
              issue["last_edit_id"] = data["last_edit_id"];

              if (userId != data["last_edit_id"]) {
                issue["description"] = data["description"];
              }
            } else if (type == "update_comment") {
              if (userId != data["last_edited_id"]) {
                final indexComment = (issue["comments"] ?? []).indexWhere((e) => e["id"] == data["id"]);

                if (indexComment != -1) {
                  issue["comments"][indexComment] = data;
                }
              }
            }
          } else {
            if (type == "new_issue") {
              if (lastFilters["page"] == 1) getListIssue(token, workspaceId, channelId, lastFilters["page"], lastFilters["isClosed"], lastFilters["filters"], lastFilters["sortBy"], lastFilters["text"], lastFilters["unreadOnly"]);
            }
          }
          notifyListeners();
        } else {
          if (type == "close_milestone") {
            final indexMilestone = (_data[indexChannel]["milestones"] ?? []).indexWhere((e) => e["id"] == data["milestone_id"]);

            if (indexMilestone != -1) {
              _data[indexChannel]["milestones"][indexMilestone]["is_closed"] = data["is_closed"];
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print("type issue error $type");
      print("type data error $data");
      print(e.toString());
    }
  }

  newChannelMember(data) {
    final newUser = data["new_user"];
    final channelId = newUser["channel_id"];
    final index = _listChannelMember.indexWhere((e) => e["id"] == channelId);

    if(index != -1) {
      insertChannelMember({
        "id": channelId,
        "workspace_id": newUser["workspace_id"],
        "user": newUser
      });
    }

    notifyListeners();
  }

  removeChannelMember(data) {
    final channelId = data["channel_id"];
    final index = _listChannelMember.indexWhere((e) => e["id"] == channelId);
    if (index != -1) {
      final listMember = _listChannelMember[index]["members"];
      int indexMember = listMember.indexWhere((e) => e["id"] == data["user_id"]);
      if(indexMember != -1) _listChannelMember[index]["members"].removeAt(indexMember);
    }

    notifyListeners();
  }

  updateMentionIssue(data) {
    final indexChannel = _data.indexWhere((e) => e["id"] == data["channel_id"]);

    if (indexChannel > -1) {
      final channel = _data[indexChannel];
      if (channel["issues"] != null) {
        if (data["type"] == "issue_comment") {
          int indexIssue = channel["issues"].indexWhere((e) => e["id"] == data["issue_id"]);
          if (indexIssue > -1) {
            final issue = channel["issues"][indexIssue];
            final indexComment = issue["comments"].indexWhere((e) => e["id"] == data["id"]);
            if (indexComment > -1) _data[indexChannel]["issues"][indexIssue]["comments"][indexComment]["mentions"] = data["mentions"];
            notifyListeners();
          }
        } else {
          int indexIssue = channel["issues"].indexWhere((e) => e["id"] == data["id"]);
          if (indexIssue > -1) _data[indexChannel]["issues"][indexIssue]["mentions"] = data["mentions"];
          notifyListeners();
        }
      }
    }
  }

  transferIssue(channelId, issueId) {
    final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

    if (indexChannel != -1) {
      final channel = _data[indexChannel];

      if (issueId != null && channel["issues"] != null) {
        final indexIssue = channel["issues"].indexWhere((e) => e["id"] == issueId);

        if (indexIssue != -1) {
          channel["issues"].removeAt(indexIssue);
          notifyListeners();
        }
      }
    }
  }

  updateLastMessageReaded(channelId, messageId) {
    final indexChannel = _data.indexWhere((e) => e["id"] == channelId);

    if (indexChannel != -1) {
      if (messageId != null) {
        if ( _data[indexChannel]["last_message_readed"] == null) {
          _data[indexChannel]["last_message_readed"] = messageId;
          notifyListeners();
        }
      } else {
        if (channelId == currentChannel["id"]) {
          _data[indexChannel]["last_message_readed"] = null;
          notifyListeners();
        }
      }
    }
  }

  updateNumberUnreadIssues(payload) {
    var channelId = payload['channel_id'];
  
    if (currentChannel['id'] == channelId) {
      numberUnreadIssues = payload['number_unread_issues'] ?? 0;
      notifyListeners();
    }
  }
}
