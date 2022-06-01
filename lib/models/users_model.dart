import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workcake/common/utils.dart';
import 'package:http/http.dart' as http;

class UserModel {
  String name = "";
  String email = "";
  String phoneNumber = "";
  String avatarUrl = "";
}

class User extends ChangeNotifier {
  Map _currentUser = {};
  Map? _otherUser;
  List _friendList = [];
  List _pendingList = [];
  List _sendingList = [];
  List _mentions = [];
  bool _isUnread = false;
  String _selectedTab = "channel";
  List _userMentionInDirect = [];
  bool isBlocked = false;
  double _sliderPosition = 0.0;
  List _savedMessages = [];

  Map get currentUser => _currentUser;
  Map? get otherUser => _otherUser;
  List get friendList => _friendList;
  List get pendingList => _pendingList;
  List get sendingList => _sendingList;
  List get mentions => _mentions;
  bool get isUnread => _isUnread;
  String get selectedTab => _selectedTab;
  List get userMentionInDirect => _userMentionInDirect;
  double get sliderPosition => _sliderPosition;
  List get savedMessages => _savedMessages;

  selectTab(value) {
    _selectedTab = value;

    notifyListeners();
  }

  onChangeSliderPosition(double pos) {
    _sliderPosition = pos;
  }

  updateUserProfileData(data) async{
    if (data["user_id"] == _currentUser["id"]){
      _currentUser["avatar_url"] = data["avatar_url"];
      _currentUser["full_name"] = data["full_name"];
      _currentUser["custom_color"] = data["custom_color"];
      _currentUser['position'] = _sliderPosition;

      var box = await Hive.openBox("custom_user");
      box.put("sliderPosition:${currentUser["id"]}", _sliderPosition);

      notifyListeners();
    }
  }

  Future<dynamic> fetchAndGetMe(String authToken) async {
    final url = Utils.apiUrl + 'users/me?token=$authToken';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body);

      if (extractedData['success'] == false) return;
      _currentUser = extractedData["user"];
      _friendList = extractedData["friends"];
      _pendingList = extractedData["pendings"];
      _sendingList = extractedData["sendings"];

      var box = await Hive.openBox("custom_user");
      _currentUser['position'] = box.get("sliderPosition:${_currentUser["id"]}") ?? _sliderPosition;

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> fetchUserMentionInDirect(String authToken) async {
    final url = Utils.apiUrl + 'users/get_user_mention_in_direct?token=$authToken';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body);

