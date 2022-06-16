// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:workcake/E2EE/e2ee.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/window_manager.dart';
import 'package:workcake/components/call_center/p2p_manager.dart';
import 'package:workcake/components/call_center/room.dart';
import 'package:workcake/components/dialog_ui.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/media_conversation/drive_api.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/services/sync_data.dart';

import '../data_channel_webrtc/device_socket.dart';

enum ThemeType { DARK, LIGHT }

class Auth extends ChangeNotifier {
  String _token = "";
  var _expiryDate;
  String _userId = "";
  Timer? _authTimer;
  String _locale = 'en';
  Map? _settings;
  dynamic _socket;
  Map? _channelPendingConnect;
  dynamic _channel;
  bool _isDarkTheme = true;
  bool _isAutoTheme = false;
  bool _isInternet = true;
  bool onFocusApp = true;
  GlobalKey<ScaffoldState> _keyDrawer = GlobalKey<ScaffoldState>();
  bool _isShowMention = false;

  GlobalKey<ScaffoldState> get keyDrawer => _keyDrawer;
  bool get isShowMention => _isShowMention;

  onChangeKeyDrawer(GlobalKey<ScaffoldState> key) {
    _keyDrawer = key;
  }

  onChangeIsShowMention(bool value) {
    _isShowMention = value;
  }

  Auth() {
    getLocale().then((value) {
      _locale = value;
      notifyListeners();
    });
    getTheme().then((type) {
      _isDarkTheme = type == ThemeType.DARK;
      notifyListeners();
    });
    getAutoTheme().then((type) {
      _isAutoTheme = type;
      notifyListeners();
    });
  }

  onChangeCurrentTheme(data, bool value) {
    _isAutoTheme = value ? true : _isAutoTheme;
    var currentTheme = data;
    if ((currentTheme == "NSAppearanceNameAqua" && _isDarkTheme) || (currentTheme == "NSAppearanceNameDarkAqua" && !_isDarkTheme))
      if (_isAutoTheme) {
        if (currentTheme == null) getTheme().then((type) {
          _isDarkTheme = type == ThemeType.DARK;
          notifyListeners();
        });
        else if (currentTheme == "NSAppearanceNameAqua") setTheme(ThemeType.LIGHT, true);
        else setTheme(ThemeType.DARK, true);
      }
  }

  String get locale => _locale;
  set locale(lc) => setLocale(lc);

  void setLocale(lc) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _locale = lc;
    bool status = await preferences.setString('locale', _locale);

