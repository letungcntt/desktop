import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:workcake/E2EE/e2ee.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/models/models.dart';

class DMConfirmShared extends StatefulWidget {
  final deviceId;
  final data;

  DMConfirmShared({
    Key? key,
    @required this.deviceId,
    @required this.data,
  }) : super(key: key,);

  @override
  _DMConfirmShared createState() => _DMConfirmShared();
}

class _DMConfirmShared extends State<DMConfirmShared>  {

  var code;
  int currentStep = 0;
  String status = "waitting";
  var timer;
  int t =0;
  var channel;

  

  @override
  void initState() {
    super.initState();
    channel  =  Provider.of<Auth>(context, listen: false).channel;

    channel.on("handle_confirm_conversation_sync", (data, _r, _j)async {
      if (code == null) return;
      if (this.mounted)
        setState(() {
          status = "handle";
        });
      await Future.delayed(Duration(seconds: 1));
      var resultRecived;
      for (var i = 0; i< data["data"].length ; i++ ){
        var t =  await Utils.decryptServer(data["data"][i]);
        if (t["success"]){
          resultRecived = t["data"];
          break;
        }
      }
      LazyBox box = Hive.lazyBox('pairkey');
      var identityKey =  await box.get("identityKey");
      var publicKeyDecrypt = identityKey["pubKey"];
      var deviceId = await box.get("deviceId");
      var idKey =  resultRecived["id_public_key"];
      var masterKey =  await X25519().calculateSharedSecret(KeyP.fromBase64(identityKey["privKey"], false), KeyP.fromBase64(idKey, true));
      if (Utils.checkedTypeEmpty(resultRecived) && resultRecived["code"] == code && resultRecived["device_id"] == widget.deviceId){
        if (this.mounted)
          setState(() {
            currentStep = 1;
          });
        // xu ly data bao gom key + tin nhan + thong tin hoi thoai
        LazyBox box = Hive.lazyBox('pairkey');
        Box direct = await  Hive.openBox('direct');
        List keys  =  box.keys.toList();
        var result = {};
        for (var i = 0; i< keys.length; i++){
          if (keys[i] == "identityKey" || keys[i] == "deviceId") continue;
          result[keys[i]] = await box.get(keys[i]);
        }
        // ma hoa de may nhan dcgiai
        var dataDe = Utils.encrypt(jsonEncode(result), masterKey.toBase64());
        var resultConv = [];
        for(int i =0; i< direct.keys.length; i++ ){
          resultConv += [{
            "id": direct.values.toList()[i].id,
            "snippet": direct.values.toList()[i].snippet,
            "updateByMessageTime": direct.values.toList()[i].updateByMessageTime,
            "userRead": direct.values.toList()[i].userRead
          }];

        }
        var dataConv = Utils.encrypt(jsonEncode({"conv": resultConv}), masterKey.toBase64());
        var listConversations =  direct.values.toList();
        int totalMessage =  await MessageConversationServices.getTotalMessage();
        Map jsonDataResult  =  {
          "data": dataDe, 
          "dataConv": dataConv,
          "success": true, 
          "totalConversation": listConversations.length,
          "totalMessages": totalMessage,
          "public_key_decrypt": identityKey["pubKey"],
          "device_id": resultRecived["device_id"],
        };

        // ma hoa tin nhan khi gui len server
        var dataEn  = await Utils.encryptServer(jsonDataResult);

        // Utils.encrypt(str, masterKey)
        channel.push(event: "result_sync_conversation", payload: {"data": dataEn, "device_id_encrypt": await box.get("deviceId")});
        if (this.mounted)
          setState(() {
            status = "tran";
            timer.cancel();
          });
        var size  = 100;
        // truyen tin nhan, 100 tin moi lan chuyen
        int totalPage = (totalMessage / size).round() + 1;
        for (int i = 0; i <= totalPage; i++){
          List dataSource = await MessageConversationServices.getMessageToTranfer(limit: size, offset: i * size, parseJson: true);
          await pushData(dataSource, masterKey, deviceId, publicKeyDecrypt, channel);

        }
        if (this.mounted)
          setState(() {
            status = "done";
          });
        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context);
      }
      else {
          Map jsonDataResult  =  {
          "data": "", 
          "success": false, 
          "totalConversation": 0,
          "public_key_decrypt": identityKey["pubKey"],
          "device_id": resultRecived["device_id"],
        };

        // ma hoa tin nhan khi gui len server
        var dataEn  = await Utils.encryptServer(jsonDataResult);
        // Utils.encrypt(str, masterKey)
        channel.push(event: "result_sync_conversation", payload: {"data": dataEn, "device_id_encrypt": await box.get("deviceId")});
        if (this.mounted)
          setState(() {
            status = "fail";
            t = 0;
            code  = Utils.getRandomNumber(4);
          });
      }
      

    });
  }

  @override
  void dispose(){
    channel.off("handle_confirm_conversation_sync");
    super.dispose();
  }

  pushData(dataSource, masterKey, deviceId, publicKeyDecrypt, channel) async {

    Map dataToSend = {
      "data": dataSource,
    };
    // print("getNameOfConverastion(convId, listConversations)  ${getNameOfConverastion(convId, listConversations)}");
    // push via socket
    var messageDe = Utils.encrypt(jsonEncode(dataToSend), masterKey.toBase64());
    var messageDeToServer = await Utils.encryptServer({
      "data": messageDe,
      "public_key_decrypt": publicKeyDecrypt,
      "device_id": widget.deviceId,
    });
    channel.push(event: "send_data_sync", payload: {
      "data": messageDeToServer,
      "device_id_encrypt": deviceId
    });
  }


  Future getFromHive(idConversation,int page,int size)async {
    LazyBox thread =  await Hive.openLazyBox("thread_$idConversation");
    List keys = thread.keys.toList();
    List result  = [];
    for (var i = size * page ; i < min(keys.length, size * (page +1)); i++){
      if (keys[i] != null)
        result +=[await thread.get(keys[i])];
    }
    return result;
  }


  getNameOfConverastion(String convId, List sources){
    var index  =  sources.indexWhere((element) => element.id  == convId);
    if (index == -1) return "";
    return sources[index].name ?? sources[index].user.reduce((value, element) => "$value ${element["full_name"]}");
  }

  @override
  didChangeDependencies(){
    super.didChangeDependencies();    
  }

  handleGenCode(){
    if (this.mounted){
      setState(() {
        code  = Utils.getRandomNumber(4);
      });
      timer = Timer.periodic(new Duration(seconds: 1), (timer) { 
        if (this.mounted) 
        setState(() {
          t= t+1;
          if (t % 30 == 0) {
            code  = Utils.getRandomNumber(4);
            status = "waitting";
          }
        });
      });
    }
  }

  logoutDevice(String token)async{
    String url  = "${Utils.apiUrl}users/logout_device?token=$token";
    LazyBox box = Hive.lazyBox('pairkey');
    try{
      var res = await Dio().post(url, data: {
        "current_device": await box.get("deviceId"),
        "data": await Utils.encryptServer({"device_id": widget.deviceId})
      });
      Navigator.pop(context);
      if(res.data["success"] == false) throw HttpException(res.data["message"]);
    }catch(e){
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final token  =  Provider.of<Auth>(context, listen: false).token;
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;

    getStatus() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(right: 4, bottom: 2),
            child: Icon(
              status == "done"
                ? CupertinoIcons.checkmark_circle
                : status == "fail" ? CupertinoIcons.xmark_circle : CupertinoIcons.clock,
              color: status == "done" ? Color(0xff27AE60) : status == "fail" ? Colors.red : isDark ? Colors.white70 :Colors.grey[700],
              size: 20
            )
          ),
          Text(
              status == "waitting"
              ? "Waiting for verification..."
              :  status == "handle"
                ? "Data processing"
                : status == "done"
                  ? "Done"
                    : status == "tran"
                    ? "Data is being transmitted"
                      : status == "fail"
                      ? "Verification has failed" : "",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: status == "done" ? Color(0xff27AE60) : status == "fail" ? Colors.red : isDark ? Colors.white70 : Colors.grey[700]
            )
          )
        ],
      );
    }

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF323F4B) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                padding: EdgeInsets.only(left: 48, top: 12),
                width: 360, height: 180,
                child: Image.asset(
                  isDark ? "assets/images/sync_data_dark.png": "assets/images/sync_data_light.png",
                  width: 360, height: 200
                ),
              ),
              IconButton(
                iconSize: 20,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                padding: EdgeInsets.only(bottom: 150, left: 10),
                icon: Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey[400]),
                onPressed: () {
                  Navigator.pop(context);
                }
              )
            ],
          ),
          Utils.checkedTypeEmpty(code)
            ? Column(
              children: [
                Text(
                  code ?? "",
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  )
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Text(
                    "Auto refesh in ${(30 - t % 30)} second(s)",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      fontSize: 12
                    )
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: getStatus(),
                )
              ],
            )
            : Column(
              children: [
                Container(
                  padding: EdgeInsets.only(left: 28, right: 28),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "A new device ",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black,
                        fontSize: 12,
                        height: 1.5,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "(${widget.data["device_name"]}, ${widget.data["device_ip"]}, Hanoi)",
                          style: TextStyle(
                            fontWeight: FontWeight.w700
                          )
                        ),
                        TextSpan(
                          text: " just logged in and requested to sync data from this device.",
                        ),
                      ]
                    )
                  )
                ),
                Container(
                  padding: EdgeInsets.only(left: 12, right: 12),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "If you don't make that request, please choose ",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black,
                        fontSize: 12,
                        height: 2,
                      ),
                      children: [
                        TextSpan(
                          text: "Logout This Device",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700
                          )
                        )
                      ]
                    )
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    "Allow to sync from this device?",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w700,
                      height: 4,
                      color: isDark ? Colors.white70 : Colors.black
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: 114,
                        color: isDark ? Color(0xFF19DFCB) : Color(0xFF2A5298),
                        child: TextButton(
                          child: Text("Accept", style: TextStyle(
                            color: isDark ? Colors.black87 : Color(0xFFFFFFFF), fontWeight: FontWeight.w400)
                          ),
                          onPressed: () {
                            handleGenCode();
                          }
                        )
                      ),
                      Container(
                        width: 8
                      ),
                      Container(
                        width: 162,
                        color: Color(0xFFEB5757),
                        child: TextButton(
                          child: Text(
                            "Logout this device",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w400
                            ),
                          ),
                          onPressed:  () {
                            logoutDevice(token);
                          },
                        ),
                      ),
                      Container(
                        width: 8
                      ),
                      Container(
                        width: 122,
                        color: Colors.grey[400],
                        child: TextButton(
                          child: Text("Do not sync", style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w400)),
                          onPressed:  (){
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }
}