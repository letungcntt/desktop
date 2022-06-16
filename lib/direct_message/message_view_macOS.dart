import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:better_selection/better_selection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/draggable_scrollbar.dart';
import 'package:workcake/components/drop_target.dart';
import 'package:workcake/components/file_items.dart';
import 'package:workcake/components/message_item/chat_item_macOS.dart';
import 'package:workcake/components/message_item/record_audio.dart';
import 'package:workcake/components/typing.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/action_input.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';


class MessageViewMacOS extends StatefulWidget {
  final id;
  final name;
  final avatarUrl;
  final DirectModel dataDirectMessage;
  final itemFiles;
  final idMessageToJump;

  MessageViewMacOS({
    Key? key,
    this.id, // truong nay se ko dc dung nua do dup trong this.dataDirectMessage
    @required this.name,
    @required this.avatarUrl,
    required this.dataDirectMessage, 
    this.itemFiles, this.idMessageToJump
  }) : super(key: key);

  @override
  _MessageViewMacOSState createState() => _MessageViewMacOSState();
}

// check miss message and load it to local
// only call hive db when offline;

class _MessageViewMacOSState extends State<MessageViewMacOS> {
  var data = [];
  var listkeyMessage = [];
  var directMessageBox;
  bool isInternet = false;
  var channel;
  ScrollController controller = ScrollController();
  int page = 0;
  var token = "";
  List images = [];
  List fileItems = [];
  var selectedMessage;
  var maxLine;
  int newLine = 1;
  bool isSelectAll = false;
  bool isMentions = true;
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  List<Map<String, dynamic>> suggestionMentions = [];
  bool islastEdited = false;
  bool isSendMessage = false;
  Timer? _debounce;
  bool isBlockCode = false;
  GlobalKey keyMessageToJump = GlobalKey();
  bool isSend = false;
  bool isShowRecord = false;

  bool isShow = true;
  GlobalKey<DraggableScrollbarState> keyScroll = GlobalKey<DraggableScrollbarState>();

  bool streamShowGoUpStatus = false;
  final streamShowGoUp = StreamController<bool>.broadcast(sync: false);

  @override
  void initState() {
    super.initState();
    DateTime.now();
    // ktra tin nhan trong mention, neu da co trong Provider thi scroll toi vi tri do
    // truowngf hojp chua co se lay 15 tin truoc do + 15 tin nhan sau do va scroll den tin nhan do
    // listView co kha nang loadmore 2 chieu

    DropTarget.instance.initDrop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataMessageConversation = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.dataDirectMessage.id);