      if (extractedData['success'] == false) return;
      _userMentionInDirect = extractedData["data"];
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> changeProfileInfo(String authToken, Map body) async {
    final url = Utils.apiUrl + 'users/profile_info?token=$authToken';
    try {
      if(isBlocked) return;
      else isBlocked = true;
      final response = await http.post(
        Uri.parse(url),
        headers: Utils.headers,
        body: json.encode(body)
      );
      final extractedData = json.decode(response.body);

      if (extractedData['success'] == true) {
        _currentUser = body;
        notifyListeners();  
      }
      isBlocked = false;
      
      return extractedData;
    } catch (e) {
      print(e);
      isBlocked = false;
      return;
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> updateTheme(String token,String theme) async {
    final url = Utils.apiUrl + 'users/desktop_theme?token=$token';
    try {
      var response = await Dio().post(url, data: {
        "desktop_theme": theme
      });

      return response.data;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> changeTimezone(String authToken, Map body) async {
    final url = Utils.apiUrl + 'users/change_birthday?token=$authToken';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: Utils.headers,
        body: json.encode(body)
      );
      final extractedData = json.decode(response.body);

      if (extractedData['success'] == false) return;

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> getUser(String authToken, String userId) async {
    final url = Utils.apiUrl + 'users/get_user?token=$authToken&currentUserId=${_currentUser["id"]}&userId=$userId';
    _otherUser = {};
    
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body);
      if (extractedData['success'] == false) return;

      _otherUser = extractedData["user"];
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> uploadAvatar(String authToken, workspaceId, file, type) async {
    final body = {
      "file": file,
      "content_type": type
    };

    final url = Utils.apiUrl + 'workspaces/$workspaceId/contents?token=$authToken';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);
      final avatarUrl = responseData["content_url"];

      if (responseData["success"] == true) {
        Map newBody;

        newBody = new Map.from(_currentUser);
        newBody["avatar_url"] = avatarUrl;

        await changeProfileInfo(authToken, newBody);
        fetchAndGetMe(authToken);
      } else if (responseData['success'] == false) {
        return;
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> sendFriendRequestTag(String content, String token) async {
    final url = Utils.apiUrl + 'users/send_friend_request_tag?token=$token';
    try {
      final Response response = await Dio().post(url, data: {
        "content": content
      });
      var resData = response.data;
      fetchAndGetMe(token);

      notifyListeners();
      return resData;
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> acceptRequest(String token, String userId) async {
    final url = Utils.apiUrl + 'users/accept_request?token=$token';
    try {
      final Response response = await Dio().post(url, data: {
        "receiver_id": userId
      });
      var resData = response.data;
      if (resData["success"]) fetchAndGetMe(token);

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> removeRequest(String token, String userId) async {
    final url = Utils.apiUrl + 'users/remove_request?token=$token';
    try {
      final Response response = await Dio().post(url, data: {
        "sender_id": userId
      });
      var resData = response.data;
      if (resData["success"]) fetchAndGetMe(token);

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> addFriendRequest(String userId, token) async {
    final url = Utils.apiUrl + 'users/add_friend_request?token=$token';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"user_first_id": _currentUser["id"], "user_second_id": userId}));
      final extractedData = json.decode(response.body);
      
      if (extractedData['success'] == true) {
        Map user = Map.from(_otherUser!);
        user["is_sended"] = 1;
        _otherUser = user;
      }

      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<dynamic> removeFriendRequest(String userId, token) async {
    final url = Utils.apiUrl + 'users/remove_friend_request?token=$token';
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode({"user_first_id": _currentUser["id"], "user_second_id": userId}));
      final extractedData = json.decode(response.body);

      if (extractedData['success'] == true) {
        Map user = Map.from(_otherUser!);
        user["is_requested"] = 0;
        user["is_sended"] = 0;
        _otherUser = user;
      } else {
        print("ERROR");
      }
      notifyListeners();
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  newMention(data){
    // ktra mention ton tai
    var index = _mentions.indexWhere((element) => element["id"] == data["id"]);
    if (index == -1){
      _mentions = [data] + _mentions;
      // _isUnread = _selectMention == false ? true : false;
      notifyListeners();
    }
  }

  deleteMention(data){
    var mentionId = data["mention_id"];
    _mentions = _mentions.where((element) => element["id"] != mentionId).toList();
    notifyListeners();
  }

  sendRequestCreateVertifyCode(String token)async{
    final url = "${Utils.apiUrl}users/request_otp_device?token=$token";
    await Dio().get(url);
  }

  Future<dynamic> getListSavedMessage(String token) async {
    final url = Utils.apiUrl + 'users/saved_messages?token=$token';

    try {
      final Response response = await Dio().get(url);
      final dataRes = response.data;

      if (dataRes["success"]) _savedMessages = dataRes["saved_messages"];
      notifyListeners();
    } catch (e) {
      print("getListSavedMessage $e");
    }
  }

  Future<dynamic> markSavedMessage(String token, Map message) async {
    final url = Utils.apiUrl + 'users/saved_messages?token=$token';

    try {
      final Response response = await Dio().post(url, data: {
        "message_id": message["id"],
        "attachments": message
      });
      final dataResponse = response.data;

      if (dataResponse["success"]) {
        _savedMessages = [dataResponse["saved_messages"]] + _savedMessages;
      }
      notifyListeners();
    } catch (e) {
      print("markSavedMessage $e");
    }
  }

  Future<dynamic> unMarkSavedMessage(String token, Map message) async {
    final url = Utils.apiUrl + 'users/saved_messages?token=$token';

    try {
      final Response response = await Dio().delete(url, data: {
        "message_id": message["id"],
        "attachments": message
      });
      final dataResponse = response.data;

      if (dataResponse["success"]) {
        final index = _savedMessages.indexWhere((ele) => ele["message_id"] == message["id"]);

        if (index != -1) _savedMessages.removeAt(index);
      }
      notifyListeners();
    } catch (e) {
      print("unMarkSavedMessage $e");
    }
  }

  deleteSavedMessage(messageId) {
    final index = _savedMessages.indexWhere((ele) => ele["message_id"] == messageId);
    if (index != -1) _savedMessages.removeAt(index);
  }
}
