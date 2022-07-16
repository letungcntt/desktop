import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:better_selection/better_selection.dart';
import 'package:context_menus/context_menus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/draggable_scrollbar.dart';
import 'package:workcake/components/message_item/attachments/sticker_file.dart';
import 'package:workcake/components/message_item/chat_item_macOS.dart';
import 'package:workcake/components/message_item/record_audio.dart';
import 'package:workcake/components/typing.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/services/sharedprefsutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/workspaces/list_sticker.dart';

import '../components/file_items.dart';

class ConversationMacOS extends StatefulWidget {
  final id;
  final name;
  final itemFiles;

  ConversationMacOS({
    Key? key,
    @required this.id,
    @required this.name,
    this.itemFiles
  }) : super(key: key);

  @override
  _ConversationMacOSState createState() => _ConversationMacOSState();
}

class _ConversationMacOSState extends State<ConversationMacOS> {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  List suggestCommands = [];
  var controller = new ScrollController();
  var _controller = new ScrollController();
  List images = [];
  List fileItems = [];
  var textInput;
  var channel;
  bool isUpdate = false;
  var messageUpdate;
  bool isSendMessage = false;
  bool isCodeBlock = false;
  var commandSelected;
  bool isShowCommand = false;
  Timer? _debounce;
  String techAcc = '';
  String techPass = '';
  String techSTK = '';
  GlobalKey keyMessageToJump = GlobalKey();
  bool streamShowGoUpStatus = false;
  final streamShowGoUp = StreamController<bool>.broadcast(sync: false);
  bool isShowRecord = false;

  List? transfer;
  String? formToken;
  String? counter;
  String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
  Map<String, String>? headers;

  Future<String> getAcc() async {
    final accTech = sl.get<SharedPrefsUtil>().getTechcomAccount();
    return accTech;
  }

  Future<String> getPass() async {
    final passTech = sl.get<SharedPrefsUtil>().getTechcomPassword();
    return passTech;
  }

  Future<String> getSTK() async {
    final stkTech = sl.get<SharedPrefsUtil>().getTechcomSTK();
    return stkTech;
  }

  getTransaction() async {
    getAcc().then((value) {
      techAcc = value;
    });
    getPass().then((value) {
      techPass = value;
    });

    final String newApi = Utils.apiUrl + 'tcb/auth';
    final response  = await Dio().post(newApi, data: { "username": techAcc, "password": techPass })
      .then((res) async {
        final r = res.data;
        if (!r["success"]) {
          return {"success": false, "code": r["error"]["code"], "message": r["error"]["value"]};
        } else {
          final String newApiTransaction = Utils.apiUrl + 'tcb/get_transactions';
    
          var rp = await Dio().post(newApiTransaction, data: {
            "username": techAcc,
            "token": r["data"]["token"]
          });
          final rpData = rp.data;
          if (rpData["success"]) {
            final transactions = rpData["data"]["transactions"];

            List data = [];
            for (var i = 0; i < transactions.length; i++) {
              var row = new Map();
              row['id'] = transactions[i]["txnRef"];
              row['note'] = transactions[i]["txnDesc"];
              row['date'] = DateFormat("dd/MM/yyyy").format(DateTime.parse(transactions[i]["txnDate"]).add(const Duration(hours: 7)));
              row['amount'] = NumberFormat.simpleCurrency(locale: 'vi').format(transactions[i]["txnAmount"]);
              row['remain'] = NumberFormat.simpleCurrency(locale: 'vi').format(transactions[i]["balanceAfterTxn"]);
              data.add(row);
            }

            setState(() {
              transfer = data.reversed.toList();
            });
            return {"success": true, "data": data.reversed.toList()};
          } else {
            return {"success": false, "message": rpData["message"] || rpData["error"]};
          }
        }
      });
    
    if (response["success"]) {
      return {"success": true, "data": response["data"]};
    } else {
      return {"success": false, "message": response["message"]};
    }
  }

