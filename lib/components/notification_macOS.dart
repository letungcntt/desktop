import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:flutter/services.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'dart:convert';

import 'package:workcake/models/models.dart';

class NotificationMacOS extends StatefulWidget {
  NotificationMacOS({Key? key}) : super(key: key);

  @override
  _NotificationMacOSState createState() => _NotificationMacOSState();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

const MethodChannel platform = MethodChannel('dexterx.dev/flutter_local_notifications_example');
class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final id;
  final title;
  final body;
  final payload;
}

class _NotificationMacOSState extends State<NotificationMacOS> {
  MethodChannel notifyChannel = MethodChannel("notify");
  @override
  void initState() {
    super.initState();
    if (mounted) {
      if(Platform.isMacOS) setUpNotify();
    }

    Timer(Duration(seconds: 2), () {
      final channel = Provider.of<Auth>(context, listen: false).channel;

      channel.on("new_message_channel_notification", (payload, _ref, _joinRef) async {
        final message = payload["message"];
        pushNotify(message);
      });

      channel.on("dm_message", (data, _ref, _joinRef) {
        pushNotifyDirect(data["data"][0]);
      });

      channel.on("clear_badge_channel", (data, _ref, _joinRef) async {
        final channelId = data["channel_id"];
        onClearBadge(channelId);
      });

      // tin nhan thread cua dm
      channel.on("new_thread_count_conversation", (data, _f, _j){
        pushNotifyDirect(data["data"][0]);
      });
    });
  }

  pushNotifyDirect(Map dataMessage) async {
    try {
      var conversationId = dataMessage["conversation_id"];
      final currentUser = Provider.of<User>(context, listen: false).currentUser;
      final userId = dataMessage["user_id"];
      if (userId == currentUser["id"]) return;
      DirectModel? dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(conversationId);
      if (dm == null) return;
      var indexUser = dm.user.indexWhere((element) => element["user_id"] == currentUser["id"]);
      if (indexUser == -1) return;
      String settingNoti = dm.user[indexUser]["status_notify"] ?? "NORMAL";
      if (settingNoti == "OFF") return;
      var currentDataDMMessage =  Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(conversationId);
      var messageDecrypted = currentDataDMMessage["conversationKey"].decryptMessage(dataMessage);
      var currentDM = Provider.of<DirectMessage>(context, listen: false).getModelConversation(conversationId);
      if (messageDecrypted != null && messageDecrypted["success"]) {
        await MessageConversationServices.insertOrUpdateMessage(messageDecrypted["message"]);
        var title = Utils.checkedTypeEmpty(messageDecrypted["message"]["parent_id"]) ? ("${currentDM!.displayName} - thread") : (currentDM!.displayName);
        var dataMessage = messageDecrypted["message"];
        var body = getBodyNotification(currentDM, dataMessage, messageDecrypted["message"]["full_name"]);
        if (settingNoti == "MENTION" && !checkInMention(dataMessage["attachments"])) return;
        if (Platform.isWindows){
          String subBody = body.substring(0, body.length > 254 ? 254 : body.length);
          String subTitle = title.substring(0, title.length > 254 ? 254 : title.length);
          notifyChannel.invokeMethod("push_notify",[subTitle, subBody]);
        }
        if (Platform.isMacOS){
          pushNotiMacOS(title, body, jsonEncode(messageDecrypted["message"]));        
        }
      }
    } catch (e, trace) {
      print("catch: $e $trace");
    }
  }

  pushNotiMacOS(title, body, payload, {isDefault: false}){
    int id = int.parse(DateTime.now().millisecondsSinceEpoch.toString().substring(7));
    var macOSPlatformChannelSpecifics = new MacOSNotificationDetails(
      presentAlert: !isDefault, 
      presentBadge: true, 
      presentSound: !isDefault, 
      sound: isDefault ? null : 'slow_spring_board', 
      badgeNumber: checkNewBadgeCount()
    );

    var platformChannelSpecifics = NotificationDetails(macOS: macOSPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload
    ); 
  }

  onClearBadge(channelId) async {
    if (this.mounted) {
      await Provider.of<Channels>(context, listen: false).clearBadge(channelId, null, false);
      await Utils.updateBadge(context);
    }
  }
  
