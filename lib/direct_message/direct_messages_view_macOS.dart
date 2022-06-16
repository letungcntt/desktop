import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:context_menus/context_menus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/progress.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/call_center/room.dart';
import 'package:workcake/components/create_direct_message.dart';
import 'package:workcake/components/modal_invite_desktop.dart';
import 'package:workcake/components/option_notification_mode.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/media_conversation/drive_api.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/services/sync_data.dart';

import 'create_DMs_MacOS.dart';
import 'dm_input_shared.dart';

class DirectMessagesViewMacOS extends StatefulWidget {
  final handleCheckedConversation;
  DirectMessagesViewMacOS({
    Key? key,
    this.handleCheckedConversation
  }) : super(key: key);

  @override
  _DirectMessagesViewMacOSState createState() => _DirectMessagesViewMacOSState();
}

class _DirectMessagesViewMacOSState extends State<DirectMessagesViewMacOS> {
  var data = [];
  var direct;
  var deviceIp;
  var deviceInfo;
  var scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initData();
    deviceInfo = DeviceInfoPlugin();
    scrollController.addListener(() {
    if (scrollController.position.extentAfter < 50) 
      Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(Provider.of<Auth>(context, listen: false).token, Provider.of<Auth>(context, listen: false).userId, isLoadMore: true);
    });
  }

  Future initData() async {
    // send data to the Provide to use
    // await Hive.openBox('direct');
    direct =  Hive.box('direct');
    setState(() {});
    // call api
  }

  disconnectDirect() {
    final channel = Provider.of<Auth>(context, listen: false).channel;
    channel.push(
      event: "disconnect_direct",
      payload: {}
    );
  }

  String getTextAtt(int video, int other ,int image, int callterminated, int attachment, int inviied,) {
    if (video == 1 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentAVideo;
    if (video > 1 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentVideos(video);
    if (video == 0 && other == 1 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentAFile;
    if (video == 0 && other > 1 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentFiles(other);
    if (video == 0 && other == 0 && image == 1 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentAnImage;
    if (video == 0 && other == 0 && image > 1 && callterminated == 0 && attachment == 0 && inviied == 0) return S.current.sentImages(image);
    if (video == 0 && other == 0 && image == 0 && callterminated == 1 && attachment == 0 && inviied == 0) return S.current.theVideoCallEnded;
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment == 1 && inviied == 0) return S.current.sentAttachments;
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 1) return "";
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return "";
    return S.current.sentAttachments;
  }

  String renderSnippet(List att, dm) {   
   Map t = getType(att, dm);
    return  getTextAtt(t['video'], t['other'], t['image'],t['call_terminated'],t['attachment'],t['inviied'],) + t['mention'];
  }

  Map getType(List att, dm) {
     Map t ={
      'image':0, 
      'video':0,
      'other':0,
      'call_terminated':0,
      'attachment':0,
      'inviied':0,
      'mention':''
    };
    for (int i =0; i< att.length; i++) {
      
      String? mime= att[i]['mime_type']?? '';
      
      if (mime == null) continue;
      if (mime=='image'||mime=='jpg') {
        t['image'] += 1;
      } else {
        if (mime=="mov"||mime=="mp4"||mime=="video") {
          t['video']+=1;
        } else if(att[0]['type']=='call_terminated') {
          t['call_terminated']+=1;
        } else if(att[0]['type'] == 'device_info' || att[0]['type'] == 'action_button' || att[0]['type'] == 'assign' || att[0]['type'] == 'close_issue' || att[0]['type'] == 'invite') {
          t['attachment']+=1;
        } else if(att[0]['type']=='invite_direct') {
          t['inviied']+=1;
        } else if (att[0]["type"] == "mention"){
          t['mention']+= att[0]["data"].map((e) {
            if (e["type"] == "text" ) return e["value"];
            return "${e["trigger"] ?? "@"}${e["name"] ?? ""} ";
          }).toList().join();
        } else {
          t['other']+=1;
        }
      }
    }
    return t;
  }
  
  sendRequestSync(channel, auth, String type) async{
    // get channel.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 448,
            height: 400,
            child: DMInputShared(type: type)
          ),
        );
      }
    );

    if (type == "reset") {
      Provider.of<User>(context, listen: false).sendRequestCreateVertifyCode(auth.token);
    } else {
      var device = await Utils.getDeviceInfo();
      inspect(device);
      LazyBox box  = Hive.lazyBox('pairKey');
      Map data  =  {
        "deviceId": await box.get("deviceId")
      };
      channel.push(
        event: "request_conversation_sync",
        payload: {
          "data": await Utils.encryptServer(data),
          "device_id": await box.get("deviceId"),
          "device_name": device["name"],
          "device_ip": device["ip"]
        }
      );      
    }
  }

  inviteDirectModel(BuildContext context, DirectModel directMessage) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    if (directMessage.user.length < 3)
      return showDialog(
        context: context, 
        builder: (BuildContext context){
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Container(
              height: 700.0,
              width: 550.0,
              child: CreateDirectMessage(
                defaultList: directMessage.user.map((ele) => Utils.mergeMaps([
                  ele, {"id": ele["user_id"]}
                ])).toList(),
              ),
            ),
          );
        }
      );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Color(0xFF3D3D3D) : Colors.white,
          contentPadding: EdgeInsets.all(0),
          content: Container(
            height: 600.0,
            width: 500.0,
            child: Center(
              child: InviteModalDesktop(directMessage: directMessage)
            )
          )
        );
      }
    );
  }

  getIconNotification(String status, isDark) {
    switch (status) {
      case "NORMAL":
        return SvgPicture.asset(
          'assets/icons/noti_bell.svg',
          color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
          width: 10, height: 10
        );
      case "MENTION":
        return SvgPicture.asset(
          'assets/icons/noti_mentions.svg',
          color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
          width: 10, height: 10
        );
      case "OFF":
        return SvgPicture.asset(
          'assets/icons/noti_silent.svg',
          color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
          width: 10, height: 10
        );
      default:
        return SvgPicture.asset(
          'assets/icons/noti_bell.svg',
          color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
          width: 10, height: 10
        );
    }
  }

  getRoomIsActive(id, rooms) {
    final indexRoom = rooms.indexWhere((element) => element["id"] == id);
    bool roomIsActive = false;
    if (indexRoom != -1) {
      roomIsActive = rooms[indexRoom]["isActive"];
    }
    return roomIsActive;
  }

  @override
  Widget build(BuildContext context) {
    final currentDirectMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final list = Provider.of<DirectMessage>(context, listen: true).data.toList();
    final dataConversationMessages = Provider.of<DirectMessage>(context, listen: true).dataDMMessages;
    final selectedFriend = Provider.of<DirectMessage>(context, listen: true).selectedFriend;
    final selectedMention = Provider.of<DirectMessage>(context, listen: true).selectedMentionDM;
    final auth = Provider.of<Auth>(context, listen: true);
    final errorCode = Provider.of<DirectMessage>(context, listen: true).errorCode;
    final channel = Provider.of<Auth>(context, listen: true).channel;
    final isDark = auth.theme == ThemeType.DARK;
    // final pendingUsers = Provider.of<User>(context, listen: true).pendingList;
    final isFetching = Provider.of<DirectMessage>(context, listen: true).fetching;
    final rooms = Provider.of<RoomsModel>(context, listen: true).rooms;

    return Column(
      children: <Widget>[
        ContextMenuRegion(
          contextMenu: GenericContextMenu(
            buttonConfigs: [
              ContextMenuButtonConfig (
                DriveService.instance != null ? S.current.loggedIntoGoogleDrive : S.current.connectGoogleDrive,
                icon: Icon(PhosphorIcons.googleLogo, size: 18),
                onPressed: () async {
                  var str = await Utils.encryptServer({
                    "user_id": auth.userId
                  });
                  var state = base64Encode(
                    utf8.encode
                   ( jsonEncode({
                      "string": str,
                      "device_id": await Utils.getDeviceId()
                    }))
                  );
                  launch(
                    "https://accounts.google.com/o/oauth2/auth?client_id=592269086567-n7q8u3mde17eo7cn2dloj5kbmkniejbo.apps.googleusercontent.com&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive.appdata&immediate=false&response_type=token+id_token&redirect_uri=https%3A%2F%2Fchat.pancake.vn%2Fapi%2Fgoogle_auth&state=$state"
                  );
                },
              ),
              ContextMenuButtonConfig(
                S.current.backup,
                icon: Icon(PhosphorIcons.cloudArrowUp, size: 18),
                onPressed: () {
                  if (Provider.of<DirectMessage>(context, listen: false).errorCode != null) return;
                  showDialog(
                    context: context,
                    builder: (BuildContext b) => DialogBackUp()
                  );                               
                  MessageConversationServices.makeBackUpMessageJsonV1(Provider.of<Auth>(context, listen: false).userId);
                },
              ),
              ContextMenuButtonConfig(
                S.current.restore,
                icon: Icon(PhosphorIcons.cloudArrowDown, size: 18),
                onPressed: () {
                   if (Provider.of<DirectMessage>(context, listen: false).errorCode != null) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext b) => DialogRestore()
                    );                               
                    MessageConversationServices.reStoreBackUpFile(Provider.of<Auth>(context, listen: false).userId);
                },
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
              )
            ),
            height: 56,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(S.of(context).directMessages.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.white))
                ),
              ],
            )
          ),
        ),
        Utils.checkedTypeEmpty(errorCode) ?
            Container(
              child: "$errorCode" == "203" ? Container(
                  margin: EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: (){
                          sendRequestSync(channel, auth, "sync");
                        },
                        child: Container(
                          padding:  EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isDark ? Color(0xFF1890FF).withOpacity(0.08) : Color(0xFFFAAD14).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(width: 1.0, color: isDark ? Color(0xFFD48806) : Color(0xFF69C0FF))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, //Center Row contents horizontally,
                            children: [
                              SvgPicture.asset(isDark ? "assets/icons/PanchatLogoDark.svg" :"assets/icons/PanchatLogoLight.svg",),
                              Container(width:8),
                              Text(S.current.syncPanchatApp, style: TextStyle(
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                fontSize: 14,
                                color: !isDark ? Color(0xFF1890FF) : Color(0xFFFAAD14)
                              ))
                            ]
                          ) 
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Text(S.current.descSyncPanchat, style: TextStyle(
                          color: Color(0xffC9C9C9),
                          fontSize: 12,
                          height: 1.3
                        )),
                      ),
                      GestureDetector(
                        onTap: () {
                          sendRequestSync(channel, auth, "reset");
                        },
                        child: Container(
                          margin: EdgeInsets.only(top:24),
                          padding:  EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isDark ? Color(0xFF1890FF).withOpacity(0.08) : Color(0xFFFAAD14).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                            border: Border(
                              top: BorderSide(width: 1.0, color: isDark ? Color(0xFFD48806) : Color(0xFF69C0FF)),
                              left: BorderSide(width: 1.0, color: isDark ? Color(0xFFD48806) : Color(0xFF69C0FF)),
                              right: BorderSide(width: 1.0, color: isDark ? Color(0xFFD48806) : Color(0xFF69C0FF)),
                              bottom: BorderSide(width: 1.0, color: isDark ? Color(0xFFD48806) : Color(0xFF69C0FF)),
                            )
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, //Center Row contents horizontally,
                            children: [
                              SvgPicture.asset(isDark ? "assets/icons/KeyDark.svg" : "assets/icons/KeyLight.svg"),
                              Container(width:8),
                              Text(S.current.resetDeviceKey, style: TextStyle(
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                fontSize: 14,
                                color: !isDark ? Color(0xFF1890FF) : Color(0xFFFAAD14)
                              ))
                            ]
                          ) 
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Text(S.current.descResetDeviceKey, style: TextStyle(
                          color: Color(0xFFC9C9C9),
                          fontSize: 12,
                          height: 1.3
                        )),
                      ),
                    ],
                  )
                )
                
              : Container(
                padding:EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Color(0xFF22075e)
                ),
                child: Text("$errorCode" == "216" ? S.current.pleaseUpdateVersion : S.current.errorWithStatus(errorCode), style: TextStyle(color: Color(0xFF8c8c8c)),),
              )
            )
          : Container(),
        Expanded(
          child: Stack(
            children: [
              Container(
                child: direct == null ? Text('') : Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: list.map((item) {
                        DirectModel directMessage = item;
                        if (directMessage.archive == true) return Container();
                        var messageSnippet;
                        var userSnippet;
                        var numberType;
                        var currentTime = 0; List userRead = [];
                        var indexConverMessage  =  dataConversationMessages.indexWhere((element) => element["conversation_id"] == directMessage.id);
                        if (directMessage.snippet != {}) {
                          final indexUser = directMessage.user.indexWhere((e) => e["user_id"] == directMessage.snippet["user_id"]);
                          userSnippet = indexUser != -1 ? directMessage.user[indexUser] : null;

                          messageSnippet = (directMessage.snippet["attachments"] != null && directMessage.snippet["attachments"].length > 0
                            ? renderSnippet(directMessage.snippet["attachments"], directMessage)
                            : directMessage.snippet["message"]);
                          numberType  = getType(directMessage.snippet["attachments"] ?? [], directMessage);
                        } else {
                          // messageSnippet = "";
                          // userSnippet = "";
                        }

                        var index = list.indexWhere((e) => e.id == item.id); 
                        if (indexConverMessage != -1) {
                          userRead = directMessage.userRead["data"] ?? [];
                          currentTime = directMessage.userRead["current_time"] ?? 0;
                        }

                        final List listUser = (directMessage.id != "" ? directMessage.user : []).where((element) => element["status"] == "in_conversation" || element["status"] == null).toList();
                        String status = "NORMAL";
                        int indexUser = listUser.indexWhere((element) => element["user_id"] == auth.userId);
                        if (indexUser != -1) {
                          status = listUser[indexUser]["status_notify"] ?? "NORMAL";
                        }

                        Widget notifyIcon = getIconNotification(status, isDark);
                        String notifyLabel = getShortLabelNotificationStatusDM(status);
                        bool roomIsActive = getRoomIsActive(directMessage.id, rooms);

                        return ContextMenuRegion(
                          enableLongPress: false,
                          child: DirectMessageItem(
                            key: Key(index.toString()),
                            directMessage: directMessage,
                            handleCheckedConversation: widget.handleCheckedConversation,
                            currentDirectMessage: currentDirectMessage,
                            currentTime: currentTime,
                            dataConversationMessages: dataConversationMessages,
                            index: index,
                            indexConverMessage: indexConverMessage,
                            messageSnippet: messageSnippet,
                            selectedFriend: selectedFriend,
                            selectedMention: selectedMention,
                            userRead: userRead,
                            userSnippet: userSnippet,
                            userId: auth.userId,
                            roomIsActive: roomIsActive,
                            numberType: numberType,
                          ),
                          contextMenu: GenericContextMenu(
                            buttonConfigs: [
                              ContextMenuButtonConfig(
                                notifyLabel,
                                icon: notifyIcon,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => NotificationDM(
                                      conversationId: directMessage.id, 
                                      onSave: Provider.of<DirectMessage>(context, listen: false).updateSettingConversationMember
                                    )
                                  );
                                },
                              ),
                              ContextMenuButtonConfig(
                                S.current.markAsUnread,
                                icon: SvgPicture.asset(
                                  "assets/icons/Mail.svg",
                                  color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 10, height: 10
                                ),
                                onPressed: () => Provider.of<DirectMessage>(context, listen: false).updateUnreadLocal(directMessage, auth.userId, auth.token),
                              ),
                              ContextMenuButtonConfig(
                                directMessage.user.length < 3 ? S.current.createGroup : S.current.inviteToGroup,
                                icon: SvgPicture.asset(
                                  'assets/icons/AddMember.svg',
                                  color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 10, height: 10
                                ),
                                onPressed: () => inviteDirectModel(context, directMessage),
                              ),
                              ContextMenuButtonConfig(
                                directMessage.user.length < 3 ? S.current.deleteChat : S.current.leaveGroup,
                                icon: SvgPicture.asset(
                                  "assets/icons/delete.svg",
                                  color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 10, height: 10
                                ),
                                onPressed: () {
                                  Provider.of<DirectMessage>(context, listen: false).leaveConversation(directMessage.id, auth.token, auth.userId);
                                },
                              )
                            ],
                          ),
                        );
                      }).toList() + [(isFetching ? shimmerEffect(context, number: 1) : Container())]
                    )
                  )
                )
              ),
              Positioned(
                left: 0, 
                bottom: 0,
                child: StreamSyncData.instance.render(context)
              )
            ],
          )
        )
      ]
    );
  }
}