  sendRequestLogin() async {
    getSTK().then((value) {
      techSTK = value;
    });
    getAcc().then((value) {
      techAcc = value;
    });
    getPass().then((value) {
      techPass = value;
    });
    final url = Uri.parse('https://ib.techcombank.com.vn/servlet/BrowserServlet');

    try {
      final resp = await http.get(url);
      var document = parse(resp.body);
      List attributes = resp.headers["set-cookie"]!.split(";").where((e) => e != " Path=/").toList().join(",").split(",")
        .where((e) => e != " Domain=.techcombank.com.vn" && e != " Domain=.ib.techcombank.com.vn" && e != " path=/" && e != " Httponly" && e != " HttpOnly" && e != " Secure").toList()
        .reversed.toList();
      formToken = document.querySelector("input[name='formToken']")!.attributes["value"].toString();
      counter = document.querySelector("input[name='counter']")!.attributes["value"].toString();
      headers = {
        "Cookie": attributes.join("; "),
        "Accept": "*/*",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Origin": "https://ib.techcombank.com.vn",
        "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
      };
      String body =
        "formToken=$formToken&command=login&requestType=CREATE.SESSION&counter=$counter&branchAdminLogin=&signOnNameEnabled=Y&signOnName=$techAcc&password=$techPass&btn_login=%C4%90%C4%82NG+NH%E1%BA%ACP&MerchantId=&Amount=&Reference=&language=2&UserType=per";
      var response = await http.post(url, body: body, headers: headers);
      // /histories 19033587164015
      final doc = parse(response.body);
      final loginError = doc.querySelector("#lgn_error");
      if (loginError?.text != null) return {"success": false, "message": "Lỗi đăng nhập"};
      final params = doc.querySelector("td[height='100%']")!.attributes["fragmenturl"].toString();
      // print("xxx $functionCode");
      List fixed = params.split("&");
      final result = fixed.indexWhere((el) => el.startsWith("routineArgs"));
      fixed[result] = "routineArgs=COS%20AI.QCK.ACCOUNT";
      final newParams = fixed.join("&");

      final urlX = Uri.parse('https://ib.techcombank.com.vn/servlet/' + newParams);
      // print("urlX $urlX");
      var responseX = await http.get(urlX, headers: headers);
      final docX = parse(responseX.body);
      final mainBodyCode = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
          .map((el) => el.attributes["id"])
          .where((element) => element!.indexOf("MainBody") >= 0).toList();
      // print("yyy ${mainBodyCode[0].toString()}");
      final paramsX = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
          .map((el) => el.attributes["fragmenturl"])
          .where((element) => element!.indexOf("MainBody") >= 0).toList();
      final compScreen = paramsX[0].toString().split("&").where((el) => el.startsWith("compScreen")).toList()[0].toString();
      // print("compScreen ${x[1]}");
      // print("today $today");
      List fixedX = paramsX[0].toString().split("&");
      final resultX = fixedX.indexWhere((el) => el.startsWith("routineArgs"));
      fixedX[resultX] = "routineArgs=AI.QCK.TRANS.STMT.TCB";
      final newParamsX = fixedX.join("&");
      
      final urlY = Uri.parse('https://ib.techcombank.com.vn/servlet/' + newParamsX.toString());
      var responseY = await http.get(urlY, headers: headers);
      // print("urlY $urlY");
      // print(responseY.body);
      final paramsY = parse(responseY.body).querySelectorAll(".fragmentContainer.notPrintableFragment")
          .map((el) => el.attributes["id"])
          .where((e) => e != null)
          .where((element) => element!.indexOf("STMTSTEPTWO") >= 0).toList();
      final stmtsteptwoCode = paramsY[0].toString();
      final stringToday = DateFormat('yyyyMMdd').format(DateTime.now());
      final stringAgo = DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 90)));

      final bodyHistories =
          "formToken=$formToken&requestType=OFS.ENQUIRY&routineName=&routineArgs=ACCOUNT%20EQ%20$techSTK%20BOOKING.DATE%20RG%20'$stringAgo%20$stringToday'%20TXN.CNT%20EQ%2010&application=&ofsOperation=&ofsFunction=&ofsMessage=&version=&transactionId=&command=globusCommand&operation=&windowName=$mainBodyCode&apiArgument=&name=&enqname=AI.QCK.TRAN.SEARCH.STMT.TCB&enqaction=SELECTION&dropfield=&previousEnqs=&previousEnqTitles=&clientStyleSheet=&unlock=&allowResize=YES&companyId=VN0010001&company=BNK-TECHCOMBANK%20HOI%20SO&user=$techAcc&transSign=&skin=arc-ib&today=15%2F07%2F2021&release=R18&$compScreen&reqTabid=&compTargets=&EnqParentWindow=$stmtsteptwoCode&timing=356-3-3-350-1&pwprocessid=&language=VN&languages=GB%2CVN&savechanges=YES&staticId=&lockDateTime=&popupDropDown=true&allowcalendar=&allowdropdowns=&allowcontext=NO&nextStage=&maximize=true&showStatusInfo=NO&languageUndefined=Language%20Code%20Not%20Defined&expandMultiString=Expand%20Multi%20Value&deleteMultiString=Delete%20Value&expandSubString=Expand%20Sub%20Value&clientExpansion=true&WS_parentWindow=&WS_parent=&WS_dropfield=&WS_doResize=&WS_initState=ENQ%20AI.QCK.TRAN.SEARCH.STMT.TCB%20ACCOUNT%20EQ%20$techSTK%20BOOKING.DATE%20RG%20'$stringAgo%20$stringToday'%20TXN.CNT%20EQ%2010&WS_PauseTime=&WS_multiPane=false&WS_replaceAll=yes&WS_parentComposite=$mainBodyCode&WS_delMsgDisplayed=&WS_FragmentName=$mainBodyCode";
      try {
        var responseZ = await http.post(url, body: bodyHistories, headers: headers)
          .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                return http.Response('Error', 500);
              }
            );
        // Timeout
        if (responseZ.statusCode == 500) return getTransaction();
 
        final docZ = parse(responseZ.body);
        final message = docZ.querySelector("#message");
        // Tài khoản không tồn tại (E-113653)
        if(message?.text != null) return {"success": false, "message": "Tài khoản không tồn tại"};

        final List colour0 = docZ.querySelectorAll(".colour0").toList();
        final List colour1 = docZ.querySelectorAll(".colour1").toList();
        final List colour = (colour0 + colour1).toList();
        var data = [];
        for (var i = 0; i < colour.length; i++) {
          var columns = colour[i].querySelectorAll("td");
          var row = new Map();
          final List splitIdNote = (columns[1].text).toString().split(" / ");
          row['id'] = splitIdNote[1];
          row['note'] = splitIdNote[0];
          row['date'] = columns[0].text;
          row['amount'] = columns[2].text;
          row['remain'] = columns[3].text;
          data.add(row);
        }
        data.sort((el1, el2) {
          List dateString1 = el1["date"].split('/');
          List dateString2 = el2["date"].split('/');
          String newDate1 = "${dateString1[2]}-${dateString1[1]}-${dateString1[0]}";
          String newDate2 = "${dateString2[2]}-${dateString2[1]}-${dateString2[0]}";
          DateTime dtString1 = DateTime.parse(newDate1);
          DateTime dtString2 = DateTime.parse(newDate2);
          return dtString1.compareTo(dtString2);
        });
        setState(() {
          transfer = data;
        });
        return {"success": true, "data": data};
      } on TimeoutException catch (_) {
        return getTransaction();
      }
    } catch (e) {
      print(e);
      return getTransaction();
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }
  

  // ignore: close_sinks
  final stream =StreamController<List>.broadcast(sync: false);

  int count = 0;
  var currentScrollTime = "";
  var currentTimeMessageToJump = 0;


  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);
    Provider.of<Auth>(context, listen: false).getQueueMessages(widget.id);
    RawKeyboard.instance.addListener(handleKey);
    RawKeyboard.instance.addListener(keyboardListener);
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      setStreamShow(false);
      setState(() {
        fileItems = [];
        isUpdate = false;
        isShowRecord = false;
      });
      getLastEdited();
      Provider.of<Auth>(context, listen: false).getQueueMessages(widget.id);
      if (controller.hasClients) controller.jumpTo(_controller.position.maxScrollExtent);
    }
  }

  onChangeIsSendMessage(bool value) {
    isSendMessage = value;
  }

  setStreamShow(bool value){
    streamShowGoUpStatus = value;
    streamShowGoUp.add(streamShowGoUpStatus);
  }

  handleKey(RawKeyEvent keyEvent) {
    final isFocus = key.currentState?.focusNode.hasFocus ?? false;
    if(keyEvent is RawKeyDownEvent) {
      if(isFocus && key.currentState?.controller!.text == "") {
        if(keyEvent.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          final messagesData = Provider.of<Messages>(context, listen: false).data.where((element) => element["channelId"] == widget.id).toList();
          final currentUser = Provider.of<User>(context, listen: false).currentUser;
          final data = messagesData.isNotEmpty ? messagesData[0]["messages"] : [];
          final dataCurrentUser = data.where((ele) => ele["user_id"] == currentUser["id"]).toList();
          if (dataCurrentUser.length > 0) {
            final msg = dataCurrentUser.first;
            Map message = {
              "id": msg["id"],
              "message": msg["message"],
              "avatarUrl": msg["avatar_url"],
              "insertedAt": msg["inserted_at"],
              "fullName": msg["full_name"],
              "attachments": msg["attachments"],
              "isChannel": true,
              "userId": msg["user_id"],
              "channelId": msg["channel_id"],
              "workspaceId": msg["workspace_id"],
              "reactions": msg["reactions"],
              "lastEditedAt": msg["last_edited_at"],
              "isUnsent": msg["is_unsent"]
            };
            message["attachments"].indexWhere((e) => e["type"] == "bot");
            if (currentUser["id"] == message["userId"] && message["isChannel"]) updateMessage(message);
          }
        }
      }
    }

    return KeyEventResult.ignored;
  }

  processFiles(files, isSetstate) {
    List result = [];
    for(var i = 0; i < files.length; i++) {
      var file = files[i];
      var existed  =  (fileItems + result).indexWhere((element) => (element["path"] == files[i]["path"] && element['name'] == file['name']));
      if (existed != -1) continue;

      String type = Utils.getLanguageFile(file['mime_type'].toLowerCase());
      int index = Utils.languages.indexWhere((ele) => ele == type);

      try {
        if (index != -1 && file['preview'] == null) {
          String message = utf8.decode((file['file'] as List<int>));

          file = {
            ...files[i],
            'preview': message.length >= 1000 ? message.substring(0, 1000) + ' ...'  : message,
          };
        }
      } catch (err) {}

      result += [file];
    }

    if (isSetstate) {
      setState(() {
        fileItems += result;
      });
    } else {
      fileItems += result;
    }
    if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    StreamDropzone.instance.initDrop();
    onSaveAttachments();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    RawKeyboard.instance.removeListener(handleKey);
    RawKeyboard.instance.removeListener(keyboardListener);
    super.dispose();
  }

  getLastEdited() async {
    var box = await Hive.openBox('drafts');
    var lastEdited = box.get('lastEdited');
    var lastEditedFile = box.get('lastEditedFile');
    var openSetting = box.get('openSetting');

    if (openSetting != null) {
      if (openSetting) {
        Provider.of<Channels>(context, listen: false).openChannelSetting(true);
      }
    }

    if (lastEdited != null || lastEditedFile != null) {
      final index = (lastEdited ?? []).indexWhere((e) => e["id"] == widget.id);
      final indexAttachment = (lastEditedFile ?? []).indexWhere((e) => e["id"] == widget.id);

      if (index != -1 || indexAttachment != -1) {
        String text = '';
        List files = [];
        if (index != -1) {
          text = lastEdited[index]["text"];
        }

        if (indexAttachment != -1) {
          files = lastEditedFile[indexAttachment]["files"] ?? [];
        }

        if (mounted) {
          setState(() {
            if (key.currentState != null) {
              key.currentState!.setMarkUpText(text);
            }
            textInput = text;
            fileItems = files;
          });
        }
      }
    }
  }

  onSaveAttachments() async{
    var box = await Hive.openBox('drafts');
    var lastEditedFile = box.get('lastEditedFile');

    List changes;

    if (lastEditedFile == null) {
      changes = [{
        "id": widget.id,
        "files": fileItems,
      }];
    } else {
      changes = List.from(lastEditedFile);
      final index = changes.indexWhere((e) => e["id"] == widget.id);

      if (index != -1) {
        changes[index] = {
          "id": widget.id,
          "files": fileItems,
        };
      } else {
        changes.add({
          "id": widget.id,
          "files": fileItems,
        });
      }
    }

    box.put('lastEditedFile', changes);
  }

  saveChangesToHive(str) async {
    var box = await Hive.openBox('drafts');
    var lastEdited = box.get('lastEdited');
    List changes;

    if (lastEdited == null) {
      changes = [{
        "id": widget.id,
        "text": str,
      }];
    } else {
      changes = List.from(lastEdited);
      final index = changes.indexWhere((e) => e["id"] == widget.id);

      if (index != -1) {
        changes[index] = {
          "id": widget.id,
          "text": str,
        };
      } else {
        changes.add({
          "id": widget.id,
          "text": str,
        });
      }
    }

    box.put('lastEdited', changes);
  }

  handleMessage() {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    onChangeIsSendMessage(true);

    if (isShowCommand && commandSelected != null) {
      String stringCommand = "/" + commandSelected["short_cut"] + " ";
      key.currentState!.controller!.text = stringCommand;
      key.currentState!.controller!.selection = TextSelection.fromPosition(TextPosition(offset: key.currentState!.controller!.text.length));

      setState(() {
        suggestCommands = [];
        isShowCommand = false;
        commandSelected = null;
      });
    } else {
      if (!isUpdate) {
        _uploadImage(auth.token, currentWorkspace["id"]);
        if(isCodeBlock) handleCodeBlock(false);
      } else {
        _sendUpdateMessage(auth, currentWorkspace);
      }

      Timer(const Duration(microseconds: 100), () => {
        key.currentState!.controller!.clear(),
        saveChangesToHive('')
      });
    }
  }

  updateMessage(dataM) {
    final messageId = dataM["id"];
    final channelId = widget.id;

    List messagesData = Provider.of<Messages>(context, listen: false).data.where((element) => element["channelId"] == channelId).toList();
    List data = messagesData.isNotEmpty ? messagesData[0]["messages"] : [];

    if (data.isNotEmpty) {
      int indexMessage = data.indexWhere((e) => e["id"] == messageId);
      if (indexMessage != -1) {
        var dataM  = data[indexMessage];
        var message  = dataM["message"];
        var mentions  = dataM["attachments"] != null ?  dataM["attachments"].where((element) => element["type"] == "mention").toList() : [];
        var sendToChannelFromThread  = dataM["attachments"] != null ?  dataM["attachments"].where((element) => element["type"] == "send_to_channel_from_thread").toList() : [];
        if (mentions.length > 0){
          var mentionData =  mentions[0]["data"];
          message = "";
          for(var i= 0; i< mentionData.length ; i++){
            if (mentionData[i]["type"] == "text" ) {
              message += mentionData[i]["value"];
            } else {
              message += "=======${mentionData[i]["trigger"] ?? "@"}/${mentionData[i]["value"]}^^^^^${mentionData[i]["name"]}^^^^^${mentionData[i]["type"] ?? ((mentionData[i]["id"].length < 10) ? "all" : "user")}+++++++";
            }
          }
        }
        
        if (sendToChannelFromThread.length == 0) {
          // Tat ca file can hien thi
          var attOldMessage = dataM["attachments"] != null ? dataM["attachments"].where((ele) => ele["mime_type"] != "block_code" && ele["type"] != "mention").toList() : [];
          setState((){
            fileItems = attOldMessage;
          });
        }

        key.currentState!.focusNode.requestFocus();
        Future.delayed(const Duration(microseconds: 1), () => key.currentState!.setMarkUpText(message));
      }

      setUpdateMessage(dataM, true);
    }
  }

  handleMessageToAttachments(String message) {
    String name = Utils.suffixNameFile('message', fileItems);
    List<int> bytes = utf8.encode(message);
    processFiles([{
      "name": '$name.txt',
      "mime_type": 'txt',
      'type': 'txt',
      "path": '',
      "file": bytes
    }], true);
  }

  _sendUpdateMessage(auth, currentWorkspace) async{
    List files = fileItems;
    setState(() {
      fileItems = [];
    });
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText);
    var sendToChannelFromThread  = messageUpdate["attachments"] != null ?  messageUpdate["attachments"].where((element) => element["type"] == "send_to_channel_from_thread").toList() : [];
    var checkingShareMessage = files.where((element) => element["mime_type"] == "share").toList();

    var message  = {
      "channel_thread_id": null,
      "key": Utils.getRandomString(20),
      "message_id": messageUpdate["id"],
      "message": result["success"] ? "" : result["data"],
      "attachments": sendToChannelFromThread + (result["success"] ? ([] + [{"type": "mention", "data": result["data"] }]) : []) + checkingShareMessage,
      "channel_id":  widget.id,
      "workspace_id": currentWorkspace["id"],
      "user_id": messageUpdate["userId"],
      "is_system_message": false
    };
    Provider.of<Messages>(context, listen: false).newUpdateChannelMessage(auth.token, message, files);
    key.currentState!.controller!.clear();

    setUpdateMessage(null, false);
    onSaveAttachments();
  }

  setUpdateMessage(data, bool value) {
    setState(() {
      messageUpdate = data;
      isUpdate = value;
      if(!value) fileItems = [];
    });
  }

  checkCommand(value, context) {
    final currentCommand = Provider.of<Channels>(context, listen: false).currentCommand;
    final appInChannel = Provider.of<Channels>(context, listen: false).appInChannels;
    final isBanking = appInChannel.indexWhere((element) => element["app_name"] == "BizBanking") != -1;
    getSTK().then((value) {
      techSTK = value;
    });
    var lengthA = techAcc.length > 4 ? techAcc.length - 4 : 0;
    var newString = techAcc.substring(lengthA);
    var command = {
      "app_id": "1889cc30-53cb-4a98-8dba-ca33f8bed6ef",
      "command_id": "",
      "command_params": [{"key": "$techSTK"}],
      "description": "***$newString",
      "is_removed": false,
      "short_cut": "histories"
    };
    List newResult = !isBanking ? currentCommand : currentCommand + [command];

    // get list Commad short_cut
    if (value.length > 0 && value.substring(0,1) == "/") {
      var result  = newResult.where((element) {
        return element["short_cut"].contains("${value.substring(1)}");
      }).toList();
      if (result.length != suggestCommands.length) {
        setState(() {
          suggestCommands = result;
          commandSelected = result.isNotEmpty ? result[0] : null;
          isShowCommand = true;
        });
      }
    } else {
      if (suggestCommands.isNotEmpty) {
        setState(() {
          suggestCommands = [];
        });
      }
    }
  }

  handleCodeBlock(bool value) {
    setState(() {
      isCodeBlock = value;
    });
  }
  getSuggestionMentions() {
    final auth = Provider.of<Auth>(context, listen: false);
    List channelMembers = Provider.of<Channels>(context, listen: false).channelMember;
    List<Map<String, dynamic>> dataList = [{'id': "${widget.id}", 'display': 'all', 'full_name': 'all', 'photo': 'all', "type": "all"}];

    for (var i = 0 ; i < channelMembers.length; i++){
      Map<String, dynamic> item = {
        'id': channelMembers[i]["id"],
        'type': 'user',
        'display': Utils.getUserNickName(channelMembers[i]["id"]) ?? channelMembers[i]["full_name"],
        'full_name': Utils.checkedTypeEmpty(Utils.getUserNickName(channelMembers[i]["id"]))
            ? "${Utils.getUserNickName(channelMembers[i]["id"])} • ${channelMembers[i]["full_name"]}"
            : channelMembers[i]["full_name"],
        'photo': channelMembers[i]["avatar_url"]
      };

      if (auth.userId != channelMembers[i]["id"]) dataList += [item];
    }

    return channelMembers.isNotEmpty && channelMembers.length < 2 ? [] : dataList;
  }

  getSuggestionIssue() {
    List preloadIssues = Provider.of<Workspaces>(context, listen: false).preloadIssues;
    List dataList = [];

    for (var i = 0 ; i < preloadIssues.length; i++){
      Map<String, dynamic> item = {
        'id': "${preloadIssues[i]["id"]}-${preloadIssues[i]["workspace_id"]}-${preloadIssues[i]["channel_id"]}",
        'type': 'issue',
        'display': preloadIssues[i]["unique_id"].toString(),
        'title': preloadIssues[i]["title"],
        'channel_name': preloadIssues[i]["channel_name"],
        'is_closed': preloadIssues[i]["is_closed"]
      };

      dataList += [item];
    }

    return dataList;
  }

  _scrollListener() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    // final scrollDirection = controller.position.userScrollDirection;

    // if (scrollDirection != ScrollDirection.idle) {
    //   double newOffset = controller.offset + (scrollDirection == ScrollDirection.reverse ? 40 : -40);
    //   newOffset = min(controller.position.maxScrollExtent, max(controller.position.minScrollExtent, newOffset));
    //   // controller.jumpTo(newOffset);
    //   Timer(Duration(milliseconds: 0), () {
    //     controller.animateTo(
    //       newOffset,
    //       duration: Duration(milliseconds: 80), curve: Curves.ease
    //     );
    //   });
    // }

    if (controller.position.extentAfter < 10) {
      Provider.of<Messages>(context, listen: false).loadMoreMessages(token, currentWorkspace["id"], currentChannel["id"]);
    }
    if (controller.position.extentBefore > 2100 && !streamShowGoUpStatus && controller.position.userScrollDirection == ScrollDirection.reverse){
      setStreamShow(true);
    }
    if (controller.position.extentBefore < 2100 && streamShowGoUpStatus && (controller.position.userScrollDirection == ScrollDirection.forward || controller.position.userScrollDirection == ScrollDirection.idle)){
      int index = Provider.of<Messages>(context, listen: false).data.indexWhere((element) => element["channelId"] == currentChannel["id"]);
      if (streamShowGoUpStatus && index != -1){
        if (Provider.of<Messages>(context, listen: false).data[index]["disableLoadingUp"]) {
          setStreamShow(false);
        }
      }
    }
    if (controller.position.extentBefore < 10 && (controller.position.userScrollDirection == ScrollDirection.forward)){
      Provider.of<Messages>(context, listen: false).getMessageChannelUp(token, currentChannel["id"], currentWorkspace["id"], isNotifyListeners: true);
    }
  }

  keyboardListener(RawKeyEvent event) {
    final keyId = event.logicalKey.keyId;

    if (event is RawKeyDownEvent) {
      if ((event.isMetaPressed || event.isAltPressed || event.isControlPressed)) {
        if(keyId.clamp(32, 126) == keyId) {
          return KeyEventResult.handled;
        }
      } else if (mounted && keyId.clamp(32, 126) == keyId) {
        GlobalKey<ScaffoldState> keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
        final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
        if (!(FocusManager.instance.primaryFocus?.context?.widget is EditableText) && selectedTab == "channel" && keyScaffold.currentState != null && !keyScaffold.currentState!.isEndDrawerOpen && !Navigator.of(context).canPop() && mounted) {
          if (key.currentState!.isFocus) return KeyEventResult.ignored;
          bool openSearchbar = Provider.of<Windows>(context, listen: false).openSearchbar;
          // final openThread = Provider.of<Messages>(context, listen: false).openThread;
          final isFocusInputThread = Provider.of<Messages>(context, listen: false).isFocusInputThread;
          bool isOtherFocus = Provider.of<Windows>(context, listen: false).isOtherFocus;
          if (!openSearchbar && !isFocusInputThread && key.currentState!= null && key.currentState!.controller != null && !isOtherFocus) {
            FocusInputStream.instance.focusToMessage();
            key.currentState!.controller?.text = key.currentState!.controller!.text + event.character!;
          }
        }
      }
    }

    return KeyEventResult.ignored;
  }

  removeFile(index) {
    List list = fileItems;
    list.removeAt(index);
    setState(() {
      fileItems = list;
    });
    onSaveAttachments();
  }

  onChangedTypeFile(int index, String name, String type) {
    setState(() {
      fileItems[index]['mime_type'] = type;
      fileItems[index]['name'] = name + '.' + type;
    });
    key.currentState?.focusNode.requestFocus();
  }

  openFileSelector() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path ?? '')).toList();
      for(int i=0;i<files.length;i++) {
        String name = files[i].path.split('/').last;
        processFiles(files.map((element) {
          return {
            "name": name,
            "mime_type": name.split('.').last,
            "path": files[i].path,
            "file": files[i].readAsBytesSync()
          };
        }).toList(), true);
      }
    } else {
      // User canceled the picker
    }
  }

  selectEmoji(emoji) {
    key.currentState!.setMarkUpText((key.currentState?.controller?.markupText ?? '') + emoji.value);
    key.currentState!.focusNode.requestFocus();
  }

  onSelectCommand(commad, commandParams) {
    final String space = (commandParams != null && commandParams.length > 0) ? " " : "";
    key.currentState!.setMarkUpText(commad + space);
    key.currentState!.focusNode.requestFocus();
  }

  _uploadImage(token, workspaceId) async {
    var auth = Provider.of<Auth>(context, listen: false);
    var user = Provider.of<User>(context, listen: false);
    var message = key.currentState!.controller!.text.trim();
    var shortCut = message.split(" ")[0];
    if (message.startsWith("/") && !isCodeBlock) {
      final currentCommands = Provider.of<Channels>(context, listen: false).currentCommand;
      var lengthA = techAcc.length > 4 ? techAcc.length - 4 : 0;
      var newString = techAcc.substring(lengthA);
      var command = {
        "app_id": "1889cc30-53cb-4a98-8dba-ca33f8bed6ef",
        "command_id": "",
        "command_params": [{"key": "$techSTK"}],
        "description": "***$newString",
        "is_removed": false,
        "short_cut": "histories"
      };
      final appInChannel = Provider.of<Channels>(context, listen: false).appInChannels;
      final isBanking = appInChannel.indexWhere((element) => element["app_name"] == "BizBanking") != -1;
      List newResult = !isBanking ? currentCommands : currentCommands + [command];
      final currentCommand  = newResult.where((element) {
        return element["short_cut"] == shortCut.substring(1);
      }).toList();

      if (currentCommand.isNotEmpty) {
        var messages = message.split(" ");
        var listParams = [];

        for (int i = 1; i <= messages.length - 1; i++ ) {
          listParams.add(messages[i]);
        }

        var c = currentCommand[0];
        var newList = [];

        if (c["command_params"].length == listParams.length) {
          for (int i = 0; i <= listParams.length - 1; i++) {
            newList.add({c["command_params"][i]["key"]: listParams[i]});
          }
        }

        c["command"] = message;
        c["channel_id"] = widget.id;
        c["workspace_id"] = workspaceId;
        c["to_command_params"] = newList;
        var messageDummy = {
          "message": "",
          "attachments": [{
            "type": "bot", 
            "data": {...c, "command": message.replaceFirst("/", "")}, 
            "bot": {"id": c["app_id"], "name": c["app_name"]}
          }],
          "channel_id":  widget.id,
          "workspace_id": workspaceId,
          "key": Utils.getRandomString(20),
          "id": Utils.getRandomString(20),
          "user_id": auth.userId,
          "user": user.currentUser["full_name"] ?? "",
          "avatar_url": user.currentUser["avatar_url"] ?? "",
          "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
          "is_system_message": false
        };
        Provider.of<Messages>(context, listen: false).checkNewMessage(messageDummy);

        if (message.startsWith("/histories")) {
          Map transfer = await sendRequestLogin();
          if (transfer["success"]) {
            for (var i = 0; i < transfer['data'].length; i++) {
              c["transfer"] = transfer['data'][i];
              var dataMessage  = {
                "message": "",
                "attachments": [{"type": "BizBanking", "data": c }],
                "channel_id":  widget.id,
                "workspace_id": workspaceId,
                "key": Utils.getRandomString(20),
              };
              final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/${widget.id}/messages?token=$token';
              await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(dataMessage));
            }
          } else {
            c["transfer"] = transfer;
            var dataMessage  = {
              "message": "",
              "attachments": [{"type": "BizBanking", "data": c}],
              "channel_id":  widget.id,
              "workspace_id": workspaceId,
              "key": Utils.getRandomString(20),
            };
            final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/${widget.id}/messages?token=$token';
            await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(dataMessage));
          } 
          Provider.of<Messages>(context, listen: false).deleteMessage({...messageDummy, "message_id": messageDummy["id"]});
        } else {
          Provider.of<Messages>(context, listen: false).excuteCommand(token, workspaceId, widget.id, {...c, "key": messageDummy["key"]});
        }
        setState(() {
          suggestCommands = [];
        });
      }
    } else {
      List list = fileItems;
      setState(() {
        StreamDropzone.instance.initDrop();
        fileItems = [];
      });
      var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText.trim());
      var checkingBlockCode = Provider.of<Messages>(context, listen: false).regexMessageBlockCode(message);
      List data = [];
      var checkingShareMessage = list.where((element) => element["mime_type"] == "share").toList();

      if (isCodeBlock) {
        data = [{'type': 'block_code', 'value': key.currentState!.controller!.text.trimRight()}];
      } else if (result['success']) {
        for (int i=0; i<result["data"].length; i++) {
          if(result["data"][i]['type'] == 'text') {
            var blockCode = Provider.of<Messages>(context, listen: false).regexMessageBlockCode(result["data"][i]['value']);
            if (blockCode['success']) {
              data = blockCode['data'];
            } else {
              data.add(result["data"][i]);
            }
          } else {
            data.add(result["data"][i]);
          }
        }
      } else {
        if(checkingBlockCode['success']) data = checkingBlockCode['data'];
      }

      List attachments = [];
      if(result['success'] && checkingBlockCode['success']) {
        attachments = [{
          "type": "mention", "data": data.where((ele) => ele['type'] != 'block_code').toList()
        }, {
          "type": "block_code", "data": data.where((ele) => ele['type'] == 'block_code').toList()
        }];
      } else {
        if(result['success']) {
          attachments = [{
            "type": "mention", "data": data
          }];
        } else if (checkingBlockCode['success'] || isCodeBlock) {
          attachments = [{
            "type": "block_code", "data": data
          }];
        }
      }

      var dataMessage  = {
        "channel_thread_id": null,
        "key": Utils.getRandomString(20),
        "message": result["success"] || checkingBlockCode["success"]|| isCodeBlock ? "" : result["data"],
        "attachments": attachments + checkingShareMessage,
        "channel_id":  widget.id,
        "workspace_id": workspaceId,
        "count_child": 0,
        "user_id": auth.userId,
        "user":user.currentUser["full_name"] ?? "",
        "avatar_url": user.currentUser["avatar_url"] ?? "",
        "full_name": Utils.getUserNickName(auth.userId) ?? user.currentUser["full_name"] ?? "",
        "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
        "is_system_message": false,
        "isDesktop": true
      };
      key.currentState!.controller!.clear();
      handleCodeBlock(false);
      list.removeWhere((element) => element["mime_type"] == "share");

      if (Utils.checkedTypeEmpty(dataMessage["message"]) || dataMessage["attachments"].length > 0 || list.isNotEmpty) {
        Provider.of<Messages>(context, listen: false).sendMessageWithImage(list, dataMessage, token);
      }

      if (mounted) {
        setState(() {
          fileItems = [];
        });
      }
      onSaveAttachments();
    }
  }

  selectArrowCommand(value) {
    if (suggestCommands.isNotEmpty) {
      int index = suggestCommands.indexWhere((e) => e == commandSelected);
      var offset = _controller.offset;
      if (value == "up") {
        setState(() {
          commandSelected = index == 0 ? suggestCommands[0] : suggestCommands[index - 1];
          if (index >= 1) _controller.animateTo(offset - 42, duration: const Duration(milliseconds: 1), curve: Curves.ease);
        });
      } else {
        setState(() {
          commandSelected = index == suggestCommands.length - 1 ? suggestCommands[suggestCommands.length - 1] : suggestCommands[index + 1];
          if (index >= 4 && index <= suggestCommands.length - 1) _controller.animateTo(offset + 46, duration: const Duration(milliseconds: 1), curve: Curves.ease);
        });
      }
    }
  }

  jumpToContext(BuildContext? c, String idMessage){
    BuildContext? messageContext = c;
    if (messageContext == null) return;
    final renderObejctMessage = messageContext.findRenderObject() as RenderBox;
    try {
      var offsetGlobal = renderObejctMessage.localToGlobal(Offset.zero);
      // print("____ ${c!.widget.}_${renderObejctMessage.size}___${MediaQuery.of(c).size}");
      double height = 0.0;
      if (idMessage  == Provider.of<Messages>(context, listen: false).messageIdToJump) height = messageContext.size!.height;
      var scrolllOffset = controller.offset - offsetGlobal.dy + MediaQuery.of(context).size.height - 150 - height;
      controller.animateTo(scrolllOffset >= 0 ? scrolllOffset : 0, duration: const Duration(milliseconds: 100), curve: Curves.ease);
    } catch (e) {
      print(e);
    }
  }

  onFirstFrameMessageSelectedDone(BuildContext? cont, int? time, String? idMessage) {
    try {
      var idMessageToJump = Provider.of<Messages>(context, listen: false).messageIdToJump;
      if (cont == null || idMessageToJump == "" || idMessage == null) return;
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
      final messagesData = Provider.of<Messages>(context, listen: false).data.where((element) => element["channelId"] == currentChannel["id"]).toList();
      final data = messagesData.isNotEmpty ? messagesData[0]["messages"] : [];
      int index  = data.indexWhere((ele) => ele["id"] == idMessageToJump);
      if (index == -1 || time == null) return;
      int currentT = data[index]["current_time"];
      if (time >=currentT) jumpToContext(cont, idMessage);
      if (time == currentT) Provider.of<Messages>(context, listen: false).setMessageIdToJump("");

      // int CcurrentT = c.cu
    } catch (e) {

      print("PPPPPPP $e");
    }
  }

  onShareMessage(attachment) {
    List list = fileItems;
    final index = list.indexWhere((element) => element["mime_type"] == "share");
    if (index != -1) {
      list.replaceRange(index, index + 1, [attachment]);
    } else {
      list.add(attachment);
    }
    setState(() {
      fileItems = list;
    });
  }

  selectSticker(data) {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var dataMessage  = {
      "channel_thread_id": null,
      "key": Utils.getRandomString(20),
      "message": "",
      "attachments": [{
        'type': 'sticker',
        'data': data
      }],
      "channel_id":  widget.id,
      "workspace_id": currentWorkspace['id'],
      "count_child": 0,
      "user_id": auth.userId,
      "user":currentUser["full_name"] ?? "",
      "avatar_url": currentUser["avatar_url"] ?? "",
      "full_name": Utils.getUserNickName(auth.userId) ?? currentUser["full_name"] ?? "",
      "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "is_system_message": false,
      "isDesktop": true
    };

    Provider.of<Messages>(context, listen: false).sendMessageWithImage([], dataMessage, auth.token);
  }

  Widget _conversation(token, currentWorkspace, data, userId) {
    final auth = Provider.of<Auth>(context);
    var isDark = auth.theme == ThemeType.DARK;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final theme = Provider.of<Auth>(context, listen: true).theme;
    final messagesData = Provider.of<Messages>(context, listen: true).data.where((element) => element["channelId"] == currentChannel["id"]).toList();
    final data = messagesData.isNotEmpty ? messagesData[0]["messages"] : [];
    final locale = Provider.of<Auth>(context, listen: true).locale;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final messageIdToJump = Provider.of<Messages>(context, listen: true).messageIdToJump;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;

    bool isEndDrawerOpen = Scaffold.of(context).isEndDrawerOpen;

    return DropZone(
      shouldBlock: isEndDrawerOpen,
      stream: StreamDropzone.instance.dropped,
      builder: (context, files) {
        if(files.data != null && files.data.length > 0) processFiles(files.data ?? [], false);
        return Stack(
          children: [
            Column(
              children: <Widget>[
                (messagesData.isNotEmpty && messagesData[0]["isLoadingDown"] && data.length == 0) ? Expanded(
                  child: Center(
                    child: SpinKitFadingCircle(
                      color: isDark ? Colors.white60 : const Color(0xff096DD9),
                      size: 35,
                    ),
                  ),
                ) : RenderMessageByDay(
                  controller: controller, theme: theme, locale: locale, currentChannel: currentChannel, updateMessage: updateMessage, 
                  keyMessageToJump: keyMessageToJump, messageIdToJump: messageIdToJump,
                  onFirstFrameMessageSelectedDone: onFirstFrameMessageSelectedDone, onShareMessage: onShareMessage
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  margin: const EdgeInsets.only(top: 4),
                  child: (currentChannel["is_archived"] != null && currentChannel["is_archived"]) ? Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black, width: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        "You cannot send message on this channel because it has already been archived.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16)
                      )
                    )
                  ) : Column (
                    children:[
                      fileItems.isNotEmpty ? FileItems(files: fileItems, removeFile: removeFile, onChangedTypeFile: onChangedTypeFile) : Container(),
                      isShowRecord
                        ? RecordAudio(onExit: (value) => setState(() => isShowRecord = value))
                        : Container(
                            decoration: BoxDecoration(
                              color: isDark ? Palette.backgroundTheardDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isDark ? const Border() : Border.all(
                                color: const Color(0xffA6A6A6), width: 0.5
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FlutterMentions(
                                  afterFirstFrame: (){
                                    getLastEdited();
                                  },
                                  parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                                  cursorColor: theme == ThemeType.DARK ? Colors.grey[400]! : Colors.black87,
                                  key: key,
                                  autofocus: true,
                                  isIssues: false,
                                  id: widget.id.toString(),
                                  isDark: isDark,
                                  setUpdateMessage: setUpdateMessage,
                                  isUpdate: isUpdate,
                                  style: TextStyle(fontSize: 15.5, color: theme == ThemeType.DARK ? Colors.grey[300] : Colors.grey[800]),
                                  sendMessages: handleMessage,
                                  isCodeBlock: isCodeBlock,
                                  isShowCommand: isShowCommand,
                                  selectArrowCommand: selectArrowCommand,
                                  handleCodeBlock: handleCodeBlock,
                                  handleMessageToAttachments: handleMessageToAttachments,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(left: 5, bottom: 10, top: 18),
                                    hintText: !isUpdate ? !isCodeBlock ? "Type a message..." : "Block Code..." : "Editing this message...",
                                    hintStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5, height: 1)
                                  ),
                                  onChanged: (str) {
                                    saveChangesToHive(key.currentState!.controller!.markupText);
                                    checkCommand(str, context);
                                    setState(() {});
                                    if (str.trim() != "" && str != textInput) {
                                      
                                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                                      _debounce = Timer(const Duration(milliseconds: 500), () {
                                          auth.channel.push(
                                            event: "on_typing",
                                            payload: {"channel_id": currentChannel["id"], "workspace_id": currentWorkspace["id"], "user_name": currentUser["full_name"]}
                                          );
                                      });
                                    }
                                  },
                                  suggestionListHeight: 200,
                                  suggestionListDecoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  onSearchChanged: (trigger, value) { },
                                  mentions: [
                                    Mention(
                                      markupBuilder: (trigger, mention, value, type) {
                                        final name = Utils.getUserNickName(mention) ?? value;
                                        return "=======@/$mention^^^^^$name^^^^^$type+++++++";
                                      },
                                      trigger: '@',
                                      style: const TextStyle(color: Colors.lightBlue),
                                      data: getSuggestionMentions(),
                                      matchAll: true,
                                    ),
                                    Mention(
                                      markupBuilder: (trigger, mention, value, type) {
                                        return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                                      },
                                      trigger: "#",
                                      style: const TextStyle(color: Colors.lightBlue),
                                      data: getSuggestionIssue(),
                                      matchAll: true
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InputLeading(
                                      openFileSelector: openFileSelector,
                                      selectEmoji: selectEmoji,
                                      showRecordMessage: (value) => setState(() => isShowRecord = value),
                                      selectSticker: selectSticker
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isUpdate ? Icons.check : Icons.send,
                                        color: ((key.currentState?.controller!.markupText != "" ) || (fileItems.isNotEmpty))
                                          ? const Color(0xffFAAD14)
                                          : isDark ? const Color(0xff9AA5B1) : const Color(0xff616E7C),
                                        size: 18
                                      ),
                                      onPressed: () => ((key.currentState?.controller!.markupText != "" ) || (fileItems.isNotEmpty)) ? handleMessage() : null,
                                    ),
                                  ],
                                )
                              ],
                            )
                          ),
                      TypingDesktop(id: widget.id)
                    ]
                  )
                ),
                (data.length > 0 && currentScrollTime != "") ? Positioned(
                  top: 20, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff1F2933) : Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(color: isDark ? const Color(0xff52606D) : const Color(0xffE4E7EB)),
                      ),
                      child: Text(currentScrollTime, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.65), fontSize: 12.5)),
                    ),
                  ),
                ) : const SizedBox(),
              ]
            ),

            AnimatedPositioned(
              bottom: 105,
              left: 15,
              right: 0,
              height: suggestCommands.length < 5 ? suggestCommands.length * 43.0 : 214.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: isDark ? const Color(0xff2f3136) : const Color(0xFFf0f0f0),
                    boxShadow: suggestCommands.isNotEmpty ? 
                    [
                      BoxShadow(
                        color: isDark  ? const Color(0xFF262626).withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3), // changes position of shadow
                      ),
                    ] : [],
                ),
                child: ListView(
                  controller: _controller,
                  shrinkWrap: true,
                  children: [
                    Column(
                      children: suggestCommands.map<Widget>((command) {
                        var string = command["command_params"] != null ? command["command_params"].map((e) {
                          return "[${e["key"]}]";
                        }) : [];
                        var commandParams = command["command_params"];

                        return Container(
                          decoration: command["command_id"] == commandSelected["command_id"] ? BoxDecoration(
                            color: Colors.grey[300]
                          ) : BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[500]!, width: 0.2),
                              top: BorderSide(color: Colors.grey[500]!, width: 0.2)
                            )
                          ),
                          child: Container(
                            height: 50,
                            child: TextButton(
                              onPressed: (){
                                onSelectCommand("/" + command["short_cut"], commandParams);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft, 
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "/${command["short_cut"] ?? ""} ",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${string.join(" ")}",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF8C8C8C),
                                            fontWeight: FontWeight.w300,
                                            fontSize: 12
                                          )
                                        )
                                      ],
                                    ),
                                  ),
                                  command["description"] != null ? Container(
                                    padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
                                    child: Text(
                                      command["description"],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF8C8C8C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300
                                      ),
                                    )
                                  ) : Container()
                                ],
                              ),
                            ),
                          )
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            ),
            messagesData.isNotEmpty && (messagesData[0]["numberNewMessages"] ?? 0) > 0 ?
              Positioned(
                bottom: 100,
                height: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: HoverItem(
                    child: GestureDetector(
                      onTap: (){
                        Provider.of<Messages>(context, listen: false).resetOneChannelMessage(currentChannel["id"]);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme == ThemeType.DARK ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          border: Border.all(color: const Color(0xFFbfbfbf), width: 1),
                        ),
                        child: Text(
                          "${messagesData[0]["numberNewMessages"]} new messages",
                          style: TextStyle(fontSize: 12, color: theme == ThemeType.DARK ? Colors.white70 : const Color(0xFF6a6e74)),
                        ),
                      ),
                    ),
                  ),
                ),
              ) 
            : Container(),
            StreamBuilder(
              stream: streamShowGoUp.stream,
              initialData: false,
              builder: (context, snapshot) {
                bool isShow = (snapshot.data as bool?) ?? false;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: isShow ? 10 : -50, left: 0, right: 0,
                  child: Center(
                    child: HoverItem(
                      // colorHover: Colors.pink,
                      child: InkWell(
                        onTap: () {
                          setStreamShow(false);
                          Provider.of<Messages>(context, listen: false).resetOneChannelMessage(currentChannel["id"]);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: !isDark ? const Color(0xFFbfbfbf) : const Color(0xff262626)
                          ),
                          child: const Icon(PhosphorIcons.arrowDown, size: 20)),
                      ),
                    ),
                  ),
                );
              }
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context).token;
    final userId = Provider.of<Auth>(context).userId;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final messagesData = Provider.of<Messages>(context, listen: false).data.where((element) => element["channelId"] == currentChannel["id"]).toList();
    final data = messagesData.isNotEmpty ? messagesData[0]["messages"] : [];
    try {
      if (!messagesData[0]["disableLoadingUp"]) setStreamShow(true);
      if (messagesData[0]["disableLoadingUp"] && controller.position.extentBefore < 10) setStreamShow(false);      
    } catch (e) {
    }

    return Row(
      children: [
        LayoutBuilder(
          builder: (context, cts) {
             if ((data.length) * 15 < cts.maxHeight) {
              Provider.of<Messages>(context, listen: false).loadMoreMessages(token, currentWorkspace["id"], currentChannel["id"], isNotifi: false);
            }
            return Container(
              width: 0,
              color: Colors.red,
            );
          }
        ),
        Expanded(child: _conversation(token, currentWorkspace, data, userId))
      ],
    );
  }
}

