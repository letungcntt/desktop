import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as En;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:workcake/E2EE/e2ee.dart';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/providers/providers.dart';

import '../isar/message_conversation/service.dart';
class Utils {
  // Check api and socket url with mode
  static String apiUrl = 'https://chat.pancake.vn/api/';
  static String socketUrl = 'wss://chat.pancake.vn/socket/websocket';
  static String clientId = '310e01831d194a4dae4f37633cbec841';
  static String publicKey = "";
  static String privKey = "";
  static String identityKey = "";
  static Map? dataDevice;
  static String? _deviceId;
  static String panchatSupportId = "9e702ec5-7a22-42ed-a289-3c8c55692523";

  static String get deviceId  => _deviceId ?? "";

  static setIdentityKey(newK){
    identityKey = newK;
  }

  static setPairKey(pairkey){
    publicKey = pairkey["pubKey"];
    privKey = pairkey["privKey"];
  }
  static String primaryColor = '0xFF2A5298';

  static bool get debugMode {
    var debug = false;
    assert(debug = true);
    return debug;
  }

  static checkDebugMode() {
    assert(() {
      // apiUrl = 'https://3928-27-72-63-124.ngrok.io/api/';
      // socketUrl = 'wss://3928-27-72-63-124.ngrok.io/socket/websocket';
      apiUrl = 'https://chat.pancake.vn/api/';
      socketUrl = 'wss://chat.pancake.vn/socket/websocket';
      clientId = 'c726228820114ea4a785898f8c4f7b53';
      return true;
    }());
  }

  static Future<String> getIpDevice() async {
    var response = await Dio().get('https://api.ipify.org?format=json');
    var dataRes = response.data;
    try {
      return dataRes["ip"];
    } catch (e) {
      return "";
    }
  }