class DirectMessageItem extends StatefulWidget{
  DirectMessageItem({
    required this.key,
    this.handleCheckedConversation,
    required this.directMessage,
    this.userSnippet,
    this.messageSnippet,
    this.userRead,
    this.currentTime,
    this.dataConversationMessages,
    this.indexConverMessage,
    this.currentDirectMessage,
    this.selectedFriend,
    this.selectedMention,
    this.index,
    this.userId,
    this.roomIsActive,
    this.numberType
  });

  final Key key;
  final handleCheckedConversation;
  final DirectModel directMessage;
  final userSnippet;
  final messageSnippet;
  final userRead;
  final currentTime;
  final dataConversationMessages;
  final indexConverMessage;
  final currentDirectMessage;
  final selectedFriend;
  final selectedMention;
  final index;
  final userId;
  final roomIsActive;
  final numberType;
  @override
  State<StatefulWidget> createState() {
    return _DirectMessageItemState();
  }
}

class _DirectMessageItemState extends State<DirectMessageItem>{
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var isHover = false;

  getAvatarUrl(List data, String userId) {
    if (data.length  == 1) return data[0]["avatar_url"];
    if (data.length > 1){
      for (var i = 0; i < data.length; i++) {
        if (data[i]["user_id"] == userId) continue;
        return data[i]["avatar_url"];
      }
    }
  }