class InputLeading extends StatefulWidget {
  const InputLeading({
    Key? key,
    required this.openFileSelector,
    this.showRecordMessage,
    this.selectEmoji,
    this.selectSticker
  }) : super(key: key);

  final openFileSelector;
  final selectEmoji;
  final showRecordMessage;
  final selectSticker;

  @override
  State<InputLeading> createState() => _InputLeadingState();
}

class _InputLeadingState extends State<InputLeading> {
  List options = [{'id': 0, 'title': ''}];
  String title = "";
  JustTheController controller = JustTheController(value: TooltipStatus.isHidden);
  List stickers = ducks + pepeStickers + otherSticker;

  createPollMessage() {
    final auth = Provider.of<Auth>(context, listen: false);
    final user = Provider.of<User>(context, listen: false);
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    

    List attachments = [{
      'type': 'poll',
      'title': title,
      'options': options,
      'results': []
    }];

    var dataMessage  = {
      "channel_thread_id": null,
      "key": Utils.getRandomString(20),
      "message": "",
      "attachments": attachments,
      "channel_id":  currentChannel["id"],
      "workspace_id": currentWorkspace["id"],
      "count_child": 0,
      "user_id": auth.userId,
      "user": user.currentUser["full_name"] ?? "",
      "avatar_url": user.currentUser["avatar_url"] ?? "",
      "full_name": user.currentUser["full_name"] ?? "",
      "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "is_system_message": true,
      "isDesktop": true
    };

    Provider.of<Messages>(context, listen: false).sendMessageWithImage([], dataMessage, auth.token);
    Navigator.pop(context);
  }