      controller..addListener(_scrollListener);
      if(dataMessageConversation != null) controller.jumpTo(0.000000000001);
    });

    RawKeyboard.instance.addListener(keyboardListener);
    Timer.run(() async {
      if (widget.id == ""){
        // initData();
      }
      else {
        token = Provider.of<Auth>(context, listen: false).token;
        channel = await Provider.of<Auth>(context, listen: false).channel;
        channel.on("dm_message", (data, _ref, _joinRef) {
          processMessage(data);
        });

        DirectModel directMessage = widget.dataDirectMessage;
        channel.push(event: "join_direct", payload: {"direct_id": directMessage.id});
        channel.on("update_dm_message", (data, _ref, _joinRef) {
          updateMessage(data);
        });
      }

      unHideDirectMessage();
      // sau 10s xoa danh dau tin nhan moi
      // markUnNewMessage();
    });
  }

  unHideDirectMessage(){
    Provider.of<DirectMessage>(context, listen: false).setHideConversation(widget.dataDirectMessage.id, false, context);
  }

  createDirectMessage(user) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final token = auth.token;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    List listUserDM = [user, {"user_id":currentUser["id"] }];
    Provider.of<DirectMessage>(context, listen: false).createDirectMessage(
      token, 
      {
        "users": listUserDM
      }, 
      context,
      userId
    );
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    
    if (oldWidget.dataDirectMessage.id != widget.dataDirectMessage.id) { 
      setState(() {
        isShowRecord = false;
        DropTarget.instance.initDrop();
        fileItems = [];
      });
      setStreamShow(false);
      getLastEdited();
      unHideDirectMessage();
      // onFirstFrameMessageSelectedToJumpDone();
      FocusInputStream.instance.focusToMessage();
      // key.currentState!.focusNode.requestFocus();
      // markUnNewMessage();
      // focus vao input
      // if (widget.id  == ""){
      //   initData();
      // }
    }
  }

  markUnNewMessage()async{
    try {
      await Future.delayed(const Duration(seconds: 5));
      Provider.of<DirectMessage>(context, listen: false).removeMarkNewMessage(widget.dataDirectMessage.id);
    } catch (e) {
    }
  }

  processFiles(files) async {
    List result  = [];
    for(var i = 0; i < files.length; i++) {
      // check the path has existed
      var file = files[i];
      var existed  =  fileItems.indexWhere((element) => (element["path"] == files[i]["path"] && element['name'] == file['name']));
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
    fileItems = [] + fileItems +result;
    if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    StreamDropzone.instance.initDrop();
    onSaveAttachments();
  }

  onChangeIsSendMessage(value) {
    isSendMessage = value;
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

  getLastEdited() async {
    var box = await Hive.openBox('drafts');
    var lastEdited = box.get('lastEdited');
    var lastEditedFile = box.get('lastEditedFile');
    var openSetting = box.get('openSetting');

    if (openSetting != null) {
      if (openSetting) {
        Provider.of<DirectMessage>(context, listen: false).openDirectSetting(true);
      }
    }

    if (lastEdited != null || lastEditedFile != null) {
      final index = lastEdited.indexWhere((e) => e["id"] == widget.dataDirectMessage.id);
      final indexAttachment = lastEditedFile.indexWhere((e) => e["id"] == widget.dataDirectMessage.id);

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
            fileItems = files;
          });
        }
      }
    }
  }

  onEdittingText(value) {
    // setState(() {
      islastEdited = value;
    // });
  }

  getDataMentions() {
    final directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    var listUser = directMessage.user;
    setState(() {
      suggestionMentions = [{'id': widget.dataDirectMessage.id, 'display': 'all', 'full_name': 'all', 'photo': 'all'}];
      for (var i = 0 ; i< listUser.length; i++){
        Map<String, dynamic> item = {
          'id': listUser[i]["user_id"],
          'display': listUser[i]["full_name"],
          'full_name': listUser[i]["full_name"],
          'photo': listUser[i]["avatar_url"]
        };
        suggestionMentions += [item];
      }
    });
  }

  getSuggestionMentions() {
    final auth = Provider.of<Auth>(context, listen: false);
    final dataUserMentions = Provider.of<User>(context, listen: false).userMentionInDirect;
    final directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    var listUser = [] + directMessage.user + dataUserMentions;
    Map index = {};

    List<Map<String, dynamic>> dataList = directMessage.user.length > 2 ? [{'id': widget.dataDirectMessage.id, 'display': 'all', 'full_name': 'all', 'photo': 'all', 'type': 'all'}] : [];
      for (var i = 0 ; i< listUser.length; i++){
        if (index[listUser[i]["user_id"]] != null) continue;
        Map<String, dynamic> item = {
          'id': listUser[i]["user_id"],
          'type': 'user',
          'display': listUser[i]["full_name"],
          'full_name': listUser[i]["full_name"],
          'photo': listUser[i]["avatar_url"]
        };
        index[listUser[i]["user_id"]] = true;

        if (auth.userId != listUser[i]["user_id"]) dataList += [item];
      }

    return dataList;
  }

  saveChangesToHive(str) async {
    var box = await Hive.openBox('drafts');
    var lastEdited = box.get('lastEdited');
    List changes;

    if (lastEdited == null) {
      changes = [{
        "id": widget.dataDirectMessage.id,
        "text": str,
      }];
    } else {
      changes = List.from(lastEdited);
      final index = changes.indexWhere((e) => e["id"] == widget.dataDirectMessage.id);

      if (index != -1) {
        changes[index] = {
          "id": widget.dataDirectMessage.id,
          "text": str,
        };
      } else {
        changes.add({
          "id": widget.dataDirectMessage.id,
          "text": str,
        });
      }
    }

    box.put('lastEdited', changes);
  }

  handleMessage() {
    final auth = Provider.of<Auth>(context, listen: false);
    onChangeIsSendMessage(true);
    _uploadImage(auth.token);
    handleCodeBlock(false);

    setState(() {
      newLine = 1;
    });
    Timer(const Duration(microseconds: 100), () => {
      key.currentState!.controller!.clear(),
      saveChangesToHive('')
    });
  }

  disconnectDirect() {
    channel = Provider.of<Auth>(context, listen: false).channel;
    channel.push(event: "disconnect_direct", payload: {});
  }

  processMessage(dataM) {
    DirectModel directMessage = widget.dataDirectMessage;
    if (directMessage.id != dataM["conversation_id"]) return;
    var newData = {
      "message": dataM["message"],
      "attachments": dataM["attachments"],
      "title": "",
      "conversation_id": dataM["conversation_id"],
      "show": true,
      "id": dataM["id"],
      "user_id": dataM["user_id"],
      "time_create": dataM["inserted_at"],
      "count": 0
    };
    if (mounted) {
      setState(() {
        data.insert(0, newData);
      });
    }
  }

  updateMessage(dataM) {
    var index = data.indexWhere((element) {
      return element["id"] == dataM["id"];
    });
    if (index >= 0) {
      setState(() {
        data[index]["message"] = dataM["message"];
      });
    }
  }

  setStreamShow(bool value){
    streamShowGoUpStatus = value;
    streamShowGoUp.add(streamShowGoUpStatus);
  }

  _scrollListener() {
    final auth = Provider.of<Auth>(context, listen: false);
    if (controller.position.extentAfter < 10) {
      Provider.of<DirectMessage>(context, listen: false).getMessageFromApi(widget.dataDirectMessage.id, auth.token, false, null, auth.userId);
    }
    if (controller.position.extentBefore > 10 && !streamShowGoUpStatus && controller.position.userScrollDirection == ScrollDirection.reverse){
      setStreamShow(true);
    }
    if (controller.position.extentBefore < 10 && streamShowGoUpStatus && (controller.position.userScrollDirection == ScrollDirection.forward || controller.position.userScrollDirection == ScrollDirection.idle)){
      if (streamShowGoUpStatus){
        setStreamShow(false);
      }  
    }
    if (controller.position.extentBefore < 10 && (controller.position.userScrollDirection == ScrollDirection.forward)){
      Provider.of<DirectMessage>(context, listen: false).getMessageFromApiUp(widget.dataDirectMessage.id, auth.token, auth.userId);
      if (streamShowGoUpStatus || controller.position.userScrollDirection == ScrollDirection.idle){
        setStreamShow(false);
      }
    }

  }

  handleCodeBlock(bool value) {
    setState(() {
      isBlockCode = value;
    });
  }

  sendDirectMessage(token) async {
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText);
    var idDirectmessage = widget.dataDirectMessage.id;
    var fakeId = getRandomString(20);
    var userId = Provider.of<Auth>(context, listen: false).userId;
    var currentUser =  Provider.of<User>(context, listen: false).currentUser;
    List list = fileItems;
    var checkingShareMessage = list.where((element) => element["mime_type"] == "share").toList();
    print(checkingShareMessage);
    var dataMessage = {
      "message": result["success"] || isBlockCode ? "" : result["data"],
      "attachments": [] + (result["success"] ? [{"type": "mention", "data": result["data"]}] : []) + (isBlockCode ? [{"type": "block_code", "data": key.currentState!.controller!.text}] : []) + checkingShareMessage,
      "title": "",
      "conversation_id": idDirectmessage,
      "show": true,
      "id": selectedMessage == null ?  "" : selectedMessage.split("__")[1],
      "user_id": userId,
      "avatar_url": currentUser["avatar_url"],
      "full_name": currentUser["full_name"],
      "time_create": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "count": 0,
      "sending": true,
      "success": true,
      "fake_id": fakeId,
      "current_time": DateTime.now().millisecondsSinceEpoch * 1000 + 600000000,
      "isSend": selectedMessage == null ? true : false,
      "isDesktop": true
    };

    if (selectedMessage != null ){
      var dataMessageSelected = await directMessageBox.get(selectedMessage);
      if (dataMessageSelected["attachments"] != null){
        var  attachments = dataMessageSelected["attachments"];
        for(var i= 0; i< attachments.length; i ++){
          if ((attachments[i]["type"] ?? "") != "mention"){
            dataMessage["attachments"] +=[attachments[i]];
          }
        }
      }
    }

    key.currentState!.controller!.clear();
    setState(() {
      selectedMessage = null;
    });

    if ((dataMessage["message"] == "") && (dataMessage["attachments"].length == 0)){

    } else {
      Provider.of<DirectMessage>(context, listen: false).handleSendDirectMessage(dataMessage, token);
    }
      
  }

  getRandomString(int length){
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  getDMname(List data, String field) {
    if (data.length  == 1) return data[0][field];
    var result = "";
    var userId  = Provider.of<Auth>(context, listen: false).userId;
    for (var i = 0; i < data.length; i++) {
      if (data[i]["user_id"] == userId) continue;
      if (i != 0 && result != "") result += ", ";
      result += data[i][field];
    }
    return result;
  }

  // getDMname(DirectModel dm) {
  //   var users = dm.user;
  //   var result = "";
  //   for (var i = 0; i < users.length; i++) {
  //     if (i != 0) result += ", ";
  //     result += users[i]["full_name"];
  //   }

  //   return dm.name  != "" ? dm.name : result;
  // }

  loadAssets() async {
    var resultList;

    try {
      resultList = await MultiImagePicker.pickImages(maxImages: 10);
    } on Exception catch (e) {
      print(e.toString());
    }

    if (!mounted) return;

    if (resultList != null) {
      setState(() {
        images = resultList;
      });
    }
  }

  removeFile(index) {
    List list = fileItems;
    list.removeAt(index);
    setState(() {
      fileItems = list;
    });

    onSaveAttachments();
  }

  _uploadImage(token) {
    var directMessageSelected = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    var userId = Provider.of<Auth>(context, listen: false).userId;
    var currentUser = Provider.of<User>(context, listen: false).currentUser;

    List list = fileItems;
    var fakeId = getRandomString(20);
    var result = Provider.of<Messages>(context, listen: false).checkMentions(key.currentState!.controller!.markupText, trim: true);
    var idDirectmessage = directMessageSelected.id;
    var checkingShareMessage = list.where((element) => element["mime_type"] == "share").toList();
    var dataMessage = {
        "message": result["success"] || isBlockCode ? "" : result["data"],
        "attachments": [] + (result["success"] ? [{"type": "mention", "data": result["data"]}] : []) + (isBlockCode ? [{"type": "block_code", "data": [{"type": "block_code", "value": key.currentState!.controller!.text}]}] : []) + checkingShareMessage,
        "title": "",
        "conversation_id": idDirectmessage,
        "show": true,
        "id": selectedMessage == null ? "" : selectedMessage["id"],
        "user_id": userId,
        "time_create": selectedMessage == null ? DateTime.now().add(const Duration(hours: -7)).toIso8601String() : selectedMessage["time_create"],
        "count": 0,
        "isSend": selectedMessage == null,
        "sending": true,
        "success": true,
        "fake_id": fakeId,
        "current_time": selectedMessage == null ? DateTime.now().millisecondsSinceEpoch * 1000 : selectedMessage["current_time"],
        "isDesktop": true,
        "avatar_url": currentUser["avatar_url"],
        "full_name": currentUser["full_name"],
      };
    setState(() {
      DropTarget.instance.initDrop();
      fileItems = [];
      selectedMessage = null;
    });

    if (Utils.checkedTypeEmpty(dataMessage["message"]) || dataMessage["attachments"].length > 0 || list.isNotEmpty) {
      Provider.of<DirectMessage>(context, listen: false).sendMessageWithImage(list, dataMessage, token);  
    }
    key.currentState!.controller!.clear();
    onSaveAttachments();
  }

  openFileSelector() async {
    try {
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
          }).toList());
        }
      } else {
        // User canceled the picker
      }
      setState(() {
        key.currentState!.focusNode.requestFocus();
      });
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }
  selectEmoji(emoji) {
    key.currentState!.setMarkUpText((key.currentState?.controller?.markupText ?? '') + emoji.value);
    key.currentState!.focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    RawKeyboard.instance.removeListener(keyboardListener);
    super.dispose();
  }

  keyboardListener(RawKeyEvent event) {
    final keyId = event.logicalKey.keyId;

    if(event is RawKeyDownEvent) {
      if ((event.isMetaPressed || event.isAltPressed || event.isControlPressed)) {
        if(keyId.clamp(32, 126) == keyId) return KeyEventResult.handled;
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

  jumpToContext(BuildContext? c, String idMessage){
    BuildContext? messageContext = c;
    if (messageContext == null) return;
    final renderObejctMessage = messageContext.findRenderObject() as RenderBox;
    try {
      double height = 0.0;
      if (idMessage  == Provider.of<DirectMessage>(context, listen: false).idMessageToJump) height = messageContext.size!.height;
      var offsetGlobal = renderObejctMessage.localToGlobal(Offset.zero);
      var scrolllOffset = controller.offset - offsetGlobal.dy + MediaQuery.of(context).size.height - 150 - height;
      controller.animateTo(scrolllOffset >= 0 ? scrolllOffset : 0.0, duration: const Duration(milliseconds: 100), curve: Curves.ease);
    } catch (e) {
      print(e);
    }
  }

  onFirstFrameMessageSelectedDone(BuildContext? cont, int? time, String? idMessage){
    try {
      var idMessageToJump = Provider.of<DirectMessage>(context, listen: false).idMessageToJump;
      if (cont == null || idMessageToJump == "" || idMessage == null) return;
      List dataMessage  = [];
      final dataMessageConversation = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.dataDirectMessage.id);
      if (dataMessageConversation != null) {
        dataMessage = dataMessageConversation["messages"];
      }
      int index  = dataMessage.indexWhere((ele) => ele["id"] == idMessageToJump);
      if (index == -1 || time == null) return;
      int currentT = dataMessage[index]["current_time"];
      if (time >=currentT) jumpToContext(cont, idMessage);
      if (time == currentT) Provider.of<DirectMessage>(context, listen: false).setIdMessageToJump("");
    } catch (e) {

      print("PPPPPPP $e");
    }
  }

  onChangedTypeFile(int index, String name, String type) {
    setState(() {
      fileItems[index]['mime_type'] = type;
      fileItems[index]['name'] = name+'.'+type;
    });
    key.currentState?.focusNode.requestFocus();
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

  onEditMessage(String idMessage){
    var dataMessageConversation  = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.dataDirectMessage.id);
    if (dataMessageConversation != null) {
      List dataMessages = dataMessageConversation["messages"];
      var indexMessage = dataMessages.indexWhere((element) => element["id"] == idMessage);
      if (indexMessage != -1){
        var dataM = dataMessages[indexMessage];
        var message = dataM["message"];
        var mentions = dataM["attachments"] != null ? dataM["attachments"].where((element) => element["type"] == "mention").toList() : [];
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
        // Tat ca file can hien thi
        var attOldMessage = dataM["attachments"] != null ? dataM["attachments"].where((ele) => ele["mime_type"] != "block_code" && ele["type"] != "mention").toList() : [];
        setState((){
          selectedMessage = dataM;
          fileItems = attOldMessage;
        });
        key.currentState!.setMarkUpText(message);
        key.currentState!.focusNode.requestFocus();
      }
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

  handleMessageToAttachments(String message) {
    List<int> bytes = utf8.encode(message);
    String name = Utils.suffixNameFile('message', fileItems);
    processFiles([{
      "name": '$name.txt',
      "mime_type": 'txt',
      "path": '',
      "file": bytes
    }]);
  }

  @override
  Widget build(BuildContext context) {
    
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final theme = Provider.of<Auth>(context, listen: false).theme;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final directMessage = Provider.of<DirectMessage>(context, listen: true).getModelConversation(widget.id);
    if (directMessage == null) return Container();
    final listUser = directMessage.user;
    final dataDMMessages = Provider.of<DirectMessage>(context, listen: true).dataDMMessages;
    List dataMessage = [];
    final dataMessageConversation = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.dataDirectMessage.id);
    final dataInfoThreadMessage = Provider.of<DirectMessage>(context, listen: false).dataInfoThreadMessage;
    if (dataMessageConversation != null) {
      dataMessage = dataMessageConversation["messages"];
    }

    final index = dataDMMessages.indexWhere((e) => e["conversation_id"] == widget.dataDirectMessage.id);
    bool isEndDrawerOpen = Scaffold.of(context).isEndDrawerOpen;
    final idMessageToJump = Provider.of<DirectMessage>(context, listen: true).idMessageToJump;
    try {
      if (!dataMessageConversation["disableLoadingUp"]) setStreamShow(true);
      if (dataMessageConversation["disableLoadingUp"] && controller.position.extentBefore < 10) setStreamShow(false);      
    } catch (e) {
    }
    if (dataMessageConversation == null) {return Container();}
    return DropZone(
      stream: StreamDropzone.instance.dropped,
      initialData: [],
      shouldBlock: isEndDrawerOpen,
      builder: (context, files){
        if(files.data != null && files.data.length > 0) processFiles(files.data ?? []);
        final isPanchat = listUser.where((element) => element["user_id"] == "41b87209-ec1f-4781-a7be-4c861d4864ca").toList();

        return Container(
          child:  Stack(
            children: [
              LayoutBuilder(builder: (context, cts) {
                if (index != -1) {
                  var minDataMessageLength = cts.maxHeight / 15;

                  if (dataMessage.length < minDataMessageLength) {
                    Provider.of<DirectMessage>(context, listen: false).getMessageFromApi(widget.dataDirectMessage.id, auth.token, false, null, auth.userId);
                  }
                }
                return Container(width: 0, color: Colors.blue);
              }),
              Container(
                // color: theme == ThemeType.DARK ? Palette.backgroundRightSiderDark : Color(0xffF3F3F3),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      alignment: Alignment.center,
                      duration: const Duration(milliseconds: 300),
                      color: Colors.red[100],
                      height: index == -1 ? 0 : (dataDMMessages[index]["conversationKey"] == null) ? 50 : 0,
                      child: const Text("You can't send message to user on conversation.", style: TextStyle(color: Colors.red),),
                    ),
                    Container(
                      child: Expanded(
                        child: SelectableScope(
                          child: DraggableScrollbar.rrect(
                            key: keyScroll,
                            id: widget.dataDirectMessage.id,
                            onChanged: (bool value) {
                              if(isShow != value) {
                                setState(() {
                                isShow = value;
                              });
                              }
                            },
                            heightScrollThumb: 56,
                            backgroundColor: Colors.grey[600],
                            scrollbarTimeToFade: const Duration(seconds: 1),
                            itemCount: data.length,
                            controller: controller,
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: Container(
                                height: double.infinity,
                                child: ListView.builder(
                                  // physics: AllwaysScrollableFixedPositionScrollPhysics(),
                                  shrinkWrap: true,
                                  reverse: true,
                                  controller: controller,
                                  itemCount: dataMessage.length,
                                  itemBuilder: (context, index) { 
                                  // children: ([(dataMessageConversation["isFetching"] ?? false) ? (shimmerEffect(context, number: 1) as Widget) : (Container() as Widget)] as List<Widget>)
                                  //  + dataMessage.map<Widget>((message) {
                                    // + ([(dataMessageConversation["isFetchingUp"] ?? false) ? shimmerEffect(context, number: 1) : Container()] as List<Widget>)
                                    var message = dataMessage[index];
                                    if (message["action"] == "delete_for_me") return Container();
                                    var avatarUrl;
                                    var fullName;
                                    final int indexUser = directMessage.user.indexWhere((e) => e["user_id"] == message["user_id"]);
                                    final user = indexUser != -1 ? directMessage.user[indexUser] : null;
                                    if (user != null) {
                                      avatarUrl = user["avatar_url"];
                                      fullName = user["full_name"];
                                    }

                                    return Container(
                                      key: Key("message_${Utils.checkedTypeEmpty(message["id"]) ? message["id"] : message["fake_id"]}"),
                                      margin: EdgeInsets.only(bottom: index == dataMessage.length - 1 ? 8 : 0),
                                      child: ChatItemMacOS(
                                        key:  (message["id"] != null && message["id"].trim() != "") ? Key(message["id"]) : Key(message["fake_id"]),
                                        idMessageToJump: idMessageToJump,
                                        onEditMessage: onEditMessage,
                                        isChannel: false,
                                        id: "${message["current_time"]}" == "1"  ? null :message["id"],
                                        accountType: message["account_type"] ?? "user",
                                        isMe: message["user_id"] == auth.userId,
                                        message: message["message"] ?? "",
                                        avatarUrl: avatarUrl ?? message["avatar_url"],
                                        insertedAt: message["inserted_at"] ?? message["time_create"],
                                        fullName: fullName ?? message["full_name"],
                                        attachments: message["attachments"],
                                        isFirst: message["isFirst"],
                                        count: (dataInfoThreadMessage[message["id"]] ?? {})["count"] ?? message["count"] ?? 0,
                                        isLast: message["isLast"],
                                        isChildMessage: false,
                                        userId: message["user_id"],
                                        success: message["success"] ?? true,
                                        infoThread: message["info_thread"] ?? [],
                                        showHeader: false,
                                        showNewUser: message["showNewUser"],
                                        isBlur:  message["isBlur"] ?? false,
                                        reactions: message["reactions"] ?? [],
                                        isThread: false,
                                        firstMessage: message["firstMessage"],
                                        isSystemMessage: message["is_system_message"] ?? false,
                                        isViewMention: false,
                                        conversationId: message["conversation_id"] ?? widget.dataDirectMessage.id,
                                        // lastEditedAt: Utils.checkedTypeEmpty(message["last_edited_at"]) && message["last_edited_at"] != "null" ? message["last_edited_at"] : null,
                                        onFirstFrameDone: onFirstFrameMessageSelectedDone,
                                        isDark: isDark,
                                        waittingForResponse: (message["status_decrypted"] ?? "") == "decryptionFailed",
                                        isUnreadThreadMessage: ((dataInfoThreadMessage[message["id"]] ?? {})["is_read"] ?? true),
                                        isUnsent: (message["action"] ?? "") == "delete",
                                        currentTime: message["current_time"],
                                        isDirect: true,
                                        onShareMessage: onShareMessage,
                                        isShow: isShow,
                                        keyScroll: keyScroll,
                                        isFetchingDown: (dataMessageConversation["isFetchingDown"] ?? false) && index == dataMessage.length,
                                        isFetchingUp: (dataMessageConversation["isFetchingUp"] ?? false) && index == 0,
                                      ),
                                    );
                                  }
                                ),
                              )
                            )
                          )
                        )
                      )
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Column(
                          children: [
                            fileItems.isNotEmpty ? FileItems(files: fileItems, removeFile: removeFile, onChangedTypeFile: onChangedTypeFile) : Container(),
                            isShowRecord
                              ? RecordAudio(onExit: (value) => setState(() => isShowRecord = value), isDMs: true)
                              : Container(
                                  decoration: BoxDecoration(
                                    color: theme == ThemeType.DARK ? Palette.backgroundTheardDark : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: theme == ThemeType.DARK ? const Border() : Border.all(
                                      color: const Color(0xffA6A6A6), width: 0.5
                                    ),
                                  ),
                                  child: isPanchat.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.only(left: 10, bottom: 10, top: 14),
                                        child: Row(
                                          children: [
                                            Text("This sender does not support replies", style: TextStyle(fontSize: 15, color: theme == ThemeType.DARK ? Colors.grey[300] : Colors.grey[800])),
                                          ],
                                        ),
                                      )
                                    : Column(
                                      children: [
                                        FlutterMentions(
                                            afterFirstFrame: (){
                                              getLastEdited();
                                              // key.currentState!.focusNode.requestFocus();
                                            },
                                            parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                                            readOnly: isPanchat.isNotEmpty ? true : false,
                                            style: TextStyle(fontSize: 15.5, color: theme == ThemeType.DARK ? Colors.grey[300] : Colors.grey[800]),
                                            cursorColor: theme == ThemeType.DARK ? Colors.grey[400]! : Colors.black87,
                                            autofocus: true,
                                            isUpdate: false,
                                            isShowCommand: false,
                                            onChanged: (value) {
                                              saveChangesToHive(key.currentState!.controller!.markupText);
                                              if(!isSend && value.isNotEmpty) {
                                                setState(() => isSend = true);
                                              } else if (isSend && value.isEmpty) {
                                                setState(() => isSend = false);
                                              }

                                              if (value.trim() != "") {
                                                if (_debounce?.isActive ?? false) _debounce?.cancel();
                                                _debounce = Timer(const Duration(milliseconds: 500), () {
                                                  auth.channel.push(
                                                    event: "on_typing",
                                                    payload: {"conversation_id": widget.dataDirectMessage.id, "user_name": currentUser["full_name"]}
                                                  );
                                                });
                                              }
                                            },
                                            id: widget.dataDirectMessage.id,
                                            isIssues: false,
                                            isDark: auth.theme == ThemeType.DARK,
                                            sendMessages: handleMessage,
                                            onEdittingText: onEdittingText,
                                            islastEdited: islastEdited,
                                            handleMessageToAttachments: handleMessageToAttachments,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              isDense: true,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              contentPadding: const EdgeInsets.only(left: 5, bottom: 10, top: 18),
                                              hintText: "Type a message...",
                                              hintStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5, height: 1)
                                            ),
                                            isCodeBlock: isBlockCode,
                                            handleCodeBlock: handleCodeBlock,
                                            key: key,
                                            suggestionListDecoration: const BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.circular(8)),
                                            ),
                                            onSearchChanged: (trigger,value) {
                                              if (trigger == "@"){
                                                getDataMentions();
                                              }
                                            },
                                            mentions: [
                                              Mention(
                                                markupBuilder: (trigger, mention, value, type) {
                                                  return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                                                },
                                                trigger: '@',
                                                style: const TextStyle(
                                                  color: Colors.lightBlue,
                                                ),
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
                                              if (!isPanchat.isNotEmpty) ActionInput(
                                                openFileSelector: openFileSelector,
                                                selectEmoji: selectEmoji,
                                                showRecordMessage: (value) => setState(() => isShowRecord = value)
                                              ),
                                              IconButton(
                                                icon: Icon(selectedMessage != null? Icons.check : Icons.send,
                                                color: (isSend || (fileItems.isNotEmpty))
                                                  ? const Color(0xffFAAD14)
                                                  : isDark ? const Color(0xff9AA5B1) : const Color(0xff616E7C),
                                                  size: 18
                                                ),
                                                onPressed: () => (isSend || (fileItems.isNotEmpty)) ? handleMessage() : null,
                                              ),
                                            ],
                                          )
                                      ],
                                    )
                                ),
                            TypingDesktop(id: widget.dataDirectMessage.id)
                          ]
                        )
                      )
                    )
                
                  ]
                )
              ),
              dataMessageConversation != null && dataMessageConversation["numberNewMessage"] != null && dataMessageConversation["numberNewMessage"] != 0 
              ? Positioned(
                bottom: 100,
                height: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: HoverItem(
                    
                    child: GestureDetector(
                      onTap: (){
                        setStreamShow(false);
                        Provider.of<DirectMessage>(context, listen: false).resetOneConversation(widget.dataDirectMessage.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme == ThemeType.DARK ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          border: Border.all(color: const Color(0xFFbfbfbf), width: 1),
                        ),
                        child: Text(
                          "${dataMessageConversation["numberNewMessage"]} new messages",
                          style: TextStyle(fontSize: 12, color: theme == ThemeType.DARK ? Colors.white70 : const Color(0xFF6a6e74)),
                        ),
                      ),
                    ),
                  ),
                ),
              ) 
              : Container(),
              // StreamBuilder(
              //   stream: streamShowGoUp.stream,
              //   initialData: false,
              //   builder: (context, snapshot) {
              //     bool isShow = (snapshot.data as bool?) ?? false;
              //     return AnimatedPositioned(
                    
              //       duration: Duration(milliseconds: 300),
              //       bottom: isShow ? 80 : -100, left: 0, right: 0,
              //       child: Center(
              //         child: HoverItem(
              //           // colorHover: Colors.pink,
              //           child: InkWell(
              //             onTap: () {
              //               setStreamShow(false);
              //               Provider.of<DirectMessage>(context, listen: false).resetOneConversation(widget.dataDirectMessage.id);
              //             },
              //             child: Container(
              //               padding: EdgeInsets.all(6),
              //               decoration: BoxDecoration(
              //                 borderRadius: BorderRadius.circular(16),
              //                 color: !isDark ? Color(0xFFbfbfbf) : Color(0xff262626)
              //               ),
              //               child: Icon(PhosphorIcons.arrowDown, size: 20)),
              //           ),
              //         ),
              //       ),
              //     );
              //   }
              // )
            ],
          ),
        );
      },
    );
  }
}