  onSelectDirectMessage(directMessage) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentDirectMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    final channel = auth.channel;
    await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
    await Provider.of<DirectMessage>(context, listen: false).setIdMessageToJump("");

    if (currentDirectMessage.id != directMessage.id) {
      Provider.of<DirectMessage>(context, listen: false).getMessageFromApiDown(directMessage.id, true, auth.token, auth.userId);
      Provider.of<DirectMessage>(context, listen: false).cutOldMessageOnConversation(directMessage.id);
      await channel.push(event: "join_direct", payload: {"direct_id": directMessage.id});
      await Provider.of<DirectMessage>(context, listen: false).setSelectedDM(directMessage, auth.token);
    }

    if (mounted) Utils.updateBadge(context);
  }

  onHideDirectMessage(idDirectMessage,idCurrentDirectMessage, isHide) async {
    if (idDirectMessage == idCurrentDirectMessage){
      List listDm = widget.dataConversationMessages;
      List listDirectModel = Provider.of<DirectMessage>(context, listen: false).data.toList();
      var indexPanchat = listDm.indexWhere((element) => element["type"] == "panchat");
      var indexPanchatModel = listDirectModel.indexWhere((element) => element.id == listDm[indexPanchat]["conversation_id"]);
      if (indexPanchat == -1) return;
      if (indexPanchatModel != -1){
        DirectModel dm = listDirectModel[indexPanchatModel];
        await onSelectDirectMessage(dm);
      }
    }
    await Provider.of<DirectMessage>(context, listen: false).setHideConversation(idDirectMessage, isHide, context);
  }

  isPanchatNotify(List users) {
    String idPanchat = "41b87209-ec1f-4781-a7be-4c861d4864ca";
    int index = users.indexWhere((element) => element["user_id"] == idPanchat);

    if(index != -1) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    DirectModel directMessage = widget.directMessage;
    var userSnippet = widget.userSnippet;
    List userRead = widget.userRead;
    var messageSnippet = widget.messageSnippet;
    var currentTime = widget.currentTime;
    final indexConverMessage = widget.indexConverMessage;
    final currentDirectMessage = widget.currentDirectMessage;
    final selectedFriend = widget.selectedFriend;
    final selectedMention = widget.selectedMention;
    final index = widget.index;
    final Color color = (userRead.indexWhere((element) => element == widget.userId) == -1) ? Color(0xffF5F7FA)
      : (currentDirectMessage.id == directMessage.id && !selectedFriend && !selectedMention)
        ? Color(0xfff0f4f8)
        : !isHover ? Color(0xff8e9297) : Color(0xfff0f4f8);
    final FontWeight fontWeight = (userRead.indexWhere((element) => element == widget.userId) == -1)
        ? FontWeight.w500
        : FontWeight.w400;

    if (indexConverMessage == -1) return Container();
    return InkWell(
      onHover: (hover){
        setState(() {
          isHover = hover;
        });
      },
      onTap: () async {
        onSelectDirectMessage(directMessage);
        FocusInputStream.instance.focusToMessage();
      },
      child: Container(
        margin: EdgeInsets.only(top: 2,bottom: 2),
        padding: EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 6),
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                Stack(
                  children: [
                    directMessage.user.length > 2
                      ? SizedBox(
                          width: 32,
                          height: 32,
                          child: directMessage.avatarUrl != null ? CachedAvatar(
                            directMessage.avatarUrl != null ? directMessage.avatarUrl : getAvatarUrl(directMessage.user, widget.userId),
                            height: 32, width: 32, radius: 16,
                            isRound: true,
                            name: directMessage.displayName,
                            isAvatar: true
                          ) : Container(
                            decoration: BoxDecoration(
                              color: Color(((index + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
                              borderRadius: BorderRadius.circular(16)
                            ),
                            child: Icon(
                              Icons.group,
                              size: 16,
                              color: Colors.white
                            ),
                          ),
                        )
                      : Container(
                        // margin: EdgeInsets.all(4),
                        child: CachedAvatar(
                          directMessage.avatarUrl != null ? directMessage.avatarUrl : getAvatarUrl(directMessage.user, widget.userId),
                          height: 32, width: 32, radius: 16,
                          isRound: true,
                          name: directMessage.displayName,
                          isAvatar: true
                        ),
                      ),
                      Positioned(
                        top: 20, left: 20,
                        child: Container(
                          height: 14, width: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: directMessage.user.where((element) => element["user_id"] != widget.userId && (element["is_online"] ?? false)).toList().length > 0 
                              ? (currentDirectMessage.id == directMessage.id && !selectedFriend && !selectedMention)
                                ? Palette.selectChannelColor
                                : isHover 
                                  ? Palette.backgroundRightSiderDark 
                                  : Color(0xff2e2e2e) 
                              : Colors.transparent
                          ),
                        )
                      ),
                      isPanchatNotify(directMessage.user) || directMessage.user.length == 1 ? SizedBox() : Positioned(
                        top: 22, left: 22,
                        child: Container(
                          height: 10, width: 10,
                           decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(1),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:directMessage.user.where((element) => element["user_id"] != widget.userId && (element["is_online"] ?? false)).toList().length > 0
                                ? Color(0xff73d13d)
                                : Colors.transparent,
                            ),
                          ),
                        )
                      )
                  ],
                ),
                          
                SizedBox(width:8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          child: RichText(
                            maxLines: 1,
                            text: TextSpan(
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                color: color,
                                fontSize: 14.5,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: directMessage.name != "" ? directMessage.name : directMessage.displayName,
                                  
                                ),
                                TextSpan(
                                  text: directMessage.user.length == 1 ? " (me)" : "",
                                )
                              ]
                            ),
                          )
                        ),
                      ),
                      userSnippet != null && userSnippet["full_name"] != "" ? Container(
                        height: 16,
                        child: userSnippet == null
                          ? Container()
                          : Row(
                            children: [
                              userSnippet["user_id"] == widget.userId 
                              ? Container(
                                margin: EdgeInsets.only(right: 2, top: 3.5),
                                child: Icon(
                                  Icons.subdirectory_arrow_right,
                                  color: color,
                                  size: 11,
                                ),
                              )
                              : directMessage.user.length == 2 
                                ? Container()
                                : Container(
                                  margin: EdgeInsets.only(right: 0,top: 4),
                                  child: Text(
                                    userSnippet["full_name"] + ": ",
                                    style: TextStyle(
                                      // tin chuwa doc snippet mau trang,
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: fontWeight
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Utils.checkedTypeEmpty(widget.numberType["mention"]) 
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 3.6),
                                      child: Row(
                                        children: [
                                          Text(
                                            widget.numberType["mention"] ?? directMessage.snippet["message"],
                                            style: TextStyle(color: color,  fontSize: 11,)
                                          ),
                                        ],
                                      ),
                                    ) 
                                    : Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: rendericon(
                                          widget.numberType["video"], 
                                          widget.numberType["other"], 
                                          widget.numberType["image"], 
                                          widget.numberType["call_terminated"], 
                                          widget.numberType["attachment"], 
                                          widget.numberType["inviied"], color),
                                      ),
                                      SizedBox(width: 4,),
                                      Expanded(
                                        child: Text(
                                          "${messageSnippet.split("\n")[0]}",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            // tin chuwa doc snippet mau trang, 
                                            color: color,
                                            fontSize: 11,
                                            height: 1.56,
                                            fontWeight: fontWeight
                                           ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )           
                          ) : Container()
                        ],
                      ),
                    )
                  ]
               ),
            ),
            if (widget.roomIsActive) RoomActiveButton(),
            Container(
              padding: EdgeInsets.only(left: 6, top: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  renderUserRead(
                    directMessage.seen,
                    directMessage.user, 
                    widget.userId, 
                    userRead,
                    "$currentTime",
                    directMessage.userRead["last_user_id_send_message"] ?? ""
                  ),
                  Container(
                    // margin: EdgeInsets.only(bottom: userRead.length == 0 ? -5 : 0),
                    child: ShowTime(time: currentTime, color: color),
                  )
                  
                ],
              ),
            ),
          ],
        ),
          
        decoration: (currentDirectMessage.id == directMessage.id && !selectedFriend && !selectedMention)
          ? BoxDecoration(color: Palette.selectChannelColor)
          : isHover
            ? BoxDecoration(color: Palette.backgroundRightSiderDark)
            : BoxDecoration(),
      )
    );
  }
  
  Widget rendericon(int video, int other ,int image, int callterminated, int attachment, int inviied, Color color) {
    if (video >= 1 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return Icon(PhosphorIcons.youtubeLogo, size: 13, color: color,);
    if (video == 0 && other >= 1 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return Icon(PhosphorIcons.folderOpen,size: 13, color: color,);
    if (video == 0 && other == 0 && image >= 1 && callterminated == 0 && attachment == 0 && inviied == 0) return Icon(PhosphorIcons.image,size: 13, color: color,);
    if (video == 0 && other == 0 && image == 0 && callterminated >= 1 && attachment == 0 && inviied == 0) return Icon(PhosphorIcons.phoneCall,size: 13, color: color,);
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment >= 1 && inviied == 0) return Icon(PhosphorIcons.chatCenteredDots,size: 13, color: color,);
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied >= 1) return Container();
    if (video == 0 && other == 0 && image == 0 && callterminated == 0 && attachment == 0 && inviied == 0) return Container();

    return Icon(PhosphorIcons.folderOpen,size: 13);
  }
}