  int generateOptionID(){
    int newID = 0;
    List listID = options.map((e) => e["id"]).toList(); 
    while(listID.contains(newID)){
      newID += 1;
    }
    return newID;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    var isDark = auth.theme == ThemeType.DARK;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(left: 5),
          child: TextButton(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
              overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
            ),
            child: Icon(CupertinoIcons.plus, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
            onPressed: () {
              widget.openFileSelector();
            }
          )
        ),
        const SizedBox(width: 4),
        Container(
          width: 30,
          height: 30,
          child: HoverItem(
            colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
              ),
              child: Icon(Icons.poll, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 20),
              onPressed: () {
                createPollDialog(context, isDark).then((value) {
                  options = [{'id': 0, 'title': ''}];
                  title = "";
                });
              }
            ),
          )
        ),
        const SizedBox(width: 4),
        if (Platform.isMacOS) Container(
          width: 30,
          height: 30,
          child: HoverItem(
            colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
              ),
              child: Icon(CupertinoIcons.mic, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
              onPressed: () {
                widget.showRecordMessage(true);
              }
            ),
          )
        ),
        JustTheTooltip(
          controller: controller,
          preferredDirection: AxisDirection.up,
          isModal: true,
          content: Emoji(
            workspaceId: currentWorkspace["id"],
            onSelect: (emoji){
              widget.selectEmoji(emoji);
              
            },
            onClose: (){
              // Navigator.pop(context);
              controller.hideTooltip();
            }
          ),
          child: Container(
            width: 30,
            height: 30,
            child: HoverItem(
              colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
              child: TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                ),
                child: Icon(CupertinoIcons.smiley, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                onPressed: () {
                  controller.showTooltip();
                  // showPopover(
                  //   context: context,
                  //   direction: PopoverDirection.top,
                  //   transitionDuration: const Duration(milliseconds: 0),
                  //   arrowWidth: 0, 
                  //   arrowHeight: 0,
                  //   arrowDxOffset: 0,
                  //   shadow: [],
                  //   onPop: (){
                  //   },
                  //   bodyBuilder: (context) => 
                  // );
                }
              ),
            )
          ),
        ),
        ContextMenu(
          contextMenu: Container(
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75)),
              borderRadius: BorderRadius.all(Radius.circular(8))
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75))
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Sticker',
                          style: TextStyle(
                            color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                            fontWeight: FontWeight.w500, fontSize: 16
                          ),
                        )
                      ),
                      InkWell(
                        child: Icon(
                          PhosphorIcons.xCircle,
                        size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                        ),
                        onTap: () => context.contextMenuOverlay.close(),
                      ),
                    ],
                  )
                ),
                SingleChildScrollView(
                  child: Container(
                    width: 300, height: 400,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 100,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: stickers.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 80, height: 80,
                          child: TextButton(
                            onPressed: () {
                              widget.selectSticker(stickers[index]);
                              context.contextMenuOverlay.close();
                            },
                            child: StickerFile(data: stickers[index], isPreview: true)
                          )
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            width: 30,
            height: 30,
            child: HoverItem(
              colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
              child: Icon(PhosphorIcons.sticker, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
            )
          ),
        )
      ]
    );
  }

  Future<dynamic> createPollDialog(BuildContext context, bool isDark) {
    TextEditingController _titleController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: isDark ? Palette.borderSideColorDark : const Color(0xfff3f3f3),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Container(
                width: 468,
                child: Wrap(
                  children: [
                    Container(
                      width: 468,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text("Create Poll", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14, fontWeight: FontWeight.w500))
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                        color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 468,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Wrap(
                              direction: Axis.vertical,
                              children: [
                                Container(
                                  width: 468 - 24*2,
                                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                                  child: CupertinoTextField(
                                    controller: _titleController,
                                    autofocus: true,
                                    onChanged: (e) {
                                      setState(() { title = e; });
                                    },
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    placeholder: "What's your poll about?",
                                    placeholderStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xff828282)),
                                    style: TextStyle(fontSize: 13.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xff353535) : const Color(0xfff8f8f8),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Utils.checkedTypeEmpty(_titleController.text.trim())
                                        ? isDark ? Colors.grey[600]! : const Color(0xffdbdbdb)
                                        : Colors.red),
                                    ),
                                  )
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  width: 468-24*2,
                                  margin: const EdgeInsets.only(top: 4),
                                  child: SingleChildScrollView(
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(12,0,12,0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark ? Colors.grey[600]! : const Color(0xffdbdbdb),
                                        ),
                                        color: isDark ? const Color(0xff353535) : const Color(0xfff8f8f8),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: Wrap(
                                        children: [
                                          Column(
                                            children: options.map<Widget>((option) {
                                              final title = option['title'];
                                              TextEditingController _optionController = TextEditingController(text: title);
                                              return Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: isDark ? const Color(0xff4C4C4C) : const Color(0xffdbdbdb),
                                                      width: 1
                                                    )
                                                  )
                                                ),
                                                child: Container(
                                                  width: 468-16*4,
                                                  child: CupertinoTextField(
                                                    key: Key(option["id"].toString()),
                                                    autofocus: true,
                                                    controller: _optionController,
                                                    onChanged: (value) {
                                                     
                                                      var index = options.indexWhere((e) => e["id"] == option["id"]);
                                                      options[index]['title'] = value; 
                                                    },
                                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                                    placeholder: "Option",
                                                    placeholderStyle: const TextStyle(
                                                      fontSize: 14, 
                                                      color:Colors.red),
                                                    style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xff353535) : const Color(0xfff8f8f8),
                                                    ),
                                                    suffix: InkWell(
                                                      onTap: () {
                                                        var index = options.indexWhere((e) => e['id'] == option['id']);
                                                        setState(() => options.removeAt(index));
                                                      },
                                                      child: Icon(PhosphorIcons.xCircle, color: isDark ? Colors.grey[400] : const Color(0xff5e5e5e), size: 18)
                                                    )
                                                  )
                                                )
                                              );
                                            }).toList(),
                                          ),
                                        ]
                                      ),
                                    ),
                                  ),
                                )
                              ]
                            )
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                options.add({'id': generateOptionID(), 'title':""});
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isDark ? const Color(0xff4c4c4c) : const Color(0xfff8f8f8)
                              ),
                              width: 468 - 24*2,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.plusCircle, size: 20.0, color: isDark ? Palette.calendulaGold : Colors.blue),
                                  const SizedBox(width: 8),
                                  Text("Add an option", style: TextStyle(color: isDark ? Palette.calendulaGold : Colors.blue)),
                                ],
                              )
                            )
                          ),
                          Container(width: double.infinity, color: isDark ? const Color(0xff5e5e5e) : const Color(0xffdbdbdb), height: 1),
                          Center(
                            child: Container(
                              width: 468-16*2,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.redAccent
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: isDark ? const Color(0xff3D3D3D) : Colors.white
                                    ),
                                    width: 212,
                                    height: 32,
                                    child: TextButton(onPressed: () {Navigator.pop(context);}, child: Text(S.current.cancel, style: const TextStyle(color: Colors.redAccent)))
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.blueAccent
                                    ),
                                    width: 212,
                                    height: 32,
                                    child: TextButton(onPressed: () {
                                      var _index = options.indexWhere((e) => !Utils.checkedTypeEmpty(e['title'].trim()));
                                      if (_index == -1) {
                                        if (Utils.checkedTypeEmpty(title.trim()) && options.isNotEmpty) {
                                          createPollMessage();
                                        } else {
                                          validateWarning(context, isDark, "A poll needs a title and options");
                                        }

                                      } else {
                                        validateWarning(context, isDark, "Cannot leave an option blank");
                                      }
                                    }, child: const Text("Create Poll", style: TextStyle(color: Colors.white)))
                                  )
                                ]
                              )
                            ),
                          )
                        ],
                      ),
                    ),
                    
                  ]
                )
              )
            );
          }                
        );
      }
    );
  }

  Future<dynamic> validateWarning(BuildContext context, bool isDark, String warningContent) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: isDark ? Palette.borderSideColorDark : Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Container(
                width: 210,
                height: 100,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text("$warningContent"),
                    const SizedBox(height: 26),
                    TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      child: const Text("Close"),
                    ),
                  ],
                )
              )
            );
          }
        );
      }
    );
  }
}

