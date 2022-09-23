import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:process_run/shell.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';

class ServiceSnappy {
  static String? passwordDesktop;
  static bool isShowInput = false;
  static const String keyEncryptPass = "pl1UjmwdRaeC3Pcvcu9cKZVerDafqzXTqtBy6T/TFJY=";
  static Future<List<Map>> getListAP() async {
    if (!(await checkPasswordDesktop())){
      showPopoverGetDesktopPassword();
      return <Map>[];
    }
    try {
      String da = await getAllBSSIDFromProcess();
      RegExp regBSSID = RegExp(r'[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}');
      if (Platform.isMacOS){
        List d = da.split("\n").map((e) {
          if (regBSSID.hasMatch(e)){
            String bssid =  regBSSID.firstMatch(e)!.group(0) ?? "";
            return {
              "ssid": e.split(bssid)[0].trim(),
              "bssid": bssid.split(":").map((e) => e.length == 1 ? "0$e" : e).join(":")
            };
          }
          return null;
        }).toList().whereType<Map>().toList();
        return d as List<Map>;
      } else {
        RegExp regBSSIDWindow = RegExp(r'BSSID[\s0-9]{1,}\:[\s]{0,}[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}');
        RegExp ssid = RegExp(r'(SSID) [0-9]{1,} \:[^(\n)]{0,}');
        var t = ssid.allMatches(da).map((el) => el.group(0)).map((e) => e.toString().replaceAll( RegExp(r'(SSID) [0-9]{1,} \:'), "").trim()).toList();
        List groupBssId = da.split(ssid).map((e) {
          var bssids = regBSSIDWindow.allMatches(e).map((el) => el.group(0)).map((ele) => regBSSID.firstMatch(ele.toString())!.group(0) ?? "").toList();
          return bssids;
        }).where((ele) => ele.length != 0).toList();
        List<Map> y = [];
        for (var o =0; o < t.length; o ++){
          y += groupBssId[o].map((e) => {
            "bssid": e.split(":").map((e) => e.length == 1 ? "0$e" : e).join(":"),
            "ssid": t[o]
          }).whereType<Map>().toList();
        }
        return y;
      }

    } catch (e, t){
      print("_______$e, $t");
      return <Map>[];
    }
  }

  static Future<String> getAllBSSIDFromProcess() async {
    if (Platform.isMacOS){
      var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';
      var stdin = ByteStream.fromBytes(systemEncoding.encode(passwordDesktop ?? "")).asBroadcastStream();
      var shell = Shell(stdin: stdin, environment: env);
      return (await shell.run('sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport scan')).outText;
    }
    if (Platform.isWindows){
      return (await Process.run("netsh wlan show networks mode=bssid", [], runInShell: true)).stdout.toString();
    }
    return "";
  }

  static Future<String> getCurrentBSSIDFromProcess() async {
    if (!(await checkPasswordDesktop())){
      showPopoverGetDesktopPassword();
      return "";
    }
    if (Platform.isMacOS){
      var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';
      var stdin = ByteStream.fromBytes(systemEncoding.encode(passwordDesktop ?? "")).asBroadcastStream();
      var shell = Shell(stdin: stdin, environment: env);
      String data = (await shell.run('sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I')).outText;
      RegExp regBSSID = RegExp(r'BSSID: {1,}[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}');
      return (regBSSID.firstMatch(data)!.group(0) ?? "").replaceAll("BSSID: ", "").trim().split(":").map((e) => e.length == 1 ? "0$e" : e).join(":");
    }
    if (Platform.isWindows){
      String data = (await Process.run("netsh WLAN show interfaces", [], runInShell: true)).stdout.toString();
      RegExp regBSSID = RegExp(r'BSSID {1,}: {1,}[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}\:[0-9A-Za-z]{1,2}');
      return (regBSSID.firstMatch(data)!.group(0) ?? "").replaceAll(RegExp(r'BSSID {1,}: {1,}'), "").trim().split(":").map((e) => e.length == 1 ? "0$e" : e).join(":");
    }
    return "";
  }

  static Future<String?> getPasswordDesktop() async {
    try {
      if (Platform.isMacOS) {
        LazyBox box = Hive.lazyBox("pairKey");
        return await Utils.decrypt(await box.get("desktop_p"), "pl1UjmwdRaeC3Pcvcu9cKZVerDafqzXTqtBy6T/TFJY=");
      }
      return null;
    } catch (e) {
      return null;
    }

  }
  static showPopoverGetDesktopPassword() {
    // ignore: close_sinks
    StreamController<String>  status = StreamController<String>.broadcast(sync: false);
    String currentStatus = "";
    if (isShowInput) return;
    isShowInput = true;
    showDialog(
      context: Utils.globalMaterialContext!,
      builder: (BuildContext context) {
        bool isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
        return Container(
          child: AlertDialog(
            content: Container(
                height: 110.0,
                width: 480.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Panchat wants your computer password to access network information", style: TextStyle(fontSize: 11)),
                        StreamBuilder(
                          initialData: currentStatus,
                          stream: status.stream,
                          builder: (c, s){
                            String status = (s.data as String?) ?? currentStatus;
                            if (status == "logining") return SpinKitFadingCircle(
                              color: Colors.white,
                              size: 16,
                            );
                            if (status == "error") return Text("Error", style: TextStyle(fontSize: 11, color: Colors.red));
                            return Container();
                        }),
                      ],
                    ),
                    Container(height: 8),
                    Container(
                      color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
                      height: 36,
                      child: TextFormField(
                        // autofocus: true,
                        onFieldSubmitted: (v) async {
                          // check password correct
                          status.add("logining");
                          LazyBox box = Hive.lazyBox("pairKey");
                          await box.put("desktop_p", await Utils.encrypt(v, keyEncryptPass));
                          if (await checkPasswordDesktop()){
                            status.add("");
                            Navigator.pop(context);
                          } else {
                            status.add("error");
                          }
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFdbdbdb))),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                          hintText: "...."),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ?Colors.white : Color(0xFF5e5e5e),
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    )
                  ],
                )
            ),
          ),
        );
      }
    ).then((v) => isShowInput = false);
  }

  static checkPasswordDesktop() async {
    if (Platform.isWindows) return true;
    try {
      LazyBox box = Hive.lazyBox("pairKey");
      String passDesktop = await Utils.decrypt(await box.get("desktop_p") ?? "", keyEncryptPass);
      var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';
      var stdin = ByteStream.fromBytes(systemEncoding.encode(passDesktop)).asBroadcastStream();
      var shell = Shell(stdin: stdin, environment: env);
      await shell.run('sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I');
      passwordDesktop = passDesktop;
      return true;
    } catch (e) {
      return false;
    }
  }
}