showCreateDM(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? Color(0xFF36393f) : Colors.white,
        contentPadding: EdgeInsets.all(20),
        content: Container(
          height: 560,
          width: 500,
          child: CreateDMsMacOS()
        ),
      );
    }
  );
}

class ShowTime extends StatefulWidget{
  final time;
  final color;

  ShowTime({
    Key? key,
    @required this.time,
    required this.color
  });

  @override 
  _ShowTime createState() => _ShowTime();
}

class _ShowTime extends State<ShowTime> {

  String timeString = "";
  var timer;

  @override
  void initState() {
    super.initState();
    initTime();
  }

  @override
  void didUpdateWidget(oldWidget){
    super.didUpdateWidget(oldWidget);
    if (widget.time != oldWidget.time){
      if (timer != null) {timer.cancel(); timer = null;}
      initTime();
    }
  }

  initTime(){
    if (timer == null)
      timer =  new Timer.periodic(Duration(seconds: 60), (t){
        genNewString();
      });
    setState(() {
      timeString = getTimeString();
    });
  }

  genNewString(){
    String newString = getTimeString();
    if (this.mounted && newString != timeString)
    this.setState(() {
      timeString = newString;
    });
  }

  getTimeString(){
    int time = widget.time;

    if (time == 0) return "";

    int now = DateTime.now().microsecondsSinceEpoch;
    int diff  = now - time;
    DateTime t =  DateTime.fromMicrosecondsSinceEpoch(time);

    if (DateTime.now().year != t.year) return "${t.year}";
    if (diff < 60000000) return "now";
    if (diff < 60000000 * 60) return "${(diff / 60000000).round()}m";
    if (diff < 60000000 * 60 * 24) return  "${(diff / 60000000 / 60).round()}h";
    if (diff < 60000000 * 60 * 24 * 7) return "${listDay[t.weekday % 7]}";
    return "${getStringMonth(t.month)} ${t.day}";
  }