class RenderMessageByDay extends StatefulWidget {
  const RenderMessageByDay({
    Key? key,
    required this.controller,
    required this.theme,
    required this.locale,
    required this.currentChannel,
    required this.updateMessage, 
    this.keyMessageToJump, 
    this.messageIdToJump,
    this.onFirstFrameMessageSelectedDone,
    this.onShareMessage
  }) : super(key: key);

  final ScrollController controller;
  final ThemeType theme;
  final String locale;
  final Map currentChannel;
  final updateMessage;
  final keyMessageToJump;
  final messageIdToJump;
  final onFirstFrameMessageSelectedDone;
  final Function? onShareMessage;

  @override
  State<RenderMessageByDay> createState() => _RenderMessageByDayState();
}

class _RenderMessageByDayState extends State<RenderMessageByDay> {
  bool isShow = true;
  GlobalKey<DraggableScrollbarState> keyScroll = GlobalKey<DraggableScrollbarState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.jumpTo(0.000000000001);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final messagesData = Provider.of<Messages>(context, listen: true).data.where((element) => element["channelId"] == currentChannel["id"]).toList();
    final data = (messagesData.isNotEmpty ? messagesData[0]["messages"] : []).toList();
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final customColor = Provider.of<User>(context, listen: false).currentUser["custom_color"];
    int index = Provider.of<Messages>(context, listen: true).data.indexWhere((element) => element["channelId"].toString() == currentChannel["id"].toString());
    var isFetchingUp =  (index == -1 ? false :  Provider.of<Messages>(context).data[index]["isLoadingUp"]) ?? false;
    var isFetchingDown =  (index == -1 ? false :  Provider.of<Messages>(context).data[index]["isLoadingDown"]) ?? false;
    
