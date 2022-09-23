import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/E2EE/e2ee.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/services/sync_data.dart';

class DMInputShared extends StatefulWidget {
  final String type;

  DMInputShared({
    Key? key,
    required this.type
  }) : super(key: key);

  @override
  _DMInputShared createState() => _DMInputShared();
}

class _DMInputShared extends State<DMInputShared> {
  var code;
  var sec;
  int totalMessages = 0;
  int totalMessagesRecived = 0;
  String status = "waitting";
  List conversation = [];
  List<Map> conversationMessages = [];
  int indexFocus = 0;
  TextEditingController _input1 = new TextEditingController();
  TextEditingController _input2 = new TextEditingController();
  TextEditingController _input3 = new TextEditingController();
  TextEditingController _input4 = new TextEditingController();
  var channel;
  bool finishKey  =  false;
  bool finishMessage =  false;
  var _focusNode1;
  var _focusNode2;
  var _focusNode3;
  var _focusNode4;
  String flow = "";
  List input = [];

  @override
  void initState() {
    super.initState();
    channel = Provider.of<Auth>(context, listen: false).channel;

    input = [
      {"controller": _input1, "focusNode": _focusNode1},
      {"controller": _input2, "focusNode": _focusNode2},
      {"controller": _input3, "focusNode": _focusNode3},
      {"controller": _input4, "focusNode": _focusNode4},
    ];

    input = input.map((e) {
      int index = input.indexWhere((ele) => ele == e);
      e["focusNode"] = new FocusNode(onKey: (node, RawKeyEvent keyEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.backspace) && keyEvent is RawKeyDownEvent) {
          e["controller"].clear();
          if (index > 0) FocusScope.of(context).requestFocus(input[index - 1]["focusNode"]);
        }
        return KeyEventResult.ignored;
      });
      return e;
    }).toList();

    channel.on("result_sync_conversation", (data, _r, _j) async{
      try {
        var dataServer  = await Utils.decryptServer(data["data"]);
        if (dataServer["success"]){
          var dataEn =  dataServer["data"];
          if (dataEn["success"]){
            flow = dataEn["flow"];
            LazyBox box = Hive.lazyBox('pairKey');
            Box direct =  Hive.box("direct");
            var identityKey =  await box.get("identityKey");
            var iKey  = dataEn["public_key_decrypt"];
            var masterKey = await X25519().calculateSharedSecret(KeyP.fromBase64(identityKey["privKey"], false), KeyP.fromBase64(iKey, true));
            var messageDeStr =  Utils.decrypt(dataEn["data"], masterKey.toBase64());
            var dataToSave  = jsonDecode(messageDeStr);
            await box.putAll(dataToSave);
            if(dataEn["dataConv"] != null) {
              var messageDeStrConv =  Utils.decrypt(dataEn["dataConv"], masterKey.toBase64());
              var dataToSaveConv  = jsonDecode(messageDeStrConv);
              var dataConv = dataToSaveConv["conv"];
              List dConv = [];
              for(int i =0; i< dataConv.length; i++){
                DirectModel dm  = DirectModel(
                  dataConv[i]["id"],
                  [],
                  "",
                  false,
                  0,
                  dataConv[i]["snippet"] ?? {},
                  dataConv[i]["is_hide"] ?? false,
                  dataConv[i]["updateByMessageTime"] ?? 0,
                  dataConv[i]["userRead"] ?? {},
                  "",
                  null
                );
                dConv = dConv + [dm];
              }
              await direct.clear();
              await direct.addAll(dConv);
            }
            if (flow != "file") StreamSyncData.instance.setTotalMessage(dataEn["totalMessages"]);
            else MessageConversationServices.statusSyncController.add(StatusSync(0, "Waitting data"));
            final token = Provider.of<Auth>(context, listen: false).token;
            final userId = Provider.of<Auth>(context, listen: false).userId;
            await Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(token, userId);
            if (this.mounted) {
              setState(() {
                status = "done";
              });
            }
          }  else {
            if (this.mounted)
              setState(() {
                status = "error";
                code = "";
              });
          }
        } else {
          if (this.mounted)
            setState(() {
              status = "error";
              code = "";
            });
        }
     } catch (e) {
       print("_____________________________$e");
     }
    });

  }

  onChangedInput(value) {
    if (value == "Cancel") {
      _input1.clear();
      _input2.clear();
      _input3.clear();
      _input4.clear();
      Navigator.pop(context);
      return ;
    } else if (value == "del") {
      if (Utils.checkedTypeEmpty(_input4.text.trim())) indexFocus = 3;
      else if (Utils.checkedTypeEmpty(_input3.text.trim())) indexFocus = 2;
      else if (Utils.checkedTypeEmpty(_input2.text.trim())) indexFocus = 1;
      else if (Utils.checkedTypeEmpty(_input1.text.trim())) indexFocus = 0;
      if (Utils.checkedTypeEmpty(input[indexFocus]["controller"].text.trim())) {
        input[indexFocus]["controller"].text = "";
        FocusScope.of(context).requestFocus(input[indexFocus]["focusNode"]);
      }
      return ;
    }
    if (!Utils.checkedTypeEmpty(_input1.text.trim())) {
      FocusScope.of(context).requestFocus(_focusNode1);
      _input1.text = value.toString();
      indexFocus += 1;
    } else if (indexFocus > 0 && indexFocus <= 4 && Utils.checkedTypeEmpty(input[indexFocus - 1]["controller"].text.trim())
      && !Utils.checkedTypeEmpty(input[indexFocus]["controller"].text.trim())
    ) {
      FocusScope.of(context).requestFocus(input[indexFocus]["focusNode"]);
      input[indexFocus]["controller"].text = value.toString();
      indexFocus += 1;
      if (indexFocus == 4) {
        this.setState(() {
          code = _input1.text + _input2.text + _input3.text + _input4.text;
        });
        handleSubmitConfirm();
      }
    }
  }

  handleGenCode(){
    setState(() {
      code  = Utils.getRandomString(6);
    });
  }

  handleResutData(){
    Navigator.of(context, rootNavigator: true).pop("Discard");
  }

  handleSubmitConfirm()async {
    final channel = Provider.of<Auth>(context, listen: false).channel;

    LazyBox box  = Hive.lazyBox('pairKey');
    Map payload  = {"code": code, "deviceId": await box.get("deviceId")};

    channel.push(event: "confirm_code", payload: {
      "device_id": await box.get("deviceId"),
      "data": await Utils.encryptServer(payload)
    });
  }

  getBackgroundColor(){
    if (status == "success") return Color(0xFF73d13d);
    if (status == "error") return Color(0xFFff4d4f);
    return Color(0xFFffffff);
  }

  getTextColor(){
    if (status == "success") return Color(0xFFf6ffed);
    if (status == "error") return Color(0xFFfff1f0);
    return Color(0xFFffffff);
  }

  @override
  void dispose(){
    channel.off("result_sync_conversation");
    _input1.dispose();
    _input2.dispose();
    _input3.dispose();
    _input4.dispose();
    super.dispose();
  }

  sendOTPResetDeviceKey() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    try {
        final url = "${Utils.apiUrl}users/vertify_otp_device?token=$token&device_id=${await Utils.getDeviceId()}";
        var res = await Dio().post(url, data: {
        "data": await Utils.encryptServer({
          "otp_code": code,
        })
      });

      if (res.data["success"]){
        setState(() {
          status = "done";
        });
        Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(token, userId);
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      } else {
        setState(() {
          status = "error";
        });
      }
    } catch (e) {
      setState(() {
        status = "error";
      });
      print("____$e");

    }
  }

  String get3CharPhoneNumber(){
    try {
      final user = Provider.of<User>(context);
      String email = user.currentUser["email"] ?? "";
      if (user.currentUser["is_verified_email"]) return email.replaceFirstMapped(RegExp(r'[^@]{1,}@'), (map){
        return (map.group(0) ?? "").split("").map((e) => "*").join();
      });
      String phoneNumber = user.currentUser["phone_number"] ?? "";
      return "*******" + phoneNumber.substring(phoneNumber.length - 3, phoneNumber.length);
    } catch (e) {
      return "";
    }

  }

  @override
  Widget build(BuildContext context) {
    final isLogoutDevice = Provider.of<DirectMessage>(context, listen: true).isLogoutDevice;
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;
    if (isLogoutDevice) {
      Navigator.pop(context);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Color(0xff3D3D3D) : Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              border: isDark ? null : Border(bottom: BorderSide(color: Color(0xffC9C9C9))),
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(),
              child: Text("Reset device Key", style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D), height: 1.57,),)
            ),
          ),
          status == "done" ? Container(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/icons/CheckCircleGreen.svg"),
                  SizedBox(height: 16,),
                  Text(widget.type == "reset" ? " Reset successfully" : "Synchronize successfully", style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D), fontSize: 24, fontWeight: FontWeight.w500, height: 1.3),),
                  SizedBox(height: 20,),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Color(0xff27AE60),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 2),
                            color: Color.fromRGBO(0, 0, 0, 0.016)
                          )
                        ]
                      ),
                      child: Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),),
                    ),
                  )
                ],
              )
            ),
          ) : Column(
            children: [
              SizedBox(height: 72,),
              Center(child: Text("ENTER YOUR CODE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.3, color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D)),)),
              SizedBox(height: 4,),
              widget.type == "reset" ? Container(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text("An message has been send with a code to", style: TextStyle(
                      color: isDark ? Color(0xffA6A6A6) : Color(0xff5e5e5e),
                      height: 1.57,
                    )),
                    Text(get3CharPhoneNumber(), style: TextStyle(
                      color: isDark ? Color(0xffEDEDED) : Color(0xff2e2e2e),
                      height: 1.57,
                    )),
                    Text("to reset your device", style: TextStyle(
                      color: isDark ? Color(0xffA6A6A6) : Color(0xff5e5e5e),
                      height: 1.57,
                    ))
                  ],
                )
              ) : Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: 4),
                child: Text("Enter your code on other devices", style: TextStyle(
                  color: isDark ? Color(0xffA6A6A6) : Color(0xff5e5e5e),
                  height: 1.57,
                ))
              ),
              SizedBox(height: 32,),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: input.map<Widget>((e) {
                    int index = input.indexWhere((ele) => e == ele);
                    return Container(
                      margin: EdgeInsets.all(6),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        border: Border.all(color: status == "error" ? Color(0xffEB5757) :isDark ? Color(0XFF828282) : Color(0xffA6A6A6)),
                        color: status == "error" ? Color.fromRGBO(235, 87, 87, 0.1) : isDark ? Color(0xff2E2E2E) : Color(0xffF3F3F3),
                        borderRadius: BorderRadius.circular(2)
                      ),
                      child: TextField(
                        controller: e["controller"],
                        focusNode: e["focusNode"],
                        autofocus: index == 0,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (str) {
                          if (str.length > 1) {
                            e["controller"].text  = str[str.length - 1];
                            e["controller"].selection = TextSelection.fromPosition(TextPosition(offset: 1));
                          }
                          if (Utils.checkedTypeEmpty(str)) {
                            if (index < 3) FocusScope.of(context).requestFocus(input[index + 1]["focusNode"]);
                            else if (str.length > 0 && index == 3) {
                              this.setState(() {
                                code = _input1.text + _input2.text + _input3.text + _input4.text;
                                status = "syncing";
                              });
                              if (widget.type == "reset") return sendOTPResetDeviceKey();
                              return handleSubmitConfirm();
                            }
                          }
                        },
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none
                        ),
                      )
                    );
                  }).toList(),
                ),
              ),
              status  == "success" ? Container(
              width: 252,
              margin: EdgeInsets.only(bottom: 8, top: 24),
              child: Column(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(0xff27AE60),
                      borderRadius: BorderRadius.circular(2)
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.checkCircle, size: 18, color: Colors.white,),
                        SizedBox(width: 8,),
                        Text("Success", style: TextStyle(color: Colors.white, fontSize: 12))
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                  Text('Getting data $totalMessagesRecived / $totalMessages messages', style: TextStyle(color: Colors.white,)),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    height: conversationMessages.where((element) => element["currentCount"] != 0 && element["currentCount"] !=  element["totalMessage"]).toList().length * 35.0,
                    child: Column(
                      children: conversationMessages.where((element) => element["currentCount"] != 0 && element["currentCount"] <=  element["totalMessage"]).map((e) {
                        return Container(
                          margin: EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Text(e["name"] == null ? "___" : e["name"], style: TextStyle(fontSize: 10, color: Colors.white)),
                                  Text("$totalMessagesRecived / $totalMessages", style: TextStyle(fontSize: 10))
                                ],
                              ),
                              Container(height: 4,),
                              Container(
                                height: 8,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: LinearProgressIndicator(
                                    value: totalMessages == 0 ? 1 : totalMessagesRecived / totalMessages,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                                    backgroundColor: Color(0xffD6D6D6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            )  : Container(),
            ],
          ),
          status == "syncing" ? Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: SpinKitFadingCircle(size: 24, color: Utils.getPrimaryColor(),),
          ) : Container(),
          status == "error" ? Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 28),
            child: Text("Wrong code, please try again", style: TextStyle(color: Color(0xffED5757),))
          ) : SizedBox(),
        ],
      ),
    );
  }
}