  static Future<String> getDeviceName()async{
    try {
      var deviceInfo = DeviceInfoPlugin();
      if (Platform.isMacOS) {
        return "MacOS";
      } else if (Platform.isLinux) {
        return "Linux";
      } else if (Platform.isWindows) {
        return "Windows";
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model ?? "";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name ?? "";
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  static getDeviceInfo() async {
    try {
      if (Utils.checkedTypeEmpty(dataDevice)) return dataDevice;
      dataDevice = {
        "ip": await getIpDevice(),
        "name": await getDeviceName(),
        "platform": Platform.operatingSystem.toLowerCase()
      };
      return dataDevice;
    } catch (e) {
      return {};
    }
  }

  static getPrimaryColor() {
    return Color(0xff1890FF);
  }

  static getUnHighlightTextColor(){
    return Color(0xffcce6ff);
  }
  static getHighlightTextColor(){
    return Color(0xffffffff);
  }

  static isWinOrLinux() {
    if (Platform.isLinux || Platform.isWindows) {
      return true;
    } else {
      return false;
    }
  }

  static const headers = <String, String>{
    'Content-Type': 'application/json; charset=UTF-8'
  };

  _parseAndDecode(String response) {
    return jsonDecode(response);
  }

  parseJson(String text) {
    return compute(_parseAndDecode, text);
  }

  static postHttp(String url, Map body) async {
    try {
      Response response = await Dio().post(url, data: json.encode(body));
      return json.decode(response.data);
    } catch (e) {
      print(e);
    }
  }

  static getHttp(String url) async {
    try {
      Response response = await Dio().get(url);
      return response.data;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static deleteHttp(String url) async {
    try {
      Response response = await Dio().delete(url);
      return response.data;
    } catch (e) {
      print(e);
    }
  }

  static checkedTypeEmpty(data) {
    if (data == "" || data == null || data == false || data == 'false') {
      return false;
    } else {
      return true;
    }
  }

  static parseLocale(locale) {
    switch (locale) {
      case "vi":
        return "Vietnamese";
      case "en":
        return "English";
      default:
        return "English";
    }
  }

  static getRandomString(int length){
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static getRandomNumber(length){
    const _chars = '1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static getString(String string, length) {
    // if (string  == null) return "";
    var lengthS  =  string.length;
    if (lengthS <= length) return string;
    return string.substring(0, length - 1) + "...";
  }
  static Map mergeMaps(List<Map> arr) {
    if (arr.length == 0 ) return {};

    Map result = Map.from(arr[0]);
    int lengthArr  =  arr.length;
    for (var i = 1; i < lengthArr; i++){
      Map draft = Map.from(arr[i]);
      draft.forEach((key, value) {
        if (key == "id"){
          if (checkedTypeEmpty(value)) result[key] = value;
        }
        else result[key] = value;
      });
    }
    return result;
  }

  static encrypt(String str, String masterKey){
    // print(str);
    // return "";
    final key = En.Key.fromBase64(masterKey);
    final iv  =  En.IV.fromLength(16);
    final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
    return  encrypter.encrypt(str, iv: iv).base64;
  }

  static encryptBytes(List<int> bytes, String masterKey){
    final key = En.Key.fromBase64(masterKey);
    final iv  =  En.IV.fromLength(16);
    final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
    return  encrypter.encryptBytes(bytes, iv: iv).bytes;
  }

  static decryptBytes(List<int> bytes, String masterKey){
    final key = En.Key.fromBase64(masterKey);
    final iv  =  En.IV.fromLength(16);
    final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
    var encrypted =  En.Encrypted(Uint8List.fromList(bytes));
    return encrypter.decryptBytes(encrypted, iv: iv);
  }

  static decrypt(String str, String masterKey){
    final key = En.Key.fromBase64(masterKey);
    final iv  =  En.IV.fromLength(16);
    final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
    var encrypted =  En.Key.fromBase64(str);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  static decryptMessage(Map message, String sharedKey){
    try {
      var decryptData  = decrypt(message["message"], sharedKey);
      decryptData = decryptData.substring(0, decryptData.length);
      decryptData = jsonDecode(decryptData);
      var resultData  = Map.from(message);
      // resultData["message"] = decryptData["message"];
      // resultData["attachments"] = decryptData["attachments"];
      return {
        "success": true,
        "message": resultData,
        "data": decryptData
        };
      } catch (e, t) {
        print("$e, $t");
        return {
        "success": false,
        "message": "Error"
        };
      }

  }

  static initPairKeyBox()async{
    try {
      var boxKey  = await Hive.openLazyBox("pairKey");
      var deviceId = await boxKey.get('deviceId');
      var identityKey = await boxKey.get("identityKey");
      var signedKey  = await boxKey.get("signedKey");
      // gen new Curve25519
      if (deviceId == null || identityKey ==  null ||  signedKey == null){
        // gen a pairKey identity
        var identityKey = await X25519().generateKeyPair();
        await boxKey.put("identityKey", {
          "pubKey": identityKey.publicKey.toBase64(),
          "privKey": identityKey.secretKey.toBase64()
        });
        final signedKey =  await X25519().generateKeyPair();
        // print("_____${signedKey.publicKey.toBase64()} ____ ${signedKey.secretKey.toBase64()}");
        await boxKey.put('signedKey', {
          "pubKey": signedKey.publicKey.toBase64(),
          "privKey": signedKey.secretKey.toBase64()
        });

        var newId  = "v4_" + MessageConversationServices.shaString([
          identityKey.publicKey.toBase64(),
          await Utils.getDeviceIdentifier(),
          // key nay se ko dc truyen di theo bat ky api nao, ko dc thay doi
          "fhl9gBRZa8jLmT2wwTmMdS2M6YHiqLsHNpb85oEStNM="
        ]);
        _deviceId = newId;
        await boxKey.put("deviceId", newId);
      }
    } catch (e) {
      print("_________$e");
    }

  }

  static encryptServer(Map data) async{
    LazyBox box  = Hive.lazyBox('pairKey');
    var idKey =  await box.get("identityKey");
    var masterKey = await X25519().calculateSharedSecret(KeyP.fromBase64(idKey["privKey"], false), KeyP.fromBase64(identityKey, true));
    var e = jsonEncode(data);
    return Utils.encrypt(e, masterKey.toBase64());
  }

  static decryptServer(String dataM) async {
    LazyBox box = Hive.lazyBox('pairKey');
    Map idKey = await box.get("identityKey");
    var sharedKey = await X25519().calculateSharedSecret(KeyP.fromBase64(idKey["privKey"], false), KeyP.fromBase64(identityKey, true));
    return decryptMessage({"message": dataM}, sharedKey.toBase64());
  }

  static genSharedKeyOnGroupByUser() async {
    var pairKey  = await X25519().generateKeyPair();
    return pairKey.secretKey.toBase64();
  }

  static openFilePicker(List<XTypeGroup>? optionGroup) async {
    final files = await FileSelectorPlatform.instance.openFiles(acceptedTypeGroups: optionGroup ==  null ? [] : optionGroup);
    final paths = files.map((e){
      return Platform.isWindows ? "${e.path}" : "file://${e.path}";
    }).toList();
    var dataFiles = await Future.wait(
      paths.map((e) async{
        try {
          var uri = e.replaceAll("%2520", "%20");
          var file = Platform.isWindows ? File(uri) : File.fromUri(Uri.parse(uri));
          var name = Platform.isWindows ? file.path.split("\\").last : e.split("/").last;
          var type = name.split(".").last.toLowerCase();
          if (type == "png" || type == "jpg" || type == "jpeg" || type == "webp") type = "image";
          if (type == "") type = "text";
          var fileData  = await file.readAsBytes();
          var checkfile = Work.checkTypeFile(fileData);
          if (checkfile  == ".png" || checkfile == ".jpg" || checkfile == ".jpeg" ||checkfile == ".gif") type = "image";
          else type = checkfile != "" ? checkfile : type;
          return {
            "name": name,
            "type": type,
            "mime_type":  name.split(".").last.toLowerCase(),
            "path": file.path,
            "file": fileData,
            "size": getFileSize(file.path, 1)
          };
        } catch (e) {
          print(e.toString());
        }
      })
    );
    return dataFiles.where((element) => element != null).toList();
  }

  static Future<String> onRenderSnippet(url, {String? keyEncrypt }) async{
    try{
      if (keyEncrypt != null) {
        Response response = await Dio().get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            receiveTimeout: 0
            ),
          );
        var string = utf8.fuse(base64).decode(await decrypt(base64Encode(response.data) ,keyEncrypt));
        return string;
      } else {
        var client = HttpClient();
        const utf8 = const Utf8Codec();
        var uri = Uri.parse(url);

        var request =  await client.getUrl(uri);
        var response =  await request.close().timeout(const Duration(seconds: 2));
        var responseBody = await response.transform(utf8.decoder).join();
        return responseBody;
      }
    } on TimeoutException catch (e) {
      return e.toString();
    } on SocketException catch (e) {
      return e.toString();
    } catch (err) {
      return err.toString();
    }
  }

  static handleSnippet(url, value) async{
    String responseBody = await onRenderSnippet(url);

    String myBackspace(String str) {
      Runes strRunes = str.runes;
      str = String.fromCharCodes(strRunes, 0, strRunes.length - 1);
      return str;
    }

    var responseBodyTrim = responseBody.replaceAll('<p>', '').replaceAll('</p>', '\n').replaceAll('</div></body></html>', '')
      .replaceAll('<html><head><title>snippet</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta charset="UTF-8"></head><body><div style="padding:12px">', '');
    final splitSnippet = responseBodyTrim.split("\n");
    int lengthString = splitSnippet.length >= 16 ? 16 : splitSnippet.length;

    List newMessage = [];
    for(int i = 0; i < lengthString; i++) {
      newMessage.add(splitSnippet[i]);
    }

    return !value ? newMessage.join("\n").trim().length > 3500 ? myBackspace(newMessage.join("\n").trim().substring(0, 3500)) + "..." : newMessage.join("\n").trim() : responseBodyTrim.trim();
  }

  static getDeviceId()async{
    if (Utils.checkedTypeEmpty(_deviceId)) return _deviceId;
    var box = Hive.lazyBox('pairKey');
    _deviceId = await box.get("deviceId");
    return _deviceId;
  }

  // server chi update cho nhung device chua co thong tin device (ip, name, ...)
  static uploadDeviceInfo(String token) async {
    var url  = "${Utils.apiUrl}users/update_device_info?token=$token&device_id=${await getDeviceId()}";
    Dio().post(url, data: {
      "data": await encryptServer({
        "device_info": await getDeviceInfo()
      })
    });
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

  static convertCharacter(String text){
    final _vietnamese = 'aâăAÂĂeêEÊoôơOÔƠuưUƯyY';
    final _vietnameseRegex = <RegExp>[
      RegExp(r'à|á|ạ|ả|ã'),
      RegExp(r'â|ầ|ấ|ậ|ẩ|ẫ'),
      RegExp(r'ă|ằ|ắ|ặ|ẳ|ẵ'),
      RegExp(r'À|Á|Ạ|Ả|Ã'),
      RegExp(r'Â|Ầ|Ấ|Ậ|Ẩ'),
      RegExp(r'Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ'),
      RegExp(r'è|é|ẹ|ẻ|ẽ'),
      RegExp(r'ê|ề|ế|ệ|ể|ễ'),
      RegExp(r'È|É|Ẹ|Ẻ|Ẽ'),
      RegExp(r'Ê|Ề|Ế|Ệ|Ể|Ễ'),
      RegExp(r'ò|ó|ọ|ỏ|õ'),
      RegExp(r'ô|ồ|ố|ộ|ổ|ỗ'),
      RegExp(r'ơ|ờ|ớ|ợ|ở|ỡ'),
      RegExp(r'Ò|Ó|Ọ|Ỏ|Õ'),
      RegExp(r'Ô|Ồ|Ố|Ộ|Ổ|Ỗ'),
      RegExp(r'Ơ|Ờ|Ớ|Ợ|Ở|Ỡ'),
      RegExp(r'ù|ú|ụ|ủ|ũ'),
      RegExp(r'ư|ừ|ứ|ự|ử|ữ'),
      RegExp(r'Ù|Ú|Ụ|Ủ|Ũ'),
      RegExp(r'Ư|Ừ|Ứ|Ự|Ử|Ữ'),
      RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'),
      RegExp(r'Ỳ|Ý|Ỵ|Ỷ|Ỹ')
    ];

    var result = text;
    for (var i = 0; i < _vietnamese.length; ++i) {
      result = result.replaceAll(_vietnameseRegex[i], _vietnamese[i]);
    }
    return result.toLowerCase();
  }

  static parseDatetime(time) {
    if (time != "" && time != null) {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;
      final int hour = difference ~/ 60;
      final int minutes = difference % 60;
      final int day = hour ~/24;

      if (day > 0) {
        int month = day ~/30;
        int year = month ~/12;
        if (year >= 1) return '${year.toString().padLeft(1, "")} ${year > 1 ? "years" : "year"} ago';
        else {
          if (month >= 1) return '${month.toString().padLeft(1, "")} ${month > 1 ? "months" : "month"} ago';
          else return '${day.toString().padLeft(1, "")} ${day > 1 ? "days" : "day"} ago';
        }
      } else if (hour > 0) {
        return '${hour.toString().padLeft(1, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else if(minutes <= 1) {
        return 'moment ago';
      } else {
        return '${minutes.toString().padLeft(1, "0")} minutes ago';
      }
    } else {
      return "Offline";
    }
  }

  static updateBadge(context) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    Future.delayed(Duration(milliseconds: 500), () {
      var macOSPlatformChannelSpecifics = new MacOSNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
        badgeNumber: checkNewBadgeCount(context)
      );

      if (Platform.isMacOS) Future.delayed(Duration(milliseconds: 100), () {
        var platformChannelSpecifics = NotificationDetails(macOS: macOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(
          0, "", "",
          platformChannelSpecifics
        );
      });
    });
  }

  static checkNewBadgeCount(context) {
    num count = 0;

    try {
      final channels = Provider.of<Channels>(context, listen: false).data;
      final data = Provider.of<DirectMessage>(context, listen: false).data;
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final dataThreads = Provider.of<Threads>(context, listen: false).dataThreads;

      for (var c in channels) {
        if (c["new_message_count"] != null) {
          count += int.parse(c["new_message_count"].toString());
        }
      }

      for (var d in data) {
        if (d.newMessageCount != null) {
          count += int.parse(d.newMessageCount.toString());
        }
      }

      final indexThread = dataThreads.indexWhere((e) => e["workspaceId"] == currentWorkspace["id"]);

      if (indexThread != -1) {
        final threads = dataThreads[indexThread]["threads"];

        for (var i = 0; i < threads.length; i++) {
          count += threads[i]["mention_count"] ?? 0;
        }
      }
    } catch (e, trace) {
      print("line 499 ${e.toString()} $trace");
    }

    return count;
  }

  static String getStringFromParse(List parses){
    return parses.map((e) {
      if (e["type"] == "text") return e["value"];
      return "${e["trigger"]}${e["name"]}";
    }).toList().join("");
  }

  static void setDeviceId(param0) {
    _deviceId = param0;
  }

  static String getFileSize(String filepath, int decimals) {
    var file = File(filepath);
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }

  static BuildContext? globalMaterialContext;
  static BuildContext? globalContext;
  static getGlobalContext() { return globalContext; }
  static setGlobalContext(context) { globalContext = context; }

  static BuildContext? loginContext;

  static Map statusOrder(statusId) {
    switch (statusId) {
      case 0:
        return {
          "text": "Mới",
          "color": 0xff00a2ae
        };
      case 1:
        return {
          "text": "Đã xác nhận",
          "color": 0xff108ee9
        };
      case 2:
        return {
          "text": "Đã gửi hàng",
          "color": 0xfff79009
        };
      case 3:
        return {
          "text": "Đã nhận",
          "color": 0xff3dbd7d
        };
      case 4:
        return {
          "text": "Đang hoàn",
          "color": 0xffe74b3c
        };
      case 5:
        return {
          "text": "Đã hoàn",
          "color": 0xffa31837
        };
      case 6:
        return {
          "text": "Đã huỷ",
          "color": 0xffd73435
        };
      case 7:
        return {
          "text": "Đã xoá",
          "color": 0xff962223
        };
      case 8:
        return {
          "text": "Đang đóng hàng",
          "color": 0xff7265e6
        };
      case 9:
        return {
          "text": "Chờ chuyển hàng",
          "color": 0xffE34999
        };
      case 11:
        return {
          "text": "Chờ hàng",
          "color": 0xffb49f09
        };
      case 12:
        return {
          "text": "Chờ in",
          "color": 0xff1775d1
        };
      case 13:
        return {
          "text": "Đã in",
          "color": 0xff1234EF
        };
      case 15:
        return {
          "text": "Hoàn một phần",
          "color": 0xff005667
        };
      case 16:
        return {
          "text": "Đã thu tiền",
          "color": 0xff004c32
        };
      case 17:
        return {
          "text": "Chờ xác nhận",
          "color": 0xff69c0ff
        };
      case 20:
        return {
          "text": "Đã đặt hàng",
          "color": 0xff13c2c2
        };
      default:
        return {
          "text": "Mới",
          "color": 0xff00a2ae
        };
    }
  }

  static BuildContext? hoverMessageContext;
  static BuildContext? getHoverMessageContext() { return hoverMessageContext; }
  static setHoverMessageContext(BuildContext? context) { hoverMessageContext = context; }

  static List<String> languages = [
    "c", "cc", "h", "c++", "h++", "hpp", "hh", "hxx", "cxx", "csharp", "c#", "pb", "pbi"
    'asc', 'apacheconf', 'osascript', 'arcade', 'arm', 'ahk', 'sh', 'zsh', 'cmake.in', "coffee", "cson", "iced",
    'jinja', 'docker', "bat", "cmd", 'erl', 'elixir', 'gms', 'golang', 'gql', 'https', 'http', 'hylang',
    'jsp', "js", "jsx", "mjs", "cjs", 'kt', 'ls', "mk", "mak", "md", "mkdown", "mkd", 'moon', 'nginxconf', 'nixos', "mm", "objc", "obj-c",
    'ml', 'scad', "pl", "pm", 'pf.conf', "postgres", "postgresql", "php", "php3", "php4", "php5", "php6", "php7", "ps", "ps1", 'pp',
    "py", "gyp", "ipython", "k", "kdb", 'qt', 're', "graph", "instances", "routeros", "mikrotik", "rb", "gemspec", "podspec", "thor", "irb",
    'rs', "sas", "SAS", 'sci', 'console', 'smali', 'st', 'ml', 'sol', 'sqf', 'stanfuncs', 'do', 'ado', "p21", "step", "stp", 'styl', 'tk',
    'craftcms', 'ts', 'vb', 'vbs', "v", "sv", "svh", 'tao', "html", "xhtml", "rss", "atom", "xjb", "xsd", "xsl", "plist", "wsf", "svg",
    "xpath", "xq", "yml", "YAML", "yaml", 'zep', 'dart', 'json', 'sql', 'swift', 'txt'
  ];

  static getLanguageFile(String text) {
    switch (text) {
      case 'cc':
      case 'c':
      case 'h':
      case 'cpp':
        return 'c';

      case 'sh':
      case 'zsh':
        return 'zsh';

      case 'ex':
      case 'exs':
        return 'elixir';

      case 'mm':
      case 'm':
        return 'objc';

      case 'py':
      case 'gyp':
      case 'ipy':
        return 'py';

      case "yml":
      case "YAML":
      case "yaml":
        return 'yaml';

      case 'go':
        return 'golang';

      default:
        return text;
    }
  }

  static String suffixNameFile(value, fileItems) {
    int i = 0;
    String formattedDate = DateFormat('yyyy-MM-dd–kk:mm').format(DateTime.now());
    String text = value + '_$formattedDate';
    bool check = true;
    while (check) {
      int index = fileItems.indexWhere((e) => e["name"] == '$text.txt');
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

  static String? getUserNickName(String? userId) {
    List members = Provider.of<Workspaces>(Utils.globalContext!, listen: false).members;
    List nickNameMembers = members.where((ele) => Utils.checkedTypeEmpty(ele['nickname'])).toList();
    int indexNickName = nickNameMembers.indexWhere((user) => userId == user["id"]);

    return indexNickName == -1 ? null : (nickNameMembers[indexNickName]["nickname"] ?? nickNameMembers[indexNickName]['full_name']);
  }

  static Future<String> getDeviceIdentifier() async {
    try {
      if (Platform.isMacOS) {
        final deviceInfoPlugin = DeviceInfoPlugin();
        return (await deviceInfoPlugin.macOsInfo).systemGUID.toString();
      }
      return (await PlatformDeviceId.getDeviceId).toString();
    } catch (e) {
      return "";
    }
  }

  static Map getMimeTypeFromBytes(List<int> bytes) {
    String subBytes = bytes.sublist(0, 20).join();
    var mimeType;
    var type;

    if (subBytes.startsWith("255216")) {
      mimeType = 'jpeg';
      type = 'image';
    } else if (subBytes.startsWith("137807") || subBytes.startsWith("7777") || subBytes.startsWith("6677")) {
      mimeType = 'png';
      type = 'image';
    } else if (subBytes.startsWith("00024") || subBytes.startsWith("00028") || subBytes.startsWith("00032")) {
      mimeType = 'mp4';
      type = 'video';
    } else if (subBytes.startsWith("00020")) {
      mimeType = 'mov';
      type = 'video';
    } else if (subBytes.startsWith("807534200888048") || subBytes.startsWith("807534200608") 
      || subBytes.startsWith("8075342008880120") || subBytes.startsWith("8075342008880101") 
      || subBytes.startsWith("8075341000000174") || subBytes.startsWith("8075342008880377")
      || subBytes.startsWith("8075342008880549")
    ) {
      mimeType = 'xlsx';
      type = 'file';
    } else if (subBytes.startsWith("8075342008880143")) {
      mimeType = 'docx';
      type = 'file';
    } else if (subBytes.startsWith("3780687045")) {
      mimeType = 'pdf';
      type = 'file';
    } 

    if (type == null) {
      return {};
    } else {
      return {
        "mimeType": mimeType,
        "type": type
      };
    }
  }

  static formatNumber(num) {
    final number = NumberFormat.compactCurrency(
      decimalDigits: 0,
      locale: 'en',
      symbol: '',
    ).format(num);

    return number;
  }

  static compareTime(TimeOfDay time) {
    TimeOfDay now = TimeOfDay.now();
    if (now.hour < time.hour) return false;
    if (now.hour > time.hour) return true;
    if (now.minute <= time.minute) return false;
    if (now.minute > time.minute) return true;
  }

  static Widget renderElementForm(context, ele, isDark) {
    switch (ele["id"]) {
      case 1:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 2:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 3:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 4:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${DateFormatter().renderTime(DateTime.parse(ele['value']), type: 'yMMMMd')}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 5:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 6:
        return Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Expanded(child: Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)))
            ],
          )
        );
      case 7:
        return Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Expanded(
                child: Wrap(
                  children: [
                    ...ele["value"].map((att) {
                      return Container(
                        margin: EdgeInsets.only(right: 3),
                        child: InkWell(
                          child: CachedImage(att["content_url"], width: 66, height: 84, radius: 2)),
                      );
                    }).toList()
                  ],
                )
              )
            ],
          )
        );
      case 8:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 9:
        final dateTime = ele["value"].split(" - ");
        return Container(
          child: Column(
            children: [
              Row(
                children: [
                  Text("Từ ngày: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                  Text("${DateFormatter().renderTime(DateTime.parse(dateTime[0]), type: 'yMMMMd')}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text("Đến ngày: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                  Text("${DateFormatter().renderTime(DateTime.parse(dateTime[1]), type: 'yMMMMd')}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                ],
              ),
            ],
          )
        );
      case 10:
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${ele["value"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
      case 11:
        final channels = Provider.of<Channels>(context, listen: false).data;
        final index = channels.indexWhere((c) => c['id'] == ele['value']);
        if (index != -1) return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Text("${channels[index]['name']}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
            ],
          )
        );
        return Container();
      case 12:
        final members = Provider.of<Workspaces>(context, listen: false).members;
        return Container(
          child: Row(
            children: [
              Text("${ele["label"]}: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              Expanded(
                child: Wrap(
                  children: [
                    ...ele['value'].map((e) {
                      final index = members.indexWhere((m) => m["id"] == e);
                      if (index != -1) return CachedImage(
                        members[index]['avatar_url'],
                        width: 30,
                        height: 30,
                        isAvatar: true,
                        radius: 50,
                        name: members[index]['full_name']
                      );
                      return Container();
                    }).toList()
                  ],
                ),
              )
            ],
          )
        );
      default:
        return Container();
    }
  }
}

final listAllApp = [
  {
    "id": 1,
    "name": "Snappy",
    "avatar_app": "assets/images/logo_app/snappy.jpg",
    "description": "Bring Snappy into Pancake Chat."
  },
  {
    "id": 2,
    "name": "POS",
    "avatar_app": "assets/images/logo_app/pos_app.png",
    "description": "Đồng bộ tin nhắn từ những trạng thái cấu hình POS."
  },
  {
    "id": 3,
    "name": "Zimbra",
    "avatar_app": "assets/images/logo_app/zimbra.png",
    "description": "Send emails into Pancake Chat to discuss them with your teammates."
  },
  {
    "id": 4,
    "name": "Biz Banking",
    "avatar_app": "assets/images/logo_app/bank_app.png",
    "description": "Thông báo biến động tài khoản ngân hàng."
  },
  {
    "id": 5,
    "name": "Github",
    "avatar_app": "assets/images/logo_app/github.png",
    "description": "Get updates from the world’s leading development platform on Pancake Chat."
  },
  {
    "id": 6,
    "name": "Trello",
    "avatar_app": "assets/images/logo_app/trello.png",
    "description": "Collaborate on Trello projects without leaving Pancake Chat."
  },
  {
    "id": 7,
    "name": "Twitter",
    "avatar_app": "assets/images/logo_app/twitter.png",
    "description": "Bring tweets into Pancake Chat."
  },
  {
    "id": 8,
    "name": "Google Calendar",
    "avatar_app": "assets/images/logo_app/google-calendar.png",
    "description": "See your schedule, respond to invites, and get event updates."
  },
  {
    "id": 9,
    "name": "Pancake Chat for Gmail",
    "avatar_app": "assets/images/logo_app/gmail.png",
    "description": "Send emails into Pancake Chat to discuss them with your teammates."
  },
  {
    "id": 10,
    "name": "Zoom",
    "avatar_app": "assets/images/logo_app/zoom.png",
    "description": "Easily start a Zoom video meeting directly from Pancake Chat."
  },
  {
    "id": 11,
    "name": "Google Drive",
    "avatar_app": "assets/images/logo_app/google-drive.png",
    "description": "Get notifications about Google Drive files within Pancake Chat."
  },
  // {
  //   "id": 12,
  //   "name": "VIB",
  //   "avatar_app": "assets/images/logo_app/logo-vib.png",
  //   "description": "Log in vib account"
  // }
];

final List<Map<String, dynamic>> listForms = [
  {
    "id": 1,
    "key": "title",
    "label": "Tiêu đề",
    "type": "input"
  },
  {
    "id": 2,
    "key": "fullName",
    "label": "Họ tên",
    "type": "input"
  },
  {
    "id": 3,
    "key": "phoneNumber",
    "label": "Số điện thoại",
    "type": "input"
  },
  {
    "id": 4,
    "key": "dateTime",
    "label": "Ngày tháng",
    "type": "dateTime"
  },
  {
    "id": 5,
    "key": "time",
    "label": "Giờ phút",
    "type": "time"
  },
  {
    "id": 6,
    "key": "description",
    "label": "Lý do/Mô tả",
    "type": "textArea"
  },
  {
    "id": 7,
    "key": "attachment",
    "label": "Tệp đính kèm",
    "type": "button"
  },
  {
    "id": 8,
    "key": "amount",
    "label": "Số tiền",
    "type": "input"
  },
  {
    "id": 9,
    "key": "dateRange",
    "label": "Khoảng thời gian",
    "type": "dateRange"
  },
  {
    "id": 10,
    "key": "number",
    "label": "Số lượng",
    "type": "input"
  },
  {
    "id": 11,
    "key": "channel",
    "label": "Chọn channel",
    "type": "select"
  },
  {
    "id": 12,
    "key": "censor",
    "label": "Người kiểm duyệt",
    "type": "select"
  },
];


final List<Map<String, dynamic>> listBanking = [
  {
    "id": 6,
    "name": "Ngân hàng TMCP Kỹ thương Việt Nam",
    "code": "TCB",
    "logo": "assets/images/logobank/techcombank.png",
    "short_name": "Techcombank",
    "bin": "970407",
    "swift_code": "VTCBVNVX",
    "bank_type": "personal",
    "color_card": 0xffda251c,
    "is_verified": true
  },{
    "id": 10,
    "name": "Ngân hàng TMCP Quốc tế Việt Nam",
    "code": "VIB",
    "logo": "assets/images/logobank/vib.jpg",
    "short_name": "VIB",
    "bin": "970441",
    "swift_code": "VNIBVNVX",
    "bank_type": "personal",
    "color_card": 0xff0066b3,
    "is_verified": true
  },{
    "id": 5,
    "name": "Ngân hàng TMCP Quân đội",
    "code": "MB",
    "logo": "assets/images/logobank/mbbank.png",
    "short_name": "MBBank",
    "bin": "970422",
    "swift_code": "MSCBVNVX",
    "bank_type": "personal",
    "color_card": 0xff000fd0,
    "is_verified": true
  },{
    "id": 1,
    "name": "Ngân hàng TMCP Công thương Việt Nam",
    "code": "ICB",
    "logo": "assets/images/logobank/viettin.png",
    "short_name": "VietinBank",
    "bin": "970415",
    "swift_code": "ICBVVNVX",
    "bank_type": "personal",
    "color_card": 0xff004f7e,
    "is_verified": false
  },{
    "id": 2,
    "name": "Ngân hàng TMCP Ngoại Thương Việt Nam",
    "code": "VCB",
    "logo": "assets/images/logobank/vietcombank.png",
    "short_name": "Vietcombank",
    "bin": "970436",
    "swift_code": "BFTVVNVX",
    "bank_type": "personal",
    "color_card": 0xff073c28,
    "is_verified": false
  },{
    "id": 3,
    "name": "Ngân hàng TMCP Đầu tư và Phát triển Việt Nam",
    "code": "BIDV",
    "logo": "assets/images/logobank/bidv.png",
    "short_name": "BIDV",
    "bin": "970418",
    "swift_code": "BIDVVNVX",
    "bank_type": "personal",
    "color_card": 0xff213e99,
    "is_verified": false
  },{
    "id": 4,
    "name": "Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam",
    "code": "VBA",
    "logo": "assets/images/logobank/agribank.png",
    "short_name": "Agribank",
    "bin": "970405",
    "swift_code": "VBAAVNVX",
    "bank_type": "personal",
    "color_card": 0xffae1c3f,
    "is_verified": false
  },{
    "id": 7,
    "name": "Ngân hàng TMCP Á Châu",
    "code": "ACB",
    "logo": "assets/images/logobank/acb.png",
    "short_name": "ACB",
    "bin": "970416",
    "swift_code": "ASCBVNVX",
    "bank_type": "personal",
    "color_card": 0xff002496,
    "is_verified": false
  },{
    "id": 8,
    "name": "Ngân hàng TMCP Việt Nam Thịnh Vượng",
    "code": "VPB",
    "logo": "assets/images/logobank/vpbank.png",
    "short_name": "VPBank",
    "bin": "970432",
    "swift_code": "VPBKVNVX",
    "bank_type": "personal",
    "color_card": 0xff008446,
    "is_verified": false
  },{
    "id": 9,
    "name": "Ngân hàng TMCP Tiên Phong",
    "code": "TPB",
    "logo": "assets/images/logobank/tpbank.png",
    "short_name": "TPBank",
    "bin": "970423",
    "swift_code": "TPBVVNVX",
    "bank_type": "personal",
    "color_card": 0xff4a1860,
    "is_verified": false
  },{
    "id": 11,
    "name": "Ngân hàng TMCP Xuất Nhập khẩu Việt Nam",
    "code": "EIB",
    "logo": "assets/images/logobank/eximbank.png",
    "short_name": "Eximbank",
    "bin": "970431",
    "swift_code": "EBVIVNVX",
    "bank_type": "personal",
    "color_card": 0xff019ddc,
    "is_verified": false
  },{
    "id": 12,
    "name": "Ngân hàng TMCP Kỹ thương Việt Nam",
    "code": "TCB",
    "logo": "assets/images/logobank/techcombank.png",
    "short_name": "Techcombank",
    "bin": "970407",
    "swift_code": "VTCBVNVX",
    "bank_type": "enterprise",
    "color_card": 0xffda251c,
    "is_verified": false
  },
];