    return Expanded(
      child: SelectableScope(
        child: DraggableScrollbar.rrect(
          key: keyScroll,
          id: currentChannel["id"],
          onChanged: (bool value) {
            if(isShow != value) {
              setState(() {
              isShow = value;
            });
            }
          },
          heightScrollThumb: 56,
          backgroundColor: Colors.grey[600],
          scrollbarTimeToFade: const Duration(seconds: 2),
          itemCount: data.length,
          controller: widget.controller,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Container(
              height: double.infinity,
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                controller: widget.controller,
                itemCount: data.length,
                itemBuilder: (context, index) { 
                  var message = data[index];
                  var isAfterThread = (index + 1) < data.length ? (((data[index +  1]["count_child"] ?? 0) > 0)) : false;

                  return ChatItemMacOS(
                    key: (message["id"] != null && message["id"] != "") ? Key(message["id"]) : message["message_key"] != null ? Key( message["message_key"]) : null,
                    userId: message["user_id"],
                    isChildMessage: false,
                    id: message["id"],
                    isMe: message["user_id"] == userId,
                    accountType: message["account_type"],
                    message: message["message"],
                    avatarUrl: message["avatar_url"],
                    insertedAt: message["inserted_at"],
                    lastEditedAt: message["last_edited_at"],
                    isUnsent: message["is_unsent"],
                    fullName: Utils.getUserNickName(message["user_id"]) ?? message["full_name"],
                    attachments: message["attachments"] == null ?  [] : message["attachments"],
                    isFirst: message["isFirst"],
                    isLast: message["isLast"],
                    isChannel: true,
                    isThread: false,
                    count: message["count_child"],
                    infoThread: message["info_thread"] != null ? message["info_thread"] : [],
                    success: message["error"] == null ? true : message["error"],
                    showHeader: false,
                    showNewUser: message["showNewUser"],
                    isSystemMessage: message["is_system_message"] ?? false,
                    isBlur: message["isBlur"],
                    updateMessage: widget.updateMessage,
                    reactions: message["reactions"],
                    snippet: message["snippet"] ?? "",
                    blockCode: message["block_code"] ?? "",
                    isViewMention: false,
                    channelId: currentChannel["id"],
                    idMessageToJump: widget.messageIdToJump,
                    onFirstFrameDone: widget.onFirstFrameMessageSelectedDone ,
                    firstMessage: message["firstMessage"],
                    onShareMessage: widget.onShareMessage,
                    isDark: isDark,
                    customColor: customColor,
                    currentTime: message["current_time"],
                    isAfterThread: isAfterThread,
                    isShow: isShow,
                    keyScroll: keyScroll,
                    isFetchingDown: isFetchingDown && index == data.length - 1,
                    isFetchingUp: isFetchingUp && index == 0,
                  );
                }
              ),
            )
          )
        )
      )
    );
  }
}