  var listDay  =  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  getStringMonth(month){
    switch (month) {
      case 1: return "Jan";
      case 2: return "Feb";
      case 3: return "Mar";
      case 4: return "Apr";
      case 5: return "May";
      case 6: return "Jun";
      case 7: return "Jul";
      case 8: return "Aug";
      case 9: return "Sep";
      case 10: return "Oct";
      case 11: return "Nov";
      case 12: return "Dec";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: EdgeInsets.only(top: 6),
      child: Text(timeString, style: TextStyle(color: widget.color, fontSize: 9),
    ));
  }
}

renderUserRead(bool seen, List users, String userId, List userRead, currentTime, String lastUserIdSendMessage) {
  if ("$currentTime" == "0") return Container();
  var indexUser  = userRead.indexWhere((element) => element == userId);
  List otherUserAvatarUrl  = (userRead.where((element) => element != userId).toList().map((e) {
    var indexUser  =  users.indexWhere((element) => element["user_id"] == e);
    if (indexUser == -1) return null;
    return {
      "avatar_url": users[indexUser]["avatar_url"],
      "name": users[indexUser]["full_name"]
    };
  }).where((element) => element != null)).toList();

  List renderUserAvatarUrl = otherUserAvatarUrl.take(2).toList();

  if (indexUser == -1 || !seen) {
    return Container(
      height: 10, width: 10,
      margin: EdgeInsets.only(top: 2, bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFF19DFCB),
        borderRadius: BorderRadius.circular(6)
      )
    );
  }
  if (userRead.length == 1)
    return Container(
      height: 10, width: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6)
      ),
      margin: EdgeInsets.only(top: 2, bottom: 8),
      child: Icon(Icons.check_circle, size: 12, color: Palette.defaultTextDark.withOpacity(0.75),),
    );
  if (lastUserIdSendMessage == userId) {
      return Container(
        margin: EdgeInsets.only(top:2, bottom: 6),
      // render avata nguoi nha
      // chir render 3 nguoi nhan neu dai hon thi cat
        child: Row(
          children: [
            Row(
              children: renderUserAvatarUrl.map((e) => Container(
                margin: EdgeInsets.only(left: 3),
                child: CachedAvatar(e["avatar_url"], width: 11, height: 11, radius: 5, name: e["name"], fontSize: 5,))).toList(),
            ),
            renderUserAvatarUrl.length < otherUserAvatarUrl.length ? 
            Container(
              margin: EdgeInsets.only(left: 3),
              width: 11, height: 11,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Color(0xFFffffff)
              ),
              child: Text("+ ${ otherUserAvatarUrl.length - renderUserAvatarUrl.length }", style: TextStyle(fontSize: 5.5, color: Color(0xFF262626)),),
            ) : Container()
          ],
        )
      );
  } else return Container(height: 20);
}

