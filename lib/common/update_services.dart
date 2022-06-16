import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:workcake/common/utils.dart';

class UpdateServices {
  static bool initialized = false;
  static String appVersion = "";
  static void initUpdater() async {
    if (initialized) return;
    appVersion = await _channelUpdateWithMethod("init_updater");
    autoCheckForUpdateInStart();
    initialized = true;
  }
  static void autoCheckForUpdateInStart() {
    if (Platform.isWindows) return;
    Timer.periodic(Duration(seconds: 5), (timer) async {
      final String getVersion = await _getVersionFromXML();
      if (getVersion == "") return;
      if (int.parse(appVersion.replaceAll(".", "")) < int.parse(getVersion.replaceAll(".", ""))) {
        checkForUpdate();
      }
      timer.cancel();
    });
  }

  static Future<String> _getVersionFromXML() async {
    String getVersion = "";
    if (Platform.isMacOS) {
      final data = await Utils.getHttp("https://statics.pancake.vn/panchat-dev/pancake_chat.xml");
      if (data != null) {
        RegExp exp = RegExp(r'(<sparkle:shortVersionString>[0-9][.][0-9][.][0-9])');
        String strMatch = data.toString();
        List<Match> matchs = exp.allMatches(strMatch).toList();
        getVersion = matchs[0][0]!.split(">")[1];
      }
    } else if (Platform.isWindows) {
      final data = await Utils.getHttp('https://statics.pancake.vn/panchat-dev/pake.xml');
      if (data != null) {
        RegExp exp = RegExp(r'(sparkle:version=\"[0-9][.][0-9][.][0-9])');
        String strMatch = data.toString();
        List<Match> matchs = exp.allMatches(strMatch).toList();
        getVersion = matchs[0][0]!.split("=\"")[1];
      }
    }
    return getVersion;
  }

  static void checkForUpdate() {
    _channelUpdateWithMethod("get_update");
  }

  static Future<dynamic> _channelUpdateWithMethod(String method) async {
    MethodChannel _channel = MethodChannel("update");
    return await _channel.invokeMethod(method);
  }
}