    if (status) notifyListeners();
  }

  Future<String> getLocale() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _locale = preferences.getString('locale') ?? "en";
    return _locale;
  }

  ThemeType get theme => _isDarkTheme ? ThemeType.DARK : ThemeType.LIGHT;
  set theme(ThemeType type) => setTheme(type, false);


  void setTheme(ThemeType type, bool isAuto) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _isDarkTheme = type == ThemeType.DARK;
    await preferences.setBool('isAutoTheme', isAuto);
    bool status = await preferences.setBool('isDark', _isDarkTheme);

    if (status) notifyListeners();
  }

  Future<bool> getAutoTheme() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _isAutoTheme = preferences.getBool('isAutoTheme') ?? false;
    return _isAutoTheme;
  }

  Future<ThemeType> getTheme() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var theme = preferences.getBool('isDark');
    _isDarkTheme = theme ?? true ;
    return _isDarkTheme ? ThemeType.DARK : ThemeType.LIGHT;
  }

  bool get isAutoTheme => _isAutoTheme;
  set isAutoTheme(bool isAuto) => setIsAutoTheme(isAuto);

  void setIsAutoTheme(bool isAuto) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _isAutoTheme = isAuto;
    bool status = await preferences.setBool('isAutoTheme', _isAutoTheme);
    await preferences.setBool('isDark', false);

    if(status) notifyListeners();
  }

  focusApp(value) {
    if (onFocusApp != value) {
      onFocusApp = value;
    }
  }

  Map get settings => _settings!;

  Map get channelPendingConnect => _channelPendingConnect!;

  dynamic get socket => _socket;

  dynamic get channel => _channel;

  String get userId => _userId;

  bool get isAuth {
    final isExpiryDate = _expiryDate != null && _expiryDate!.isBefore(DateTime.now()) && _token != "";

    if (token == "" || isExpiryDate) {
      return false;
    } else {
      return true;
    }
  }

  bool get isInternet => _isInternet;

  String get token {
    if (_expiryDate != null &&_expiryDate!.isAfter(DateTime.now()) && _token != "") {
      return _token;
    } else {
      return "";
    }
  }

  Future<dynamic> signUp(String firstName, lastName, email, password, confirmPassword, context) async {
    await Utils.initPairKeyBox();
    var box =  Hive.lazyBox('pairKey');
    var deviceId  = await box.get('deviceId');
    var identityKey  = await box.get('identityKey');
    final url = Utils.apiUrl + 'users/signup';
    try {
      final response = await Dio().post(url, data: {
        "user)_identity_key": identityKey["pubKey"],
        "device_id": deviceId,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "confirm_password": confirmPassword
      });

      return response.data;
    } catch(e) {
      print(e);
      showAlertDialog(context, e.toString());
    }
  }

  Future<dynamic> loginUserPassword(String email, String password, context) async {
    if (email == "" || password == "") return showAlertDialog(context, "Email/phone or password is not empty");
    await Utils.initPairKeyBox();
    String deviceIdentifier = await Utils.getDeviceIdentifier();
    var box =  Hive.lazyBox('pairKey');
    var deviceId  = await box.get('deviceId');
    var identityKey  = await box.get('identityKey');
    final url = Utils.apiUrl + 'users/authorization';
    final currentTime = DateTime.now().microsecondsSinceEpoch;
    try {
      final response = await Dio().post(url, data: {
        "user_identity_key": identityKey["pubKey"],
        "device_id" : deviceId,
        "email": email,
        "password": password,
        "device_identifier": deviceIdentifier,
        "current_time": currentTime,
        "hash": await MessageConversationServices.shaString([
          identityKey["pubKey"],
          deviceId,
          deviceIdentifier,
          email,
          password,
          currentTime.toString(),
          // 1 string ngau nhien o ca client va server
          // key nay se ko dc truyen di theo bat ky api nao, ko dc thay doi
          "oAA6dRwf0fLpn5ecY1AyhV1inY1Y2EmLny1xIUdplm0="
        ], typeOutPut: "base64Url"),
        "device_info": Utils.checkedTypeEmpty(Utils.dataDevice) ? Utils.dataDevice : await Utils.getDeviceInfo()
      });
      final responseData = response.data;

      if (responseData['success'] == false) {
        throw HttpException(responseData['message']);
      }
      _token = responseData['access_token'];
      _userId = responseData['data']['id'];
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(
          responseData['express_in'] * 1000);
      Utils.setIdentityKey(responseData["pub_identity_key"]);
      await uploadPublicKey();
      _autoLogout();
      notifyListeners();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
          'pub_identity_key': responseData["pub_identity_key"],
        },
      );
      prefs.setString('userData', userData);
      if(responseData["data"]["desktop_theme"] == "auto") {
        setIsAutoTheme(true);
      } else if(responseData["data"]["desktop_theme"] == "dark"){
        setTheme(ThemeType.DARK, false);
      } else {
        setTheme(ThemeType.LIGHT, false);
      }

      // Phoenix.rebirth(context);
      return true;
    } catch (e) {
      print(">>>>>>>>>>>>>>>>.");
      await box.clear();
      showAlertDialog(context, e.toString());
    }
  }
    Future<dynamic> forgotPassword(input, type) async {
    final url = Utils.apiUrl + 'users/forgot_password';
    try {
      var response = await Dio().post(url, data: type == "email" ? { "email": input } : { "phone_number": input } );
      return response.data;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> resetPassword(info) async {
    final url = Utils.apiUrl + 'users/reset_password';

    try {
      var response = await Dio().post(url,
        data: {
          "phone_number": info["phone_number"],
          "account_id": info["account_id"],
          "otp": info["otp"],
          "otp_id": info["otp_id"],
          "new_password": info["new_password"]
        }
      );
      return response.data;
    } catch (e) {
      print(e);
    }
  }

  showAlertDialog(BuildContext context, title) {
    Widget okButton = TextButton(
      autofocus: true,
      style: ButtonStyle(
        padding: MaterialStateProperty.all(const EdgeInsets.all(10.0)),
        backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor())
      ),
      child: const Text("Try again", style: TextStyle(color: Colors.white),),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Error"),
      content: Text(title ?? ""),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showErrorDialog(String message){
    var dialogService = sl<DialogService>();

    Future.delayed(const Duration(seconds: 2), (){
      sl<NavigationService>().back();
    });

    dialogService.showCustomDialog(
      variant: DialogType.error,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      customData: message
    );
  }

  bool isBlock = false;
  showAlertMessage(String value, bool isError) async {
    var dialogService = sl<DialogService>();
    isBlock = false;

    Future.delayed(const Duration(seconds: 1), () {
      if(!isBlock) {
        isBlock = false;
        sl<NavigationService>().back();
      }
    });

    await dialogService.showCustomDialog(
      variant: isError ? DialogType.error : DialogType.complete,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      customData: value
    ).then((value) {
      isBlock = true;
    });
  }

  Future<dynamic> loginPancakeId(String token, context) async {
    await Utils.initPairKeyBox();
    var box =  Hive.lazyBox('pairKey');
    var deviceId  = await box.get('deviceId');
    var identityKey  = await box.get('identityKey');

    final url = Utils.apiUrl + 'users/authorization';
    try {
      final response = await Dio().post(url, data: {
        "user_identity_key": identityKey["pubKey"],
        "device_id" : deviceId,
        "authorization_code": token,
        "device_info": Utils.checkedTypeEmpty(Utils.dataDevice) ? Utils.dataDevice : await Utils.getDeviceInfo()
      });
      final responseData = response.data;

      if (responseData['success'] == false) {
        throw HttpException(responseData['message']);
      }
      _token = responseData['access_token'];
      _userId = responseData['data']['id'];
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(
          responseData['express_in'] * 1000);
      Utils.setIdentityKey(responseData["pub_identity_key"]);
      await uploadPublicKey();

      _autoLogout();
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
          'pub_identity_key': responseData["pub_identity_key"]
        },
      );
      prefs.setString('userData', userData);
      // Phoenix.rebirth(context);
    } catch (e) {
      await box.clear();
      print(e);
      sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Future<void> _authenticate(String email, String password, String urlSegment,
      {String phoneNumber = "", String displayName = ""}) async {
    final url = Uri.parse((Utils.apiUrl + 'users/$urlSegment'));

    log(url.toString());
    try {
      final response = await http.post(
        url,
        headers: Utils.headers,
        body: json.encode(
          {
            'userName': email,
            'email': email,
            'phoneNumber': phoneNumber,
            'password': password,
            'displayName': displayName,
            'returnSecureToken': true,
          },
        ),
      );

      final responseData = json.decode(response.body);
      if (responseData['success'] == false) {
        throw HttpException(responseData['message']);
      }

      _token = responseData['access_token'];
      _userId = responseData['data']['id'];
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(
          responseData['express_in'] * 1000);

      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
        },
      );
      prefs.setString('userData', userData);
    } catch (error) {
      print(error);
      sl.get<Auth>().showErrorDialog(error.toString());
    }
  }

  Future<void> register(String displayName, String email, String password,
      String phoneNumber) async {
    return _authenticate(email, password, 'register',
        phoneNumber: phoneNumber, displayName: displayName);
  }

  Future<dynamic> login(String email, String password) async {
    return _authenticate(email, password, 'login_password');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    final extractedUserData = json.decode((prefs.getString('userData') ?? ""));
    final expiryDate = DateTime.parse(extractedUserData['expiryDate'].toString());

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData['token'].toString();
    _userId = extractedUserData['userId'].toString();
    _expiryDate = expiryDate;
    Utils.setIdentityKey(extractedUserData["pub_identity_key"]);
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    try {
      try {
        _socket.disconnect();
        _channel.leave();
      } catch (e) {
      }
      LazyBox box = Hive.lazyBox('pairKey');
      String? deviceId  = await box.get("deviceId");
      var boxLast = Hive.box('lastSelected');
      await boxLast.clear();
      var dataToSend = {
        "data": await Utils.encryptServer({"device_id": deviceId}),
        "device_id": deviceId
      };
      var to = _token;
      _token = "";
      _userId = "";
      _expiryDate = null;
      if (_authTimer != null) {
        _authTimer!.cancel();
        _authTimer = null;
      }
      notifyListeners();
      print("::::::::::::::::::::::::::::::::::::::::::::");
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('userData');
      prefs.remove('cur_tab');
      // khong xoa direct box nua
      // khi chua sync, van co the doc tin nhan trong local
      box.deleteAll(box.keys);
      // directBox.clear();
      Utils.setDeviceId(null);
      String url = "${Utils.apiUrl}users/logout?token=$to";
      await Dio().post(url, data: dataToSend);
      StreamSyncData.instance.initValue();
      await DeviceSocket.instance.reconnect();
    } catch (e) {
      _token = "";
      _userId = "";
      _expiryDate = null;
      Utils.setDeviceId(null);
      LazyBox box = Hive.lazyBox('pairKey');
      box.clear();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('userData');
      prefs.remove('cur_tab');
      await DeviceSocket.instance.reconnect();
      StreamSyncData.instance.initValue();
      print("error cloase $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  rejoinChannel(context) {
    var workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    var channelId = Provider.of<Channels>(context, listen: false).currentChannel["id"];
    final changeToMessage = Provider.of<Workspaces>(context, listen: false).changeToMessage;
    
    if (!changeToMessage) {
      final lastFilters =  Provider.of<Channels>(context, listen: false).lastFilters;
      Provider.of<Channels>(context, listen: false).getListIssue(token, workspaceId, channelId, lastFilters["page"],
        lastFilters["isClosed"], lastFilters["filters"], lastFilters["sortBy"], lastFilters["text"], lastFilters["unreadOnly"]);
    }

    if (channelId != null && workspaceId != null) {
      channel.push(
        event: "join_channel",
        payload: {"channel_id": channelId, "workspace_id": workspaceId}
      );
      Provider.of<Threads>(context, listen: false).getThreadsDesktop(token, workspaceId, true);
      Provider.of<Channels>(context, listen: false).selectChannel(token, workspaceId, channelId);
      getQueueMessages(channelId);
    }
  }

  getQueueMessages(channelId) async {
    try {
      var box = await Hive.openBox('queueMessages');
      List queueMessages = box.values.toList().where((e) => e["channel_id"].toString() == channelId.toString()).toList();
      queueMessages.sort((a, b) => a["inserted_at"].compareTo(b["inserted_at"]));

      for (var i = 0; i < queueMessages.length; i++) {
        if (queueMessages[i]["retries"] > 0) {
          await sendQueueMessage(queueMessages[i], box);
        } else {
          box.delete(queueMessages[i]["key"]);
        }
      }
    } catch (e) {
      print("getQueueMessages error ${e.toString()}");
    }
  }

  sendQueueMessage(message, box) async {
    var workspaceId = message["workspace_id"];
    var channelId = message["channel_id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token';
    for (var i =0; i < message["attachments"].length; i++){
      if (message["attachments"][i]["type"] == "befor_upload")
        message["attachments"][i] = {
          "content_url": message["attachments"][i]["content_url"],
          "key": message["attachments"][i]["key"], 
          "mime_type":  message["attachments"][i]["mime_type"],
          "name": message["attachments"][i]["name"],
          "image_data": message["attachments"][i]["image_data"]
        };
    }
    try {
      final response = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(message));
      final responseData = json.decode(response.body);

      if (responseData['success']) {
        box.delete(message["key"]);
      } else {
        box.put(message["key"], {...message, 'retries': message["retries"] - 1});
      }
    } catch (e) {
      box.put(message["key"], {...message, 'retries': message["retries"] - 1});
      print("sendQueueMessage error ${e.toString()}");
    }
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  Future<void> connectSocket(userId, params, {required BuildContext contextToSync}) async {
    var context = Utils.getGlobalContext();
    var deviceId = await Utils.getDeviceId();
    if (deviceId != null && deviceId.toString().startsWith("v1_")) return logout();
    _socket = new PhoenixSocket(
      Utils.socketUrl, 
      socketOptions: PhoenixSocketOptions(
        heartbeatIntervalMs: 10000
      )
    );
    await _socket.connect();
    _channel = socket.channel("user:$userId", {
      "accessToken": token
    });
    var channel = _channel;
    notifyListeners();

    channel.join().receive("ok", (resp) async => {
      _channel = channel,

      if (token != "") {
        Provider.of<DirectMessage>(context, listen: false).resetStatus(token, _userId),
        Provider.of<Messages>(context, listen: false).resetStatus(token, context),
        Provider.of<User>(context, listen: false).fetchAndGetMe(token).then((_) => p2pManager.init(_channel, this._userId)),
        Provider.of<User>(context, listen: false).getListSavedMessage(token),
        Provider.of<Workspaces>(context, listen: false).getPreloadIssue(token),
        Provider.of<Workspaces>(context, listen: false).getListWorkspace(context ,token),
        Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(token, _userId, isReset: true),
        Provider.of<RoomsModel>(context, listen: false).getRoomIds(token),
        rejoinChannel(context),
        Provider.of<User>(context, listen: false).fetchUserMentionInDirect(token),
        notifyListeners()
      } else {
        print("token in connect socket: null")
      }
    }).receive("error", (resp) => {
      notifyListeners(),
      _channel = channel,
      print("Unable to join $resp")
    });

    channel.on("dm_message", (data, _ref, _joinRef) {
      bool isInMessageView = Provider.of<Workspaces>(context, listen: false).tab == 0;
      Provider.of<DirectMessage>(context, listen: false).onDirectMessage(data["data"], userId, true, false, token, context, isInMessageView: isInMessageView);
    });

    channel.on("on_create_dm", (data, _ref, _joinRef){
      Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(_token, _userId);
    });

    channel.on("update_workspace", (data, _ref, _joinRef){
      Provider.of<Workspaces>(context, listen: false).updateWorkspace(data);
    });

    channel.on("update_workspace_member", (data, _ref, _joinRef){
      Provider.of<Workspaces>(context, listen: false).updateWorkspaceMember(false,
        {
         "user_id" :data["user_id"],
         "role_id" :data["role_id"],
         "nickname" :data["changes"]['nickname']
        },
      );
      Provider.of<Messages>(context, listen: false).onUpdateMessagesChannele({
         "user_id" :data["user_id"],
         "role_id" :data["role_id"],
         "nickname" :data["changes"]['nickname'],
         "workspace_id": data["workspace_id"]
        });
    });

    channel.on("update_current_member", (data, _ref, _joinRef) {
      Provider.of<Workspaces>(context, listen: false).updateCurrentMember(data);
    });

    channel.on("create_channel", (data, _ref, _joinRef) {
      Provider.of<Channels>(context, listen: false).insertDataChannel(data);
      Provider.of<Channels>(context, listen: false).insertChannelMember(data);
      Provider.of<Workspaces>(context, listen: false).changeListChannelMembers({
        "new_user": {
          "channel_id": data["id"],
          "workspace_id": data["workspace_id"],
          "id": data["owner_id"]
        }
      });
    });

    channel.on("update_channel", (data, _ref, _joinRef){
      Provider.of<Channels>(context, listen: false).updateChannel(data, context);
    });

    channel.on("delete_channel", (data, _ref, _joinRef) {
      Provider.of<Channels>(context, listen: false).delChannelToAll(token, data["workpsace_id"], data["channel_id"]);
    });

    channel.on("delete_workspace", (data, _ref, _joinRef){
      Provider.of<Workspaces>(context, listen: false).updateDeleteWorkspace(context, token, data);
    });

    channel.on("update_channel_info", (data, _ref, _joinRef){
      Provider.of<Channels>(context, listen: false).updateChannelInfo(data);
    });

    channel.on("update_dm_message", (data, _ref, _joinRef){
      Provider.of<DirectMessage>(context, listen: false).updateDirectMessage(data, true, true, false);
    });

    channel.on("new_channel", (data, _ref, _joinRef) async{
      final workspace = Provider.of<Workspaces>(context, listen: false);
      final currentWorkspace = workspace.currentWorkspace;
      await workspace.getListWorkspace(context, token);
      await workspace.getInfoWorkspace(token, currentWorkspace["id"], context);
    });

    // sua tin nhan
    channel.on("update_channel_message", (data, _ref, _joinRef) {
      Provider.of<Messages>(context, listen: false).onUpdateChannelMessage(data);
      Provider.of<Threads>(context, listen: false).updateThreadMessage(data);
    });

    channel.on("update_channel_thread_message", (data, _ref, _joinRef){
      Provider.of<Threads>(context, listen: false).updateThreadMessage(data);
    });

    channel.on("broadcast_update_profile", (data, _ref, _joinRef){
      Provider.of<Channels>(context, listen: false).updateProfileChannel(data);
      Provider.of<Workspaces>(context, listen: false).updateWorkspaceMember(true, data);
      Provider.of<Messages>(context, listen: false).onUpdateProfile(data);
      Provider.of<DirectMessage>(context, listen: false).onChangeProfileFriend(data);
      Provider.of<User>(context, listen: false).updateUserProfileData(data);
    });

    //cap nhat tin nhan moi
    channel.on("new_message_channel", (data, _ref, _joinRef){
      final message = data["message"];

      Provider.of<Messages>(context, listen: false).checkNewMessage(message);

      if (message["channel_thread_id"] != null) {
        Provider.of<Messages>(context, listen: false).updateMessage(message);
      } else {
        Provider.of<Workspaces>(context, listen: false).updateUnreadMentionInConver(message, userId);
      }
    });

    channel.on("update_after_delete_thread_message", (data, _ref, _joinRef) {
      final message = data["message"];

      if (message["channel_thread_id"] != null) {
        Provider.of<Messages>(context, listen: false).deleteChildMessage(message);
      }
    });

    channel.on("update_thread", (data, _ref, _joinRef){
      Provider.of<Threads>(context, listen: false).updateThread(token, data, "newMessage", context);
    });

    channel.on("new_thread_count_conversation", (data, _ref, _joinRef) {
      Provider.of<DirectMessage>(context, listen: false).updateCountChildMessage(data["data"], token);
    });

    channel.on("handle_request_conversation_sync", (data, _ref, _joinRef){
      // chi nhung may ;giai dc data moi hien thi
      return Provider.of<DirectMessage>(context, listen: false).handleRequestConversationSync(data["data"] , contextToSync);
    });

    channel.on("logout_device", (data, _f, _j){
      Provider.of<DirectMessage>(context, listen: false).logoutDevice(data);
    });

    channel.on("clear_badge_channel", (data, _ref, _joinRef){
      final channelId = data["channel_id"];

      Provider.of<Channels>(context, listen: false).clearBadge(channelId, null, false);
    });

    // set badge unread count
    channel.on("on_join_dm", (data, ref, joinRef) {
      Provider.of<DirectMessage>(context, listen: false).setUnreadCountConv(data);
    });

    channel.on("delete_message", (data, ref, joinRef) {
      Provider.of<Messages>(context, listen: false).deleteMessage(data);
      Provider.of<Threads>(context, listen: false).updateThread(token, data, "delete_message", context);
    });

    channel.on("delete_saved_message", (data, ref, joinRef) {
      Provider.of<User>(context, listen: false).deleteSavedMessage(data["message_id"]);
    });

    channel.on("reaction_channel_message", (data, ref, joinRef){
      Provider.of<Messages>(context, listen: false).reactionChannelMessage(data);
      Provider.of<Threads>(context, listen: false).updateThread(token, data, "reaction", context);
      Provider.of<Workspaces>(context, listen: false).updateReactionMessageMention(data);
    });

    channel.on("update_poll_message", (data, ref, joinRef){
      Provider.of<Messages>(context, listen: false).updatePollMessage(data);
    });

    channel.on("add_emoji_workspace", (data, ref, joinRef){
      Provider.of<Workspaces>(context, listen: false).addEmojiWorkspace(data);
    });

    channel.on("update_issue", (data, ref, joinRef) async {
      final workspaceId = data["workspace_id"];
      final channelId = data["channel_id"];
      final issueId = data["issue_id"];
      final type = data["type"];
      final payload = data["data"];

      if (data["issue_id"] != null) {
        await Provider.of<Threads>(context, listen: false).updateIssueThread(context, token, workspaceId, channelId, issueId, type, data, userId);
      }

      Provider.of<Channels>(context, listen: false).updateChannelIssue(token, workspaceId, channelId, issueId, type, payload, userId);

      if (type == "new_issue") {
        Provider.of<Workspaces>(context, listen: false).updatePreloadIssue(context, payload);
      }
    });

    channel.on("update_label_and_milestone", (data, _, __) async {
      final workspaceId = data["workspace_id"];
      final channelId = data["channel_id"];
      Provider.of<Channels>(context, listen: false).updateLabelAndMilestone(workspaceId, channelId, token);
    });

    channel.on("new_workspace_member", (data, ref, joinRef) {
      Provider.of<Workspaces>(context, listen: false).newWorkspaceMember(data);
      Provider.of<Workspaces>(context, listen: false).changeListChannelMembers(data);
      Provider.of<Channels>(context, listen: false).newChannelMember(data);
    });

    channel.on("new_channel_member", (data, ref, joinRef) {
      Provider.of<Workspaces>(context, listen: false).changeListChannelMembers(data);
      Provider.of<Channels>(context, listen: false).newChannelMember(data);
    });

    channel.on("new_mention", (data, ref, _j){
      Provider.of<Workspaces>(context, listen: false).newMention(data, userId);
    });
    
    channel.on("delete_mention", (data, ref, _j){
      Provider.of<Workspaces>(context, listen: false).deleteMention(data);
    });

    channel.on("need_broadcast_message_key", (data, ref, _){
      Provider.of<DirectMessage>(context, listen: false).reGetDataDiectMessage(token, _userId);
    });

    channel.on("new_mention_conversation", (data, ref, _) {
      Provider.of<DirectMessage>(context, listen: false).newMentionConversation(data);
    });

    channel.on("update_mention_workspace", (data, ref, _j){
      Provider.of<Workspaces>(context, listen: false).updateMentionWorkspace(data);
    });

    channel.on("update_mentions_issue", (data, ref, _) {
      Provider.of<Channels>(context, listen: false).updateMentionIssue(data);
    });

    channel.on("mark_read_conversation", (data, ref, _j) {
      Provider.of<DirectMessage>(context, listen: false).updateListReadConversation(data["conversation_id"], data);
    });

    channel.on("update_friend_status", (data, ref, _j) {
      Provider.of<User>(context, listen: false).fetchAndGetMe(token);
    });

    channel.on("call", (data, ref, _) {
      Provider.of<P2PModel>(context, listen: false).onMediaEvent(data);
    });

    channel.on("delete_channel_member", (data, ref, joinRef) {
      Provider.of<Channels>(context, listen: false).removeChannelMember(data);
    });

    channel.on("kick_member", (data, ref, joinRef) {
      if (data['type'] == 'channel') {
        Provider.of<Channels>(context, listen: false).deleteMemberFromChannel(token, data);
      } else {
        Provider.of<Workspaces>(context, listen: false).deleteMemberFromWorkspace(context, token, data);
      }
    });

    channel.on("update_online_status", (data, ref, _) {
      final workspaceId = data["workspace_id"];
      final channelId = data["channel_id"];

      if (workspaceId != null && channelId != null) {
        Provider.of<Workspaces>(context, listen: false).updateOnlineStatus(workspaceId, channelId, data);
      } else {

        // update trong conv

      }
    });

    channel.on("online_status_user", (data, _r, _j) {
      Provider.of<DirectMessage>(context, listen: false).updateOnlineStatus(data);
    });
    
    channel.on("update_channel_seen_status", (data, ref, __) {
      Provider.of<Channels>(context, listen: false).updateChannelSeenStatus(data);
    });
      
    channel.on("update_read_mention_from_mobile", (data, ref, __){
      Provider.of<Workspaces>(context, listen: false).updateReadMentionFromMobile(data["data"]);
    });


    // gui lai tin nhan cho nguoi yeu cau tin nhan doc
    // truong hop 1 nguoi nao do trong hoi thoai mat tin nhan thi se yeu cau cac thanh vien (co tin nhan do) se gui lai dua tren key cua nguoi dau tien gui tin nhan
    channel.on("resend_message_conversation", (data, _ref, _joinRef) {
      MessageConversationServices.resendMessageConversation(token, data as Map, context);
    });

    channel.on("revice_data_sync", (data, _f, _j)async{
      try {
        var dataServer  = await Utils.decryptServer(data["data"]);
        if (dataServer["success"]){
          LazyBox box  = Hive.lazyBox('pairKey');
          var identityKey =  await box.get("identityKey");
          var iKey  = dataServer["data"]["public_key_decrypt"];
          var masterKey = await const X25519().calculateSharedSecret(KeyP.fromBase64(identityKey["privKey"], false), KeyP.fromBase64(iKey, true));
          var messageDeStr =  Utils.decrypt(dataServer["data"]["data"], masterKey.toBase64());
          var dataMessage  = (jsonDecode(messageDeStr))["data"];
          List dataToSave  = [];

          try {
            dataToSave = dataMessage as List;            
          } catch (e) {
            (dataMessage as Map).forEach((key, value) => dataToSave += [value]);
          }
          await MessageConversationServices.insertOrUpdateMessages(dataToSave, moveFromHive: true);
          StreamSyncData.instance.setSyncStatus(dataToSave.length);
        }
      } on Exception catch (e) {
        print("revice_data_sync $e");
      }
    });

    // data tin nhan chua doc cua messages
    channel.on("data_message_unread", (data, _r, _j){
      Provider.of<DirectMessage>(context, listen: false).dataMessageUnread(data);
    });

    // cap nhat thread khi thread trong dm thay doi
    channel.on("new_thread_user", (data, _r, _j){
      Provider.of<DirectMessage>(context, listen: false).updateThreadUser(data);
    });

    // xoa tin nhan dm
    channel.on("delete_message_dm", (data, _r, _j){
      final conversationId = data["conversation_id"];
      data["message_ids"].map((mid) => Provider.of<DirectMessage>(context, listen: false).updateDeleteMessage(token, conversationId, mid)).toList();
    });


    // xoa tin nhan cho minh dm
    channel.on("delete_for_me", (data, _r, _j){
      final conversationId = data!["conversation_id"];
      data["message_ids"].map((mid) => Provider.of<DirectMessage>(context, listen: false).updateDeleteMessage(token, conversationId, mid, type: "delete_for_me")).toList();
    });
    
    channel.on("update_number_unread_issues", (data, ref, joinRef){
      Provider.of<Channels>(context, listen: false).updateNumberUnreadIssues(data);
    });

    channel.on("change_conversation_name", (data, _r, _f){
      Provider.of<DirectMessage>(context, listen: false).changeConversationName(data, userId);
    });

    channel.on('update_conversation', (data, _r, _f) {
      Provider.of<DirectMessage>(context, listen: false).updateConversation(data, token, userId);
    });

    // cap nhat so luong hoi thoai chua doc
    channel.on("update_count_conversation_unread", (data, _r, _j){
      Provider.of<DirectMessage>(context, listen: false).updateUnreadConversation(data);
    });

    // xoa lich su tro chuyen(o phia minh)
    channel.on("delete_history_conversation", (data, _r, _f){
      Provider.of<DirectMessage>(context, listen: false).deleteHistoryConversation(data, userId);
    });

    // roi khoi nhom group, xoa 1-1
    channel.on("action_leave_or_delete_conversation", (data, _r, _f){
      Provider.of<DirectMessage>(context, listen: false).leaveOrDeleteConversation(data!["conversation_id"], userId);
    });

    // lay data token google,
    channel.on("login_google_data", (data, _r, _j){
      DriveService.setDataLogin(data["access_token"] ??  data["accessToken"]);
      WindowManager.instance.wakeUp();
      notifyListeners();
    });
  }

  setInternetConnect(status) {
    _isInternet = status;
  }

  uploadPublicKey() async{
    try {
      var box =  Hive.lazyBox('pairKey');
      var iKey =  Utils.identityKey;
      final url  =  "${Utils.apiUrl}/users/upload_publickey?token=$token";
      var identityKey =  await box.get("identityKey");

      var deviceId  = await box.get('deviceId');
      var signedKey =  await box.get("signedKey");
      // print("__signedKey___${signedKey["pubKey"]} ____ ${signedKey["privKey"]}");
      var jsonData  = {
        "pub_key": signedKey["pubKey"],
        "device_id": deviceId,
      };
      var jsonDataString =  jsonEncode(jsonData);
      var masterKey = await const X25519().calculateSharedSecret(KeyP.fromBase64(identityKey["privKey"], false), KeyP.fromBase64(iKey, true));

      var dataEncrypted =  Utils.encrypt(jsonDataString, masterKey.toBase64());
      var response = await Dio().post(url, data: {
        "data": dataEncrypted,
        "device_id": deviceId,
      });
      if (response.data["success"]){
        var dataResponse = await Utils.decryptServer(response.data["data"]);
        if (dataResponse["success"]){
          await box.put("id_default_private_key", dataResponse["data"]["id_default_pr_key"]);
        }        
      }

    } catch (e) {
      await logout();
    }
  }
}