  setUpNotify() {
    WidgetsFlutterBinding.ensureInitialized();
    MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true
    );
    final InitializationSettings initializationSettings = 
      InitializationSettings(
        macOS: initializationSettingsMacOS
      );
    
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (payload) async {
        var newPayload = jsonDecode(payload!);
        var channelId = newPayload["channel_id"];
        var workspaceId = newPayload["workspace_id"];
        var conversationId = newPayload["conversation_id"];

        if (conversationId != null) {
          onGotoDirect(conversationId, newPayload);
        } else {
          onChangeWorkspace(workspaceId, channelId, newPayload);
        }
        selectNotificationSubject.add(payload);
      }
    );
    pushNotiMacOS("", "", null, isDefault: true); 
  }

  parseAttachments(att, isChannel, {var convId = ""}) {
    final attachment = att.length > 0 ? att[0] : null;

    if (attachment != null) {
      final string = attachment["type"] == "mention" ? attachment["data"].map((e) {
        if (e["type"] == "text" ) return e["value"];
        return "${e["trigger"] ?? "@"}${e["name"] ?? ""} ";
      }).toList().join() :
        attachment["type"] == "delete" ? "${attachment['delete_user_name']} was kicked from this channel." :
        attachment["type"] == "bot" ? "Sent an attachment" : 
        attachment["type"] == "change_name" ? "${attachment["user_name"]} has changed channel name to ${attachment["params"]["name"]}" :
        attachment["type"] == "invite" ? "${attachment["invited_user"]} has join a channel" : 
        attachment["type"] == "leave_channel" ? "${attachment["user"]} has leave the channel" :
        attachment["type"] == "change_topic" ? "${attachment["user_name"]} has changed channel topic to ${attachment["params"]["topic"]}" :
        attachment["type"] == "change_private" ? "${attachment["user_name"]} has changed channel private to ${attachment["params"]["is_private"] ? "private" : "public"}" :
        attachment["mime_type"] == "image" ? "Sent a photo" : "Sent an attachment";

      return string;
    } else {
      return "Error payload";
    }
  }

  pushNotify(payload) {
    final onFocusApp = Provider.of<Auth>(context, listen: false).onFocusApp;
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    final data = Provider.of<Channels>(context, listen: false).data;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final channelId = payload["channel_id"];
    final message = payload["message"];
    final userId = payload["user_id"];
    final attachments = payload["attachments"] ?? [];
    int index = data.indexWhere((e) => e["id"] == channelId);

    if (userId != currentUser["id"]) {
      if (index != -1) {
        if (((tab == 0 || currentChannel["id"] != channelId) || !onFocusApp) ) {
          Provider.of<Channels>(context, listen: false).updateLastMessageReaded(channelId, payload["id"]);
        }

        if (data[index]["status_notify"] == "NORMAL" || (data[index]["status_notify"] == "MENTION" && checkInMention(attachments))) {
          if ((tab == 0 || currentChannel["id"] != channelId) || !onFocusApp) {
            int index = data.indexWhere((e) => e["id"] == channelId);
            String title = payload["full_name"] != null ? "${payload["full_name"]} to ${data[index]["name"]}" : "Bot to ${data[index]["name"]}";
            var body = !Utils.checkedTypeEmpty(message) ? parseAttachments(attachments, true) : "${payload["message"]}";
            var newPayload = jsonEncode(payload);
            if (Platform.isMacOS) {
              pushNotiMacOS(title, body, newPayload);
            } else {
              String subBody = body.substring(0, body.length > 254 ? 254 : body.length);
              notifyChannel.invokeMethod("push_notify", [title, subBody]);
            }

          }
        }
      }
    }
  }

  checkInMention(att) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final mentions = att.where((e) => e["type"] == "mention").toList();
    bool check = false;

    if (mentions.length > 0) {
      for (var mention in mentions) {
        final data = mention["data"];

        if (data != null) {
          final indexAll = data.indexWhere((e) => (e["type"] == "user" && e["name"] == "all") || e["type"] == "all");
          final indexUser = data.indexWhere((e) => e["type"] == "user" && e["value"] == currentUser["id"]);

          if (indexAll != -1 || indexUser != -1) {
            check = true;
          }
        }
      }
    }

    return check;
  }


  getBodyNotification(DirectModel dm, Map message, String? fullName){
    // hoi thoai 1-1 => khoong chua ten nguoi gui
    // trong cac truong hop con lai thi co ten nguoi gui
    if (dm.user.length == 2){
      return message["message"] == "" ? "${parseAttachments(message["attachments"], false, convId: dm.id)}" : "${message["message"]}";
    }
    return message["message"] == "" ? "$fullName: ${parseAttachments(message["attachments"], false, convId: dm.id)}" : "$fullName: ${message["message"]}";
  }

  getTitleNotification(DirectModel dm){
    // hoi thoai 1-1, nameDm la ten nguoi gui
    // trong cac truong hop con lai thi tra ve ten hoac list danh sach thanh vien
    if (dm.user.length == 2){
      var yourId = Provider.of<Auth>(context, listen: false).userId;
      var otherIndex = dm.user.indexWhere((element) => element["user_id"] != yourId);
      if (otherIndex == -1) return dm.name != "" ? dm.name : dm.user.map((e) => e["full_name"]).join(", ");
      return dm.user[otherIndex]["full_name"];
    }
    return dm.name != "" ? dm.name : dm.user.map((e) => e["full_name"]).join(", ");
  }

  checkNewBadgeCount() {
    final channels = Provider.of<Channels>(context, listen: false).data;
    final data = Provider.of<DirectMessage>(context, listen: false).data;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final dataThreads = Provider.of<Threads>(context, listen: false).dataThreads;
    num count = 0;

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

    return count;
  }

  onChangeWorkspace(workspaceId, channelId, payload) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final channel = Provider.of<Auth>(context, listen: false).channel;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
    Provider.of<User>(context, listen: false).selectTab("channel");
    Provider.of<Workspaces>(context, listen: false).tab = workspaceId;
    Provider.of<Workspaces>(context, listen: false).selectWorkspace(token, workspaceId, context);
    Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, workspaceId, context);
    Provider.of<Messages>(context, listen: false).loadMessages(token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).selectChannel(token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).onChangeLastChannel(workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);
    
    channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );

    if (payload["channel_thread_id"] != null) {
      final data = Provider.of<Messages>(context, listen: false).data;
      int index = data.indexWhere((e) => e["channelId"] == channelId);

      if (index != -1) {
        List messages = data[index]["messages"];
        int indexMessage = messages.indexWhere((e) => e["id"] == payload["channel_thread_id"]);

        if (indexMessage != -1) { 
          final message = messages[indexMessage];
          Map parentMessage = { 
            "id": message["id"],
            "message": message["message"],
            "avatarUrl": message["avatar_url"],
            "lastEditedAt": message["last_edited_at"],
            "isUnsent": message["is_unsent"],
            "fullName": message["full_name"],
            "insertedAt": message["inserted_at"],
            "attachments": message["attachments"],
            "userId": message["user_id"],
            "workspaceId": workspaceId,
            "channelId": channelId,
            "isChannel": true
          };

          Provider.of<Channels>(context, listen: false).openChannelSetting(false);
          Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
          Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
        }
      }
    }
    
    Utils.updateBadge(context);
  }

  onGotoDirect(conversationId, payload) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final channel = Provider.of<Auth>(context, listen: false).channel;
    final list = Provider.of<DirectMessage>(context, listen: false).data.reversed.toList();

    int index = list.indexWhere((e) => e.id == conversationId);

    if (index != -1) {
      DirectModel directMessage = list[index];

      await channel.push(event: "join_direct", payload: {"direct_id": conversationId});
      Provider.of<Workspaces>(context, listen: false).tab = 0;
      Provider.of<Workspaces>(context, listen: false).changeToMessageView(true);
      await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
      await Provider.of<DirectMessage>(context, listen: false).setSelectedDM(directMessage, token);
      await Provider.of<DirectMessage>(context, listen: false).getMessageFromApiDown(conversationId, true, token, userId);


      if (payload["parent_id"] != null) {
        final data = Provider.of<DirectMessage>(context, listen: false).dataDMMessages;
        final index = data.indexWhere((e) => e["conversation_id"] == conversationId);

        if (index != -1) {
          var messageOnIsar = await MessageConversationServices.getListMessageById(payload["parent_id"], conversationId);
          if (messageOnIsar != null) {
            final message = messageOnIsar;
            final directMessageSelected =  Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
            List users = directMessageSelected.user;
            final indexUser = users.indexWhere((e) => e["user_id"] == message["user_id"]);

            if (indexUser != -1) {
              final user = users[indexUser];
              Map parentMessage = {
                "id": message["id"],
                "message": message["message"],
                "avatarUrl": user["avatar_url"],
                "insertedAt": message["time_create"],
                "fullName": user["full_name"],
                "attachments": message["attachments"],
                "userId": message["user_id"],
                "conversationId": conversationId,
                "isChannel": false,
              };

              Provider.of<Channels>(context, listen: false).openChannelSetting(false);
              await Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
            }
          }
        }
      } 
    }

    Utils.updateBadge(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       child: Container(width: 0),
    );
  }
}