class DialogBackUp extends StatefulWidget {
  const DialogBackUp({ Key? key,  }) : super(key: key);

  @override
  State<DialogBackUp> createState() => _DialogBackUpState();
}

class _DialogBackUpState extends State<DialogBackUp> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 100, width: 100,
        // color: Colors.red,
        child: StreamBuilder(
          initialData: StatusBackUp(100, S.current.startingUp),
          stream: MessageConversationServices.statusBackUp,
          builder: (context, snapshot){
            StatusBackUp data = snapshot.data == null ? StatusBackUp(100, S.current.startingUp) : ((snapshot.data) as StatusBackUp);
            return Container(
              child: Center(
                child: Text(data.status),
              )
            );
          }
        ),
      ),
    );
  }
}

class DialogRestore extends StatefulWidget {
  const DialogRestore({ Key? key,  }) : super(key: key);

  @override
  State<DialogRestore> createState() => _DialogRestoreState();
}

class _DialogRestoreState extends State<DialogRestore> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 100, width: 100,
        // color: Colors.red,
        child: StreamBuilder(
          initialData: StatusRestore(100, S.current.startingUp),
          stream: MessageConversationServices.statusRestore,
          builder: (context, snapshot){
            StatusRestore data = snapshot.data == null ? StatusRestore(100, S.current.startingUp) : ((snapshot.data) as StatusRestore);
            return Container(
              child: Center(
                child: Text(data.status),
              )
            );
          }
        ),
      ),
    );
